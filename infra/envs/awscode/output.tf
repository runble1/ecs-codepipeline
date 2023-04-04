output "repository_url" {
  value = module.ecr.repository_url
}

output "public_dns" {
  value = module.alb.public_dns
}

output "codecommit_url" {
  value = module.codecommit.clone_url_http
}
