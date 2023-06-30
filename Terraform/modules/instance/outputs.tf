output "security_group" {
  value = aws_security_group.instance
}

output "asg_name" {
  value = aws_autoscaling_group.server.name
}