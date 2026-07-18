#!/bin/bash
set -e

# 1. Update OS and install dependencies
dnf update -y
dnf install -y git make jq tar

# 2. Install K3s (Lightweight Kubernetes)
curl -sfL https://get.k3s.io | sh -
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /root/.bashrc

# Wait for K3s to initialize
sleep 15

# 3. Install Kustomize
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash
mv kustomize /usr/local/bin/

# 4. Set up the AWX deployment directory
mkdir -p /opt/awx
cd /opt/awx

# Create the kustomization.yaml file
cat <<EOF > kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - github.com/ansible/awx-operator/config/default?ref=2.19.1

images:
  - name: quay.io/ansible/awx-operator
    newTag: 2.19.1

namespace: awx
EOF

# 5. Deploy the AWX Operator
kubectl create namespace awx
kustomize build . | kubectl apply -f -

# Wait for the operator pod to be ready
sleep 30

# 6. Create the AWX Instance manifest
cat <<EOF > awx-instance.yaml
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx
  namespace: awx
spec:
  service_type: NodePort
  nodeport_port: 30080
EOF

# Deploy the AWX Instance
kubectl apply -f awx-instance.yaml

# 7. Expose K3s NodePort 30080 to standard Port 80 using iptables
iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 30080
iptables-save > /etc/sysconfig/iptables