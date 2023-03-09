resource "aws_sns_topic" "alerts_ci_slack_notifications_sns_topic" {
  name = "${var.name}-ci"
}

resource "aws_sns_topic_policy" "alerts_ci_slack_notifications_sns_topic_policy" {
  arn    = aws_sns_topic.alerts_ci_slack_notifications_sns_topic.arn
  policy = data.aws_iam_policy_document.alerts_ci_slack_notifications_sns_topic_access.json
}

data "aws_iam_policy_document" "alerts_ci_slack_notifications_sns_topic_access" {
  statement {
    actions = ["sns:Publish"]

    principals {
      type = "Service"
      identifiers = [
        "codestar-notifications.amazonaws.com"
      ]
    }

    resources = [aws_sns_topic.alerts_ci_slack_notifications_sns_topic.arn]
  }
}

resource "aws_codestarnotifications_notification_rule" "aws_codestarnotifications_notification_rule_codepipeline" {
  count = 1

  detail_type = "BASIC"
  event_type_ids = [
    "codepipeline-pipeline-pipeline-execution-failed",
    "codepipeline-pipeline-pipeline-execution-succeeded",
  ]

  name     = "alerts-${var.name}"
  resource = var.aws_codepipeline_arn

  target {
    address = aws_sns_topic.alerts_ci_slack_notifications_sns_topic.arn
  }
}

resource "aws_iam_policy" "chatbot_iam_policy" {
  path        = "/"
  description = "chatbot-iam-policy-${var.name}"
  policy      = data.aws_iam_policy_document.chatbot_iam_policy_document.json
  name        = "chatbot-iam-policy-${var.name}"
}

data "aws_iam_policy_document" "chatbot_iam_policy_document" {
  statement {
    actions = [
      "cloudwatch:Describe*",
      "cloudwatch:Get*",
      "cloudwatch:List*"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role" "chatbot_iam_role" {
  name = "chatbot-iam-role-${var.name}"

  assume_role_policy = data.aws_iam_policy_document.chatbot_assume.json
}

data "aws_iam_policy_document" "chatbot_assume" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"

      identifiers = [
        "chatbot.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role_policy_attachment" "chatbot_iam_role_policy_attachment" {
  role       = aws_iam_role.chatbot_iam_role.id
  policy_arn = aws_iam_policy.chatbot_iam_policy.arn
}

module "chatbot" {
  source = "../chatbot"

  configuration_name = "${var.name}-ci"
  iam_role_arn       = aws_iam_role.chatbot_iam_role.arn
  slack_channel_id   = var.slack_channel_id
  slack_workspace_id = var.slack_workspace_id

  sns_topic_arns = [
    aws_sns_topic.alerts_ci_slack_notifications_sns_topic.arn
  ]
}
