resource "aws_ses_domain_identity" "ses" {
  domain = var.domain
}

resource "aws_route53_record" "ses_record" {
  zone_id = var.zone_id
  name    = "_amazonses.${var.domain}"
  type    = "TXT"
  ttl     = "600"
  records = [aws_ses_domain_identity.ses.verification_token]
}

resource "aws_ses_domain_dkim" "dkim" {
  domain = var.domain
}

resource "aws_route53_record" "dkim_record" {
  count   = 3
  zone_id = var.zone_id
  name    = "${element(aws_ses_domain_dkim.dkim.dkim_tokens, count.index)}._domainkey.${var.domain}"
  type    = "CNAME"
  ttl     = "600"
  records = ["${element(aws_ses_domain_dkim.dkim.dkim_tokens, count.index)}.dkim.amazonses.com"]
}

resource "aws_iam_user" "smtp_user" {
  name = "smtp_user"
}

resource "aws_iam_access_key" "smtp_user" {
  user = aws_iam_user.smtp_user.name
}

data "aws_iam_policy_document" "ses_sender" {
  statement {
    actions   = ["ses:SendRawEmail"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ses_sender" {
  name        = "ses_sender"
  description = "Allows sending of e-mails via Simple Email Service"
  policy      = data.aws_iam_policy_document.ses_sender.json
}

resource "aws_iam_user_policy_attachment" "test-attach" {
  user       = aws_iam_user.smtp_user.name
  policy_arn = aws_iam_policy.ses_sender.arn
}
# to use when we develop BE code to dynamic extrac credentials from file and delete file below before pushing to Github
# resource "local_file" "ses_credentials" {
#   content  = "${aws_iam_access_key.smtp_user.id} ${aws_iam_access_key.smtp_user.ses_smtp_password_v4}"
#   filename = "${path.module}/ses_credentials"
# }
