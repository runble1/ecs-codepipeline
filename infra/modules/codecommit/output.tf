output "repository_id" {
  value = aws_codecommit_repository.this.repository_id
}

output "clone_url_http" {
  value = aws_codecommit_repository.this.clone_url_http
}

output "arn" {
  value = aws_codecommit_repository.this.arn
}
