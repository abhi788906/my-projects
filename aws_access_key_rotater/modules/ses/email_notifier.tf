resource "aws_ses_email_identity" "email" {
  for_each = toset(var.mails)

  email = each.value
}