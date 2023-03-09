resource "aws_cloudwatch_dashboard" "cloudwatch_dashboard" {
  dashboard_name = var.name
  dashboard_body = <<EOF
{
   "widgets":[
      {
        "type":"metric",
        "width":6,
        "height":4,
        "properties":{
          "view":"singleValue",
          "metrics":[
            [
              "ECS/ContainerInsights",
              "DesiredTaskCount",
              "ServiceName",
              "${var.name}",
              "ClusterName",
              "${var.name}",
              {
               "color":"#2ca02c",
               "period":60
              }
           ],
           [
              ".",
              "RunningTaskCount",
              ".",
              ".",
              ".",
              ".",
              {
                 "color":"#d62728",
                 "period":60
              }
           ]
          ],
          "region":"${var.region}",
          "period":300,
          "stacked":false,
          "title":"ECS WEB tasks status"

        }
      },
      {
        "type":"metric",
        "width":6,
        "height":4,
        "properties":{
          "view":"singleValue",
          "metrics":[
            [
              "ECS/ContainerInsights",
              "DesiredTaskCount",
              "ServiceName",
              "${var.name}_sidekiq",
              "ClusterName",
              "${var.name}",
              {
               "color":"#2ca02c",
               "period":60
              }
           ],
           [
              ".",
              "RunningTaskCount",
              ".",
              ".",
              ".",
              ".",
              {
                 "color":"#d62728",
                 "period":60
              }
           ]
          ],
          "region":"${var.region}",
          "period":300,
          "stacked":false,
          "title":"ECS Sidekiq tasks status"

        }
      },
      {
         "type":"metric",
         "width":6,
         "height":4,
         "properties":{
            "view":"singleValue",
            "metrics":[
               [
                  "AWS/ApplicationELB",
                  "HealthyHostCount",
                  "TargetGroup",
                  "${var.aws_alb_target_group_blue_arn_suffix}",
                  "LoadBalancer",
                  "${var.aws_alb_arn_suffix}",
                  { "color": "#1f77b4", "label": "Blue" }
               ],
               [
                  ".",
                  ".",
                  ".",
                  "${var.aws_alb_target_group_green_arn_suffix}",
                  ".",
                  ".",
                  { "label": "Green", "color": "#2ca02c" }
               ]
            ],
            "region":"${var.region}",
            "period":60,
            "stacked":false,
            "title": "Healthy Hosts Count"
         }
      },
      {
         "type":"metric",
         "width":6,
         "height":4,
         "properties":{
            "view":"singleValue",
            "metrics":[
               [
                  "AWS/ApplicationELB",
                  "UnHealthyHostCount",
                  "TargetGroup",
                  "${var.aws_alb_target_group_blue_arn_suffix}",
                  "LoadBalancer",
                  "${var.aws_alb_arn_suffix}",
                  { "color": "#1f77b4", "label": "Blue" }
               ],
               [
                  "...",
                  "${var.aws_alb_target_group_green_arn_suffix}",
                  ".",
                  ".",
                  { "label": "Green", "color": "#2ca02c" }
               ]
            ],
            "region":"${var.region}",
            "period":60,
            "stacked":false,
            "title":"UnHealthy Hosts Count"
         }
      },
      {
         "type":"metric",
         "width":12,
         "height":6,
         "properties":{
            "view":"timeSeries",
            "stacked":false,
            "metrics":[
               [ "AWS/ECS", "MemoryUtilization", "ServiceName", "${var.name}", "ClusterName", "${var.name}", { "label": "Minimum", "stat": "Minimum", "color": "#2ca02c" } ],
               [ "...", { "stat": "Average", "label": "Average" } ],
               [ "...", { "color": "#1f77b4", "stat": "Maximum", "label": "Maximum" } ]
            ],
            "region":"${var.region}",
            "period":300,
            "title":"Memory utilization Web"
         }
      },
      {
         "type":"metric",
         "width":12,
         "height":6,
         "properties":{
            "view":"timeSeries",
            "stacked":false,
            "metrics":[
               [ "AWS/ECS", "CPUUtilization", "ServiceName", "${var.name}", "ClusterName", "${var.name}", { "label": "Maximum", "stat": "Maximum" } ],
               [ "...", { "stat": "Average", "label": "Average" } ],
               [ "...", { "stat": "Minimum", "label": "Minimum" } ]
            ],
            "region":"${var.region}",
            "period":300,
            "title":"CPU utilization Web"
         }
      },
      {
         "type":"metric",
         "width":12,
         "height":6,
         "properties":{
            "view":"timeSeries",
            "stacked":false,
            "metrics":[
               [ "AWS/ECS", "MemoryUtilization", "ServiceName", "${var.name}_sidekiq", "ClusterName", "${var.name}", { "label": "Minimum", "stat": "Minimum", "color": "#2ca02c" } ],
               [ "...", { "stat": "Average", "label": "Average" } ],
               [ "...", { "color": "#1f77b4", "stat": "Maximum", "label": "Maximum" } ]
            ],
            "region":"${var.region}",
            "period":300,
            "title":"Memory utilization Sidekiq"
         }
      },
      {
         "type":"metric",
         "width":12,
         "height":6,
         "properties":{
            "view":"timeSeries",
            "stacked":false,
            "metrics":[
               [ "AWS/ECS", "CPUUtilization", "ServiceName", "${var.name}_sidekiq", "ClusterName", "${var.name}", { "label": "Maximum", "stat": "Maximum" } ],
               [ "...", { "stat": "Average", "label": "Average" } ],
               [ "...", { "stat": "Minimum", "label": "Minimum" } ]
            ],
            "region":"${var.region}",
            "period":300,
            "title":"CPU utilization Sidekiq"
         }
      },
      {
         "type":"metric",
         "width":12,
         "height":6,
         "properties":{
            "view":"timeSeries",
            "stacked":false,
            "metrics":[
               [ "AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", "${var.aws_alb_arn_suffix}", { "id": "m1", "label": "HTTPCode_ELB_5XX_Count" } ],
               [ ".", "HTTPCode_ELB_4XX_Count", ".", ".", { "id": "m2", "label": "HTTPCode_ELB_4XX_Count" } ],
               [ ".", "HTTPCode_ELB_3XX_Count", ".", ".", { "id": "m3", "label": "HTTPCode_ELB_3XX_Count" } ]
            ],
            "region":"${var.region}",
            "title":"Load Balancer responses",
            "period":300,
            "stat": "Sum"
         }
      },
      {
         "type":"metric",
         "width":12,
         "height":6,
         "properties":{
            "view":"timeSeries",
            "stacked":false,
            "metrics":[
               [ "AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "LoadBalancer", "${var.aws_alb_arn_suffix}", { "id": "m4", "label": "HTTPCode_Target_2XX_Count" } ],
               [ ".", "HTTPCode_Target_3XX_Count", ".", ".", { "id": "m5", "label": "HTTPCode_Target_3XX_Count" } ],
               [ ".", "HTTPCode_Target_4XX_Count", ".", ".", { "id": "m7", "label": "HTTPCode_Target_4XX_Count" } ],
               [ ".", "HTTPCode_Target_5XX_Count", ".", ".", { "id": "m6", "label": "HTTPCode_Target_5XX_Count" } ]
            ],
            "region":"${var.region}",
            "title":"HTTPCode Backend responses",
            "period":300,
            "stat": "Sum"
         }
      },
      {
         "type":"metric",
         "width":12,
         "height":6,
         "properties":{
            "view":"timeSeries",
            "stacked":false,
            "metrics":[
               [
                  "AWS/ApplicationELB",
                  "TargetResponseTime",
                  "LoadBalancer",
                  "${var.aws_alb_arn_suffix}",
                  {
                     "period":60,
                     "stat":"p50"
                  }
               ],
               [
                  "...",
                  {
                     "period":60,
                     "stat":"p90",
                     "color":"#c5b0d5"
                  }
               ],
               [
                  "...",
                  {
                     "period":60,
                     "stat":"p99",
                     "color":"#dbdb8d"
                  }
               ]
            ],
            "region":"${var.region}",
            "period":300,
            "title":"Container response times"
         }
      },
      {
        "width": 12,
        "height": 6,
        "type": "metric",
        "properties": {
          "metrics": [
            [ "AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", "${var.db_identifier}" ]
          ],
          "view": "timeSeries",
          "stacked": false,
          "region":"${var.region}",
          "stat": "Average",
          "title": "Max DB Connections",
          "period": 300,
          "annotations": {
            "horizontal": [
              {
                "label": "Max",
                "value": ${var.database_max_simultaneous_connections_warning}
              }
            ]
          }
        }
      },
      {
        "type": "metric",
        "width": 12,
        "height": 6,
        "properties": {
            "metrics": [
                [ "AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "${var.db_identifier}" ]
            ],
            "period": 300,
            "view": "timeSeries",
            "stacked": false,
            "start": "-PT3H",
            "end": "P0D",
            "title": "DB CPU Utilization",
            "region": "${var.region}"
          }
      },
      {
        "type": "metric",
        "width": 12,
        "height": 6,
        "properties": {
          "metrics": [
            [ "AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", "${var.db_identifier}"]
          ],
          "period": 300,
          "view": "bar",
          "stacked": false,
          "title": "RDS FreeStorageSpace",
          "region": "${var.region}",
          "annotations": {
            "horizontal": [
              {
                  "label": "Attention",
                  "value": ${var.database_free_storage_space_warning},
                  "fill": "below"
              }
            ]
          }
        }
      },
      {
        "type": "metric",
        "width": 12,
        "height": 6,
        "properties": {
          "metrics": [
              [ "AWS/RDS", "FreeableMemory", "DBInstanceIdentifier", "${var.db_identifier}" ]
          ],
          "period": 300,
          "view": "timeSeries",
          "stacked": false,
          "start": "-PT3H",
          "end": "P0D",
          "title": "RDS FreeableMemory",
          "region": "${var.region}"
        }
      },
      {
        "type": "metric",
        "width": 12,
        "height": 6,
        "properties": {
            "metrics": [
              [ "AWS/RDS", "WriteIOPS", "DBInstanceIdentifier", "${var.db_identifier}" ]
            ],
            "period": 300,
            "view": "timeSeries",
            "stacked": false,
            "start": "-PT3H",
            "end": "P0D",
            "title": "RDS WriteIOPS",
            "region": "${var.region}"
        }
      },
      {
        "type": "metric",
        "width": 12,
        "height": 6,
        "properties": {
          "metrics": [
              [ "AWS/RDS", "WriteLatency", "DBInstanceIdentifier", "${var.db_identifier}" ]
          ],
          "period": 300,
          "view": "timeSeries",
          "stacked": false,
          "start": "-PT3H",
          "end": "P0D",
          "title": "RDS - WriteLatency",
          "region": "${var.region}"
        }
      },
      {
        "type": "metric",
        "width": 12,
        "height": 6,
        "properties": {
          "metrics": [
            [ "AWS/RDS", "ReadLatency", "DBInstanceIdentifier", "${var.db_identifier}" ]
          ],
          "period": 300,
          "view": "timeSeries",
          "stacked": false,
          "start": "-PT3H",
          "end": "P0D",
          "title": "RDS - ReadLatency",
          "region": "${var.region}"
        }
      },
      {
        "type": "metric",
        "width": 12,
        "height": 6,
        "properties": {
          "metrics": [
            [ "AWS/RDS", "ReadIOPS", "DBInstanceIdentifier", "${var.db_identifier}"]
          ],
          "period": 300,
          "view": "timeSeries",
          "stacked": false,
          "start": "-PT3H",
          "end": "P0D",
          "title": "RDS - ReadIOPS",
          "region": "${var.region}"
        }
      },
      {
        "type": "metric",
        "width": 12,
        "height": 6,
        "properties": {
          "metrics": [
            [ "AWS/RDS", "WriteThroughput", "DBInstanceIdentifier", "${var.db_identifier}"]
          ],
          "period": 300,
          "view": "timeSeries",
          "stacked": false,
          "start": "-PT3H",
          "end": "P0D",
          "title": "RDS - WriteThroughput",
          "region": "${var.region}"
        }
      },
      {
        "type": "metric",
        "width": 12,
        "height": 6,
        "properties": {
          "metrics": [
            ["AWS/ElastiCache", "CurrConnections", "CacheClusterId", "${var.redis_name}"]
          ],
          "period": 300,
          "view": "timeSeries",
          "stacked": false,
          "start": "-PT3H",
          "end": "P0D",
          "title": "Redis Connection",
          "region": "${var.region}"
        }
      },
      {
        "type": "metric",
        "width": 12,
        "height": 6,
        "properties": {
          "metrics": [
            ["AWS/ElastiCache", "CacheHits", "CacheClusterId", "${var.redis_name}"],
            ["AWS/ElastiCache", "CacheMisses", "CacheClusterId", "${var.redis_name}"]
          ],
          "stat": "Average",
          "period": 300,
          "view": "timeSeries",
          "stacked": false,
          "start": "-PT3H",
          "end": "P0D",
          "title": "Redis Cache Hits/Misses",
          "region": "${var.region}"
        }
      },
      {
        "type": "metric",
        "width": 12,
        "height": 6,
        "properties": {
          "metrics": [
            ["AWS/ElastiCache", "SwapUsage", "CacheClusterId", "${var.redis_name}"]
          ],
          "stat": "Average",
          "period": 300,
          "view": "timeSeries",
          "stacked": false,
          "start": "-PT3H",
          "end": "P0D",
          "title": "Redis Swap Usage",
          "region": "${var.region}"
        }
      },
      {
        "type": "metric",
        "width": 12,
        "height": 6,
        "properties": {
          "metrics": [
            ["AWS/ElastiCache", "Evictions", "CacheClusterId", "${var.redis_name}"]
          ],
          "stat": "Average",
          "period": 300,
          "view": "timeSeries",
          "stacked": false,
          "start": "-PT3H",
          "end": "P0D",
          "title": "Redis Evictions",
          "region": "${var.region}"
        }
      }
  ]
}
EOF
}