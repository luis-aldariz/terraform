variable "environment" {
  type = "string"
}

variable "domain" {
  type = "string"
}

variable "table" {
  type = "string"
}

variable "attributes" {
  type = "list"
}

variable "hash_key" {
  type = "string"
}

variable "range_key" {
  type    = "string"
  default = ""
}

variable "read_capacity" {
  default = 1
}

variable "write_capacity" {
  default = 1
}

variable "indexes" {
  type = "list"

  default = []
}

variable "stream_enabled" {
  type    = "string"
  default = "false"
}

variable "stream_view_type" {
  type    = "string"
  default = ""
}

variable "autoscaling_enabled" {
  type    = "string"
  default = "false"
}

variable "min_read_capacity" {
  default = 1
}

variable "max_read_capacity" {
  default = 100
}

variable "min_write_capacity" {
  default = 1
}

variable "max_write_capacity" {
  default = 100
}

variable "target_capacity" {
  default = 70
}

variable "enable_point_in_time_recovery" {
  type        = "string"
  default     = "false"
  description = "Enable DynamoDB point in time recovery"
}

locals {
  index_count = "${length(var.indexes)}"
  table_name  = "${var.environment}-${var.domain}-${var.table}"

  table_arn = "${join("",coalescelist(
    aws_dynamodb_table.table-with-0-index.*.arn,
    aws_dynamodb_table.table-with-1-index.*.arn,
    aws_dynamodb_table.table-with-2-index.*.arn,
    aws_dynamodb_table.table-with-3-index.*.arn,
    aws_dynamodb_table.table-with-4-index.*.arn
  ))}"

  autoscaling_count  = "${var.autoscaling_enabled == "true" ? 1 : 0}"
  min_read_capacity  = "${var.autoscaling_enabled == "true" && var.read_capacity < var.min_read_capacity ? var.read_capacity : var.min_read_capacity}"
  max_read_capacity  = "${var.autoscaling_enabled == "true" && var.read_capacity > var.max_read_capacity ? var.read_capacity : var.max_read_capacity}"
  min_write_capacity = "${var.autoscaling_enabled == "true" && var.write_capacity < var.min_write_capacity ? var.write_capacity : var.min_write_capacity}"
  max_write_capacity = "${var.autoscaling_enabled == "true" && var.write_capacity > var.max_write_capacity ? var.write_capacity : var.max_write_capacity}"

  billing_mode = "${var.autoscaling_enabled == "ondemand" ? "PAY_PER_REQUEST" : "PROVISIONED"}"
}

data "aws_iam_role" "DynamoDBAutoscaleRole" {
  name = "DynamoDBAutoscaleRole"
}

resource "aws_appautoscaling_target" "dynamodb_table_read_target" {
  count              = "${local.autoscaling_count}"
  max_capacity       = "${local.max_read_capacity}"
  min_capacity       = "${local.min_read_capacity}"
  resource_id        = "table/${local.table_name}"
  role_arn           = "${data.aws_iam_role.DynamoDBAutoscaleRole.arn}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "dynamodb_table_read_policy" {
  count              = "${local.autoscaling_count}"
  name               = "DynamoDBReadCapacityUtilization:${aws_appautoscaling_target.dynamodb_table_read_target.resource_id}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = "${aws_appautoscaling_target.dynamodb_table_read_target.resource_id}"
  scalable_dimension = "${aws_appautoscaling_target.dynamodb_table_read_target.scalable_dimension}"
  service_namespace  = "${aws_appautoscaling_target.dynamodb_table_read_target.service_namespace}"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }

    target_value = "${var.target_capacity}"
  }
}

resource "aws_appautoscaling_target" "dynamodb_table_write_target" {
  count              = "${local.autoscaling_count}"
  max_capacity       = "${local.max_write_capacity}"
  min_capacity       = "${local.min_write_capacity}"
  resource_id        = "table/${local.table_name}"
  role_arn           = "${data.aws_iam_role.DynamoDBAutoscaleRole.arn}"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "dynamodb_table_write_policy" {
  count              = "${local.autoscaling_count}"
  name               = "DynamoDBWriteCapacityUtilization:${aws_appautoscaling_target.dynamodb_table_write_target.resource_id}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = "${aws_appautoscaling_target.dynamodb_table_write_target.resource_id}"
  scalable_dimension = "${aws_appautoscaling_target.dynamodb_table_write_target.scalable_dimension}"
  service_namespace  = "${aws_appautoscaling_target.dynamodb_table_write_target.service_namespace}"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }

    target_value = "${var.target_capacity}"
  }
}

resource "aws_dynamodb_table" "table-with-0-index" {
  count = "${local.index_count == 0 ? 1 : 0}"

  name             = "${local.table_name}"
  read_capacity    = "${var.read_capacity}"
  write_capacity   = "${var.write_capacity}"
  hash_key         = "${var.hash_key}"
  range_key        = "${var.range_key}"
  attribute        = "${var.attributes}"
  stream_enabled   = "${var.stream_enabled}"
  stream_view_type = "${var.stream_view_type}"

  billing_mode = "${local.billing_mode}"

  point_in_time_recovery {
    enabled = "${var.enable_point_in_time_recovery}"
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = ["read_capacity", "write_capacity"]
  }

  tags {
    TERRAFORM = "${var.environment}/${var.domain}"
  }
}

resource "aws_dynamodb_table" "table-with-1-index" {
  count = "${local.index_count == 1 ? 1 : 0}"

  name             = "${local.table_name}"
  read_capacity    = "${var.read_capacity}"
  write_capacity   = "${var.write_capacity}"
  hash_key         = "${var.hash_key}"
  range_key        = "${var.range_key}"
  attribute        = "${var.attributes}"
  stream_enabled   = "${var.stream_enabled}"
  stream_view_type = "${var.stream_view_type}"

  billing_mode = "${local.billing_mode}"

  lifecycle {
    prevent_destroy = true
    ignore_changes  = ["read_capacity", "write_capacity"]
  }

  global_secondary_index {
    name               = "${lookup(var.indexes[0], "name")}"
    hash_key           = "${lookup(var.indexes[0], "hash_key")}"
    range_key          = "${lookup(var.indexes[0], "range_key", "")}"
    write_capacity     = "${lookup(var.indexes[0], "write_capacity", 1)}"
    read_capacity      = "${lookup(var.indexes[0], "read_capacity", 1)}"
    projection_type    = "${lookup(var.indexes[0], "projection_type", "ALL")}"
    non_key_attributes = ["${compact(list(lookup(var.indexes[0], "non_key_attributes", "")))}"]
  }

  tags {
    TERRAFORM = "${var.environment}/${var.domain}"
  }
}

resource "aws_dynamodb_table" "table-with-2-index" {
  count = "${local.index_count == 2 ? 1 : 0}"

  name             = "${local.table_name}"
  read_capacity    = "${var.read_capacity}"
  write_capacity   = "${var.write_capacity}"
  hash_key         = "${var.hash_key}"
  range_key        = "${var.range_key}"
  attribute        = "${var.attributes}"
  stream_enabled   = "${var.stream_enabled}"
  stream_view_type = "${var.stream_view_type}"

  billing_mode = "${local.billing_mode}"

  lifecycle {
    prevent_destroy = true
    ignore_changes  = ["read_capacity", "write_capacity"]
  }

  global_secondary_index {
    name               = "${lookup(var.indexes[0], "name")}"
    hash_key           = "${lookup(var.indexes[0], "hash_key")}"
    range_key          = "${lookup(var.indexes[0], "range_key", "")}"
    write_capacity     = "${lookup(var.indexes[0], "write_capacity", 1)}"
    read_capacity      = "${lookup(var.indexes[0], "read_capacity", 1)}"
    projection_type    = "${lookup(var.indexes[0], "projection_type", "ALL")}"
    non_key_attributes = ["${compact(list(lookup(var.indexes[0], "non_key_attributes", "")))}"]
  }

  global_secondary_index {
    name               = "${lookup(var.indexes[1], "name")}"
    hash_key           = "${lookup(var.indexes[1], "hash_key")}"
    range_key          = "${lookup(var.indexes[1], "range_key", "")}"
    write_capacity     = "${lookup(var.indexes[1], "write_capacity", 1)}"
    read_capacity      = "${lookup(var.indexes[1], "read_capacity", 1)}"
    projection_type    = "${lookup(var.indexes[1], "projection_type", "ALL")}"
    non_key_attributes = ["${compact(split(",", lookup(var.indexes[1], "non_key_attributes", "")))}"]
  }

  tags {
    TERRAFORM = "${var.environment}/${var.domain}"
  }
}

resource "aws_dynamodb_table" "table-with-3-index" {
  count = "${local.index_count == 3 ? 1 : 0}"

  name             = "${local.table_name}"
  read_capacity    = "${var.read_capacity}"
  write_capacity   = "${var.write_capacity}"
  hash_key         = "${var.hash_key}"
  range_key        = "${var.range_key}"
  attribute        = "${var.attributes}"
  stream_enabled   = "${var.stream_enabled}"
  stream_view_type = "${var.stream_view_type}"

  billing_mode = "${local.billing_mode}"

  lifecycle {
    prevent_destroy = true
    ignore_changes  = ["read_capacity", "write_capacity"]
  }

  global_secondary_index {
    name               = "${lookup(var.indexes[0], "name")}"
    hash_key           = "${lookup(var.indexes[0], "hash_key")}"
    range_key          = "${lookup(var.indexes[0], "range_key", "")}"
    write_capacity     = "${lookup(var.indexes[0], "write_capacity", 1)}"
    read_capacity      = "${lookup(var.indexes[0], "read_capacity", 1)}"
    projection_type    = "${lookup(var.indexes[0], "projection_type", "ALL")}"
    non_key_attributes = ["${compact(list(lookup(var.indexes[0], "non_key_attributes", "")))}"]
  }

  global_secondary_index {
    name               = "${lookup(var.indexes[1], "name")}"
    hash_key           = "${lookup(var.indexes[1], "hash_key")}"
    range_key          = "${lookup(var.indexes[1], "range_key", "")}"
    write_capacity     = "${lookup(var.indexes[1], "write_capacity", 1)}"
    read_capacity      = "${lookup(var.indexes[1], "read_capacity", 1)}"
    projection_type    = "${lookup(var.indexes[1], "projection_type", "ALL")}"
    non_key_attributes = ["${compact(split(",", lookup(var.indexes[1], "non_key_attributes", "")))}"]
  }

  global_secondary_index {
    name               = "${lookup(var.indexes[2], "name")}"
    hash_key           = "${lookup(var.indexes[2], "hash_key")}"
    range_key          = "${lookup(var.indexes[2], "range_key", "")}"
    write_capacity     = "${lookup(var.indexes[2], "write_capacity", 1)}"
    read_capacity      = "${lookup(var.indexes[2], "read_capacity", 1)}"
    projection_type    = "${lookup(var.indexes[2], "projection_type", "ALL")}"
    non_key_attributes = ["${compact(split(",", lookup(var.indexes[2], "non_key_attributes", "")))}"]
  }
}

resource "aws_dynamodb_table" "table-with-4-index" {
  count = "${local.index_count == 4 ? 1 : 0}"

  name             = "${local.table_name}"
  read_capacity    = "${var.read_capacity}"
  write_capacity   = "${var.write_capacity}"
  hash_key         = "${var.hash_key}"
  range_key        = "${var.range_key}"
  attribute        = "${var.attributes}"
  stream_enabled   = "${var.stream_enabled}"
  stream_view_type = "${var.stream_view_type}"

  billing_mode = "${local.billing_mode}"

  lifecycle {
    prevent_destroy = true
    ignore_changes  = ["read_capacity", "write_capacity"]
  }

  global_secondary_index {
    name               = "${lookup(var.indexes[0], "name")}"
    hash_key           = "${lookup(var.indexes[0], "hash_key")}"
    range_key          = "${lookup(var.indexes[0], "range_key", "")}"
    write_capacity     = "${lookup(var.indexes[0], "write_capacity", 1)}"
    read_capacity      = "${lookup(var.indexes[0], "read_capacity", 1)}"
    projection_type    = "${lookup(var.indexes[0], "projection_type", "ALL")}"
    non_key_attributes = ["${compact(list(lookup(var.indexes[0], "non_key_attributes", "")))}"]
  }

  global_secondary_index {
    name               = "${lookup(var.indexes[1], "name")}"
    hash_key           = "${lookup(var.indexes[1], "hash_key")}"
    range_key          = "${lookup(var.indexes[1], "range_key", "")}"
    write_capacity     = "${lookup(var.indexes[1], "write_capacity", 1)}"
    read_capacity      = "${lookup(var.indexes[1], "read_capacity", 1)}"
    projection_type    = "${lookup(var.indexes[1], "projection_type", "ALL")}"
    non_key_attributes = ["${compact(split(",", lookup(var.indexes[1], "non_key_attributes", "")))}"]
  }

  global_secondary_index {
    name               = "${lookup(var.indexes[2], "name")}"
    hash_key           = "${lookup(var.indexes[2], "hash_key")}"
    range_key          = "${lookup(var.indexes[2], "range_key", "")}"
    write_capacity     = "${lookup(var.indexes[2], "write_capacity", 1)}"
    read_capacity      = "${lookup(var.indexes[2], "read_capacity", 1)}"
    projection_type    = "${lookup(var.indexes[2], "projection_type", "ALL")}"
    non_key_attributes = ["${compact(split(",", lookup(var.indexes[2], "non_key_attributes", "")))}"]
  }

  global_secondary_index {
    name               = "${lookup(var.indexes[3], "name")}"
    hash_key           = "${lookup(var.indexes[3], "hash_key")}"
    range_key          = "${lookup(var.indexes[3], "range_key", "")}"
    write_capacity     = "${lookup(var.indexes[3], "write_capacity", 1)}"
    read_capacity      = "${lookup(var.indexes[3], "read_capacity", 1)}"
    projection_type    = "${lookup(var.indexes[3], "projection_type", "ALL")}"
    non_key_attributes = ["${compact(split(",", lookup(var.indexes[3], "non_key_attributes", "")))}"]
  }

  tags {
    TERRAFORM = "${var.environment}/${var.domain}"
  }
}

output "read_policy" {
  value = <<EOF
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:BatchGetItem",
                "dynamodb:DescribeTable",
                "dynamodb:GetItem",
                "dynamodb:Scan",
                "dynamodb:Query",
                "dynamodb:DescribeTable",
                "dynamodb:ConditionCheckItem"
            ],
            "Resource": [
                "${local.table_arn}/index/*",
                "${local.table_arn}"
            ]
        }
EOF
}

output "write_policy" {
  value = <<EOF
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:BatchWriteItem",
                "dynamodb:PutItem",
                "dynamodb:DeleteItem",
                "dynamodb:UpdateItem",
                "dynamodb:ConditionCheckItem"
            ],
            "Resource": [
                "${local.table_arn}/index/*",
                "${local.table_arn}"
            ]
        }
EOF
}

output "arn" {
  value = "${local.table_arn}"
}

output "name" {
  value = "${local.table_name}"
}
