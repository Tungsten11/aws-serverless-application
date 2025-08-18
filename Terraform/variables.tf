variable "aws_region" {
  default = "ap-southeast-1"
}
variable "table_name" {
  default = "ItemsTable"
}
variable "budget_alert_email" {
  description = "Email for AWS budget alerts"
}
