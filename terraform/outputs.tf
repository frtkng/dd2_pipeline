output "bucket"      { value = aws_s3_bucket.dd2.id }
output "instance_id" { value = aws_instance.dd2.id }
output "public_ip"   { value = aws_instance.dd2.public_ip }
output "ssh_command" {
  value = var.key_name != "" ? "ssh -i ${var.key_name}.pem ubuntu@${aws_instance.dd2.public_ip}" : "(SSH disabled)"
}