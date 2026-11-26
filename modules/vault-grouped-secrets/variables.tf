variable "group" {
  description = "Name of the grouped secret to read, as in vault-manager/grouped-secrets.json (read from /vault/grouped/<group>)"
  type        = string
}

variable "secret_keys" {
  description = "Keys to return from the group. Required: a key missing from the group is left out, so a stack can create a resource only once its key exists."
  type        = list(string)

  validation {
    condition     = length(var.secret_keys) > 0
    error_message = "List the keys this stack uses; an empty list would return the whole group."
  }
}

variable "aws_region" {
  description = "AWS region where the secrets are stored"
  type        = string
  default     = "us-east-1"
}

variable "role_arn" {
  description = "ARN of the IAM role to assume for reading the group. If not provided, uses the group's role from vault-manager (grouped_role_arns)."
  type        = string
  default     = null
}
