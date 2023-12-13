provider "aws" {
  region = "us-east-1"
}

module "foo_lambda" {
  source = "github.com/samuel-phan/terraform-aws-lambda"

  function_name = "foo"
  description   = "foo lambda"
  handler       = "index.handler"
  runtime       = "python3.10"
  timeout       = 60

  source_path = "src/foo"
  trigger_on_package_timestamp = false
}
