data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "tls_private_key" "tp" {
  algorithm = "ED25519"
}

resource "aws_key_pair" "tp" {
  key_name   = "tp-${var.poste_nn}-cle"
  public_key = tls_private_key.tp.public_key_openssh
}

resource "local_sensitive_file" "private_key" {
  content         = tls_private_key.tp.private_key_openssh
  filename        = "${path.root}/tp-${var.poste_nn}-cle.pem"
  file_permission = "0400"
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  associate_public_ip_address = true
  vpc_security_group_ids      = [var.bastion_sg_id]
  key_name                    = aws_key_pair.tp.key_name

  tags = {
    Name = "tp-${var.poste_nn}-bastion"
  }
}

resource "aws_instance" "app" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = var.private_subnet_id
  associate_public_ip_address = false
  vpc_security_group_ids      = [var.prive_sg_id]
  key_name                    = aws_key_pair.tp.key_name

  tags = {
    Name = "tp-${var.poste_nn}-app"
  }
}

resource "local_file" "ssh_config" {
  filename = "${path.root}/ssh_config_tp-${var.poste_nn}"
  content  = <<-EOT
    Host tp-${var.poste_nn}-bastion
      HostName ${aws_instance.bastion.public_ip}
      User ec2-user
      IdentityFile ${abspath(local_sensitive_file.private_key.filename)}

    Host tp-${var.poste_nn}-app
      HostName ${aws_instance.app.private_ip}
      User ec2-user
      IdentityFile ${abspath(local_sensitive_file.private_key.filename)}
      ProxyJump tp-${var.poste_nn}-bastion
  EOT
}
