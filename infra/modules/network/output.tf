output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_public_1a_id" {
  value = aws_subnet.public_1a.id
}

output "subnet_public_1c_id" {
  value = aws_subnet.public_1c.id
}

output "subnet_private_1a_id" {
  value = aws_subnet.private_1a.id
}

output "subnet_private_1c_id" {
  value = aws_subnet.private_1c.id
}