# 2. Find the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}# 3. Provision the EC2 Instance
resource "aws_instance" "awx_server" {
  ami           = data.aws_ami.amazon_linux.id
  #instance_type = "t3.xlarge" # AWX requires a minimum of 4 vCPUs and 8GB RAM
  instance_type = "t2.micro"
  #key_name      = var.tk-ec2-key
  key_name      = aws_key_pair.awx_deployer_key.key_name
  subnet_id                   = aws_subnet.public_1b.id
  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.awx_sg.id]

  root_block_device {
    volume_size = 40
    volume_type = "gp3"
  }

  # 4. Bootstrap Kubernetes and AWX via User Data
  #user_data = file("bootstrap.sh")

  tags = {
    Name = "tk-tf-ec2-awx-controller"    #Prefix your own name, e.g. jazeel-ec2
  }

  depends_on = [
    aws_route.public_internet,
    aws_nat_gateway.tk_tf_nat_gw
  ]
}

# 5. Output the Public IP
output "awx_public_ip" {
  value = aws_instance.awx_server.public_ip
}