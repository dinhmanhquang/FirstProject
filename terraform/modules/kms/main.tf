resource "aws_kms_key" "ecs_exec" {
  description = "KMS key for exec task"
}

resource "aws_kms_alias" "ecs_exec_alias" {
  name          = "alias/ecs-exec-kms-key"
  target_key_id = aws_kms_key.ecs_exec.key_id
}