# 1. Generate a secure RSA private key
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 2. Register the public key with AWS EC2
resource "aws_key_pair" "awx_deployer_key" {
  key_name   = "tk-ec2-key"
  public_key = tls_private_key.ec2_key.public_key_openssh
}

# 3. Save the private key locally to a .pem file
resource "local_file" "private_key" {
  content         = tls_private_key.ec2_key.private_key_pem
  filename        = "${path.module}/tk-ec2-key.pem"
  file_permission = "0400" # Sets read-only permissions for safety
}