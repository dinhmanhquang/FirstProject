output "certificate_arn" {
  description = "Certificate ARN"
  value       = aws_acm_certificate_validation.cert_validation.certificate_arn
}
