

output "alb_dns_name" {
  value = aws_lb.awsLb.dns_name
}
output "alb_id" {
  value = aws_lb.awsLb.id
}

output "forwardKey" {
  value = var.forwardKey
}