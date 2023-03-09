
# alb
resource "aws_cloudwatch_metric_alarm" "elb_loadbalancer" {
  alarm_name                = "${var.name}_load_balancer"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  threshold                 = "10"
  alarm_description         = "Request error rate has exceeded 10%"
  alarm_actions             = [var.action]
  ok_actions                = [var.action]
  insufficient_data_actions = [var.action]
  treat_missing_data        = "notBreaching"

  metric_query {
    id          = "${var.name}_e1"
    expression  = "${var.name}_m2/${var.name}_m1*100"
    label       = "Error Rate"
    return_data = "true"
  }

  metric_query {
    id = "${var.name}_m1"

    metric {
      metric_name = "RequestCount"
      namespace   = "AWS/ApplicationELB"
      period      = "120"
      stat        = "Sum"
      unit        = "Count"

      dimensions = {
        AvailabilityZone = "ap-northeast-1"
        LoadBalancer     = var.aws_lb_web_arn_suffix
        TargetGroup      = var.aws_lb_target_group_blue_arn_suffix
      }
    }
  }

  metric_query {
    id = "${var.name}_m2"

    metric {
      metric_name = "HTTPCode_ELB_5XX_Count"
      namespace   = "AWS/ApplicationELB"
      period      = "120"
      stat        = "Sum"
      unit        = "Count"

      dimensions = {
        AvailabilityZone = "ap-northeast-1"
        LoadBalancer     = var.aws_lb_web_arn_suffix
        TargetGroup      = var.aws_lb_target_group_blue_arn_suffix
      }
    }
  }
}

# end of alb
# start database metric
resource "aws_cloudwatch_metric_alarm" "db_cpu_utilization_too_high" {
  alarm_name                = "${var.name}_rds_high_cpu_utilization"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/RDS"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "60"
  alarm_description         = "Average database CPU utilization is too high."
  ok_actions                = [var.action]
  insufficient_data_actions = [var.action]
  alarm_actions             = [var.action]

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }
}

resource "aws_cloudwatch_metric_alarm" "disk_free_storage_space_too_low" {
  alarm_name                = "${var.name}_rds_disk_free_storage_low"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "2"
  metric_name               = "FreeStorageSpace"
  namespace                 = "AWS/RDS"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "1073741824" #bytes
  alarm_description         = "Average database free storage space is too low and may fill up soon."
  ok_actions                = [var.action]
  insufficient_data_actions = [var.action]
  alarm_actions             = [var.action]

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }
}

resource "aws_cloudwatch_metric_alarm" "memory_freeable_too_low" {
  alarm_name                = "${var.name}_rds_memory_freeable_low"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "2"
  metric_name               = "FreeableMemory"
  namespace                 = "AWS/RDS"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "156000000" #bytes
  alarm_description         = "Average database freeable memory is too low, performance may be negatively impacted."
  ok_actions                = [var.action]
  insufficient_data_actions = [var.action]
  alarm_actions             = [var.action]

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }
}


resource "aws_cloudwatch_metric_alarm" "db_connection_count_anomalous" {
  alarm_name                = "${var.name}_rds_anomalous_connection_count"
  comparison_operator       = "GreaterThanUpperThreshold"
  evaluation_periods        = "2"
  threshold_metric_id       = "rds_e1"
  alarm_description         = "Anomalous database connection count detected. Something unusual is happening."
  ok_actions                = [var.action]
  insufficient_data_actions = [var.action]
  alarm_actions             = [var.action]

  metric_query {
    id          = "rds_e1"
    expression  = "ANOMALY_DETECTION_BAND(rds_m1,100)"
    label       = "DatabaseConnections (Expected)"
    return_data = "true"
  }

  metric_query {
    id          = "rds_m1"
    return_data = "true"
    metric {
      metric_name = "DatabaseConnections"
      namespace   = "AWS/RDS"
      period      = "43200"
      stat        = "Average"
      unit        = "Count"

      dimensions = {
        DBInstanceIdentifier = var.db_instance_id
      }
    }
  }
}

# end of database metric

# redis
resource "aws_cloudwatch_metric_alarm" "cache_cpu" {
  count               = 2
  alarm_name          = "${var.name}_redis_cpu_utilization"
  alarm_description   = "Redis cluster CPU utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = "60"

  dimensions = {
    CacheClusterId = element(var.elasticache_member_clusters, count.index)
  }

  ok_actions                = [var.action]
  insufficient_data_actions = [var.action]
  alarm_actions             = [var.action]
}

resource "aws_cloudwatch_metric_alarm" "cache_memory" {
  count               = 2
  alarm_name          = "${element(var.elasticache_member_clusters, count.index)}-freeable-memory"
  alarm_description   = "Redis cluster freeable memory"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/ElastiCache"
  period              = "60"
  statistic           = "Average"

  threshold = "256000000" #bytes

  dimensions = {
    CacheClusterId = element(var.elasticache_member_clusters, count.index)
  }
}
# end of redis metrics

# WAF
resource "aws_cloudwatch_metric_alarm" "waf_common" {
  alarm_name          = "${var.name}_waf_blocked_request_common"
  alarm_description   = "Request blocked of AWSManagedRulesCommonRuleSet"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  period              = "300"
  statistic           = "Average"
  threshold           = "10"

  dimensions = {
    WebACL = var.waf_web_acl
    Rule   = "AWSManagedRulesCommonRuleSet"
    Region = "ap-northeast-1"
  }

  alarm_actions = [var.action]
}

resource "aws_cloudwatch_metric_alarm" "waf_SQLi" {
  alarm_name          = "${var.name}_waf_blocked_request_sql"
  alarm_description   = "Request blocked of AWSManagedRulesSQLiRuleSet"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  period              = "300"
  statistic           = "Average"
  threshold           = "10"

  dimensions = {
    WebACL = var.waf_web_acl
    Rule   = "AWSManagedRulesSQLiRuleSet"
    Region = "ap-northeast-1"
  }

  alarm_actions = [var.action]
}

resource "aws_cloudwatch_metric_alarm" "waf_badInput" {
  alarm_name          = "${var.name}_waf_blocked_request_common_badInput"
  alarm_description   = "Request blocked of AWSManagedRulesKnownBadInputsRuleSet"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  period              = "300"
  statistic           = "Average"
  threshold           = "10"

  dimensions = {
    WebACL = var.waf_web_acl
    Rule   = "AWSManagedRulesKnownBadInputsRuleSet"
    Region = "ap-northeast-1"
  }

  alarm_actions = [var.action]
}

# end of WAF metrics
# Latency of ALB response time
resource "aws_cloudwatch_metric_alarm" "alb_response_latency" {
  alarm_name                = "${var.name}_alb_response_time_latency"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "3"
  metric_name               = "TargetResponseTime"
  namespace                 = "AWS/ApplicationELB"
  period                    = "300"
  extended_statistic        = "p99"
  threshold                 = "20" #second
  alarm_description         = "The Latency of response time is high"
  ok_actions                = [var.action]
  insufficient_data_actions = [var.action]
  alarm_actions             = [var.action]
  treat_missing_data        = "notBreaching"

  dimensions = {
    LoadBalancer = var.aws_lb_web_arn_suffix
  }
}