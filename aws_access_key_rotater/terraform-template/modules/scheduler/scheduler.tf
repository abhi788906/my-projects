resource "aws_cloudwatch_event_rule" "lambda_event_rule" {
  name        = var.scheduler_name
  description = "Trigger Lambda function every day"

  schedule_expression = var.cron_expression  # Schedule for the first day of every month at midnight UTC

}

resource "aws_cloudwatch_event_target" "event_target_lambda" {
  arn  = "${var.lambda_arn}"
  target_id = "access-key-schedule-check"
  rule = aws_cloudwatch_event_rule.lambda_event_rule.id
}

resource "aws_lambda_permission" "scheduler_trigger" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = var.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_event_rule.arn
}