resource "aws_cloudwatch_event_connection" "crushyourrace_api_connection" {
  name               = "crushyourrace-api-connection"
  authorization_type = "API_KEY"

  auth_parameters {
    api_key {
      key   = "x-api-key"
      value = var.api_key
    }
  }
}

resource "aws_cloudwatch_event_api_destination" "crushyourrace_daily_destination" {
  name                             = "crushyourrace-daily-destination"
  connection_arn                   = aws_cloudwatch_event_connection.crushyourrace_api_connection.arn
  http_method                      = "POST"
  invocation_endpoint             = "${var.api_base_url}/update-all-users/"
  invocation_rate_limit_per_second = 1
}

resource "aws_cloudwatch_event_rule" "crushyourrace_daily" {
  name                = "crushyourrace-daily"
  description         = "Trigger daily crushyourrace updates at 8:30 PM EST"
  schedule_expression = "cron(30 1 * * ? *)" # 8:30 PM EST
}

resource "aws_iam_role" "eventbridge_api_destination" {
  name = "crushyourrace-daily-eventbridge-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "eventbridge_api_destination" {
  name = "crushyourrace-daily-eventbridge-policy"
  role = aws_iam_role.eventbridge_api_destination.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "events:InvokeApiDestination"
        ]
        Resource = [
          aws_cloudwatch_event_api_destination.crushyourrace_daily_destination.arn
        ]
      }
    ]
  })
}

resource "aws_cloudwatch_event_target" "crushyourrace_daily_target" {
  rule      = aws_cloudwatch_event_rule.crushyourrace_daily.name
  target_id = "crushyourraceDailyTarget"
  arn       = aws_cloudwatch_event_api_destination.crushyourrace_daily_destination.arn
  role_arn  = aws_iam_role.eventbridge_api_destination.arn

  retry_policy {
    maximum_event_age_in_seconds = 3600
    maximum_retry_attempts       = 0
  }
} 