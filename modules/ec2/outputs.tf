output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "bastion_private_ip" {
  value = aws_instance.bastion.private_ip
}

output "app_private_ip" {
  value = aws_instance.app.private_ip
}

output "ssh_config_path" {
  value = local_file.ssh_config.filename
}
