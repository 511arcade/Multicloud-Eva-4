output "alb_dns_name" {
  description = "DNS del Application Load Balancer (registro A para seguimiento)"
  value       = aws_lb.app.dns_name
}

output "asg_name" {
  description = "Nombre del Auto Scaling Group"
  value       = aws_autoscaling_group.web.name
}

output "s3_bucket" {
  description = "Bucket S3 de objetos"
  value       = aws_s3_bucket.objects.bucket
}

output "vpc_id" {
  description = "ID de la VPC"
  value       = aws_vpc.main.id
}

output "private_subnets" {
  description = "Subredes privadas (donde escala el ASG)"
  value       = aws_subnet.private[*].id
}
