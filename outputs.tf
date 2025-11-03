output "dynamodb_table_arn" {
  value       = aws_dynamodb_table.contacts.arn
  description = "ARN of the DynamoDB table"
}

output "eb_environment_cname" {
  value       = aws_elastic_beanstalk_environment.env.cname
  description = "CNAME of the EB environment"
}