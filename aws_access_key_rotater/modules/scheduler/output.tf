output "scheduler_arn" {
    value =  aws_cloudwatch_event_rule.lambda_event_rule.arn
    description =  "Event rule arn to cross reference" 
}