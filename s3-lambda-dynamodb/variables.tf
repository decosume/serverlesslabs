
#Create Variables
variable "aws_region" {
  default     = "us-east-1"
}

variable "bucket_name_transactions" {
  default = "pccdatafeed-lab"
}

variable "transactions_name_function" {
  default = "pcc_loadticketsFn"
}

variable "transactions_name_table" {
  default = "pccdatafeedt"
}
