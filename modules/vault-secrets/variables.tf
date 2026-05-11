variable "vault_type" {
  description = "The type of vault to access (liquibase, devops)"
  type        = string
  validation {
    # "lbio" removed from list — TECHOPS-161 (vault deprecated)
    condition     = contains(["liquibase", "devops"], var.vault_type)
    error_message = "Vault type must be one of: liquibase, devops."
  }
}

variable "secret_keys" {
  description = "List of specific secret keys to retrieve from the vault. If empty, all secrets will be returned."
  type        = list(string)
  default     = []
}

variable "aws_region" {
  description = "AWS region where the secrets are stored"
  type        = string
  default     = "us-east-1"
}

variable "role_arn" {
  description = "ARN of the IAM role to assume for accessing the vault. If not provided, will use the default vault-specific OIDC role."
  type        = string
  default     = null
}


