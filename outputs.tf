output "website_url" {
  description = "The public URL the webserver will deliver traffic from"
  value       = "http://${aws_instance.webserver.public_dns}/"
}

output "webserver_instance_id" {
  description = "EC2 instance id which can be used to create a AMI"
  value       = aws_instance.webserver.id
}
