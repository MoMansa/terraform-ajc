output "bastion_sg_id" {
  value = aws_security_group.bastion.id
}

output "prive_sg_id" {
  value = aws_security_group.prive.id
}
