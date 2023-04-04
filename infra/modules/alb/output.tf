output "public_dns" {
  value = aws_lb.for_webserver.dns_name
}

output "target_group_arn" {
  value = aws_lb_target_group.for_webserver.arn
}

output "alb_sg_id" {
  value = aws_security_group.alb.id
}

output "alb_arn" {
  value = aws_lb.for_webserver.arn
}
