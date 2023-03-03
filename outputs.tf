output "instance_name" {
  value       = local.instance_name
  description = "The instance name"
}

output "instance_id" {
  value       = aws_instance.instance.id
  description = "The instance id"
}

output "instance_ip" {
  value       = aws_instance.instance.private_ip
  description = "The instance private IPv4 address"
}

output "instance_fqdn" {
  value = module.bluecat.fqdn
}
  
output "instance_key_name" {
  value       = aws_instance.instance.key_name
  description = "The instance key name"
}
