resource "aws_organizations_account" "account" {
  name      = var.management_account_name
  email     = var.management_account_email
  parent_id = aws_organizations_organizational_unit.product.id
}

data "aws_organizations_organization" "account" {

}
resource "aws_organizations_organizational_unit" "product" {
  name      = var.organization_unit_name
  parent_id = data.aws_organizations_organization.account.roots[0].id
}

