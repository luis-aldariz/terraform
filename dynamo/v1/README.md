# Dynamo

## Variables

### Required

#### environment

#### domain

#### table

Name for the table

#### attributes

Attribute definitions, should only specify ones used for keys on table or indexes

```
  attributes = [
    {
      name = "id"
      type = "S"
    },
    {
      name = "name"
      type = "S"
    },
  ]
```

#### hash_key

Specify attribute name to be used as the primary key

### Optional

#### range_key

Default: not set  
Specifies attribute for use as range key

#### read_capacity

Default: 1  
Each unit equals 2 reads per second. Only used on creation.

#### write_capacity

Default: 1  
Each unit equals 1 write per second. Only used on creation.

#### indexes

Default: []  
Define global secondary indexes
Support for up to 4 indexes

#### autoscaling_enabled

Default: "false"  
Enables autoscaling for the dynamo table.  
Value "true" requires managing min/max values with below parameters.  
Value "ondemand" enables Dynamo Ondemand Pricing mode where scale is managed by AWS. Capacity values on this module will not apply.

#### min_read_capacity

Default: 1  
Minimum boundry for autoscaling read capacity. Each unit equals 2 reads per second. Ignored if autoscaling is not enabled.

#### max_read_capacity

Default: 100  
Maximum boundry for autoscaling read capacity. Each unit equals 2 reads per second. Ignored if autoscaling is not enabled.

#### min_write_capacity

Default: 1  
Minimum boundry for autoscaling write capacity. Each unit equals 1 write per second. Ignored if autoscaling is not enabled.

#### max_write_capacity

Default: 100  
Maximum boundry for autoscaling write capacity. Each unit equals 1 write per second. Ignored if autoscaling is not enabled.

#### target_capacity

Default: 70  
Range: 0-100  
Target utilization to guide autoscaling.

#### enable_point_in_time_recovery

Default: "false"
Enables DynamoDB point in time recovery

### Outputs

#### read_policy

IAM Policy section targeting read permissions to the table

#### write_policy

IAM Policy section targeting write permissions to the table

#### arn

Table ARN

#### name

Table name

## prevent_destroy

prevent_destroy is set to true to disable the destruction of tables. The intention is that this destruction has to be done by hand to stop data loss.

## Sample

```hcl
module "default" {
  source      = "git@github.com:name/terraform-modules//dynamo/v1"
  environment = "qa1"
  domain      = "test"
  table       = "sample"
  hash_key    = "id"

  attributes = [
    {
      name = "id"
      type = "S"
    },
  ]
}
```

See [test definitions](../tests/main.tf) for additional samples
