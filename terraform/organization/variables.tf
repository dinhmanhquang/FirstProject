variable "management_account_name" {
  type = string
}
variable "management_account_email" {
  type = string
}
variable "monthly_billing_threshold" {
  type    = number
  default = "500"
}
variable "currency" {
  type    = string
  default = "USD"
}
variable "organization_unit_name" {
  type = string
}
