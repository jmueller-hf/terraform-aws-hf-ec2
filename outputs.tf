output "instance_info" {
  value       = aws_instance.instance
  description = "The instance info"
}

output "instance_id" {
  value       = aws_instance.instance.id
  description = "The instance id"
}

output "instance_ip" {
  value       = aws_instance.instance.private_ip
  description = "The instance private IPv4 address"
}
