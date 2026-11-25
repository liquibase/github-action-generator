# Get the grouped role ARNs from vault-manager remote state
data "terraform_remote_state" "vault_manager" {
  backend = "remote"

  config = {
    hostname     = "spacelift.io"
    organization = "liquibase"
    workspaces = {
      name = "vault-manager"
    }
  }
}

locals {
  # Use the provided role ARN or the group's own role (shard 1 keeps the bare group name)
  role_arn = var.role_arn != null ? var.role_arn : data.terraform_remote_state.vault_manager.outputs.grouped_role_arns[var.group]
}

# AWS provider configuration to assume the group's role
provider "aws" {
  region = var.aws_region

  assume_role {
    role_arn     = local.role_arn
    session_name = substr("tf-vault-${var.group}", 0, 64) # AWS caps RoleSessionName at 64
  }

  default_tags {
    tags = {
      ManagedBy = "vault-grouped-secrets-module"
      VaultType = "grouped"
    }
  }
}

# Data source to get the grouped secret value
data "aws_secretsmanager_secret_version" "grouped" {
  secret_id = "/vault/grouped/${var.group}"
}

# Local to parse the JSON secret and filter by requested keys
locals {
  all_secrets = jsondecode(data.aws_secretsmanager_secret_version.grouped.secret_string)

  # Requested keys only; a key missing from the group is left out
  filtered_secrets = {
    for key in var.secret_keys : key => local.all_secrets[key]
    if contains(keys(local.all_secrets), key)
  }
}
