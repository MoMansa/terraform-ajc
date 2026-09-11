resource "aws_security_group" "bastion" {
  name        = "tp-${var.poste_nn}-sg-bastion"
  description = "SSH depuis le poste de travail"
  vpc_id      = var.vpc_id

  tags = {
    Name = "tp-${var.poste_nn}-sg-bastion"
  }
}

resource "aws_vpc_security_group_ingress_rule" "bastion_ssh" {
  security_group_id = aws_security_group.bastion.id
  description        = "SSH depuis mon poste"
  cidr_ipv4          = var.ma_cidr_ip
  from_port          = 22
  to_port            = 22
  ip_protocol        = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "bastion_out" {
  security_group_id = aws_security_group.bastion.id
  cidr_ipv4          = "0.0.0.0/0"
  ip_protocol        = "-1"
}

resource "aws_security_group" "prive" {
  name        = "tp-${var.poste_nn}-sg-prive"
  description = "SSH depuis le groupe du bastion uniquement"
  vpc_id      = var.vpc_id

  tags = {
    Name = "tp-${var.poste_nn}-sg-prive"
  }
}

resource "aws_vpc_security_group_ingress_rule" "prive_ssh" {
  count = var.test_panne_sg ? 0 : 1

  security_group_id            = aws_security_group.prive.id
  description                   = "SSH depuis le groupe du bastion"
  referenced_security_group_id  = aws_security_group.bastion.id
  from_port                     = 22
  to_port                       = 22
  ip_protocol                   = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "prive_out" {
  security_group_id = aws_security_group.prive.id
  cidr_ipv4          = "0.0.0.0/0"
  ip_protocol        = "-1"
}
