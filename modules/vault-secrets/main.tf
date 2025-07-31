# Local variables for vault configuration
locals {
  vault_names = {
    liquibase = "liquibase-vault"
    lbio      = "lbio-vault"
    devops    = "devops-vault"
  }

  # The actual secret names in AWS Secrets Manager (using paths, not names)
  vault_secret_names = {
    liquibase = "/vault/liquibase"
    lbio      = "/vault/lbio"
    devops    = "/vault/devops"
  }

  vault_paths = {
    liquibase = "/vault/liquibase"
    lbio      = "/vault/lbio"
    devops    = "/vault/devops"
  }

  # Default OIDC role ARNs for each vault type
  # These are dynamically retrieved from the vault-manager remote state
  default_role_arns = {
    liquibase = data.terraform_remote_state.vault_manager.outputs.liquibase_vault_role_arn
    lbio      = data.terraform_remote_state.vault_manager.outputs.lbio_vault_role_arn
    devops    = data.terraform_remote_state.vault_manager.outputs.devops_vault_role_arn
  }

  # Use provided role ARN or default to vault-specific OIDC role
  role_arn = var.role_arn != null ? var.role_arn : local.default_role_arns[var.vault_type]
}

# Note: Removed GitHub OIDC provider data source as it's not needed by this module

# Get the vault OIDC role ARNs from vault-manager remote state
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


# AWS provider configuration to assume the vault-specific OIDC role
provider "aws" {
  region = var.aws_region

  assume_role {
    role_arn     = local.role_arn
    session_name = "terraform-vault-secrets-${var.vault_type}"
  }

  default_tags {
    tags = {
      ManagedBy = "vault-secrets-module"
      VaultType = var.vault_type
    }
  }
}

# Data source to retrieve the secret from AWS Secrets Manager
data "aws_secretsmanager_secret" "vault" {
  name = local.vault_secret_names[var.vault_type]
}

# Data source to get the actual secret value
data "aws_secretsmanager_secret_version" "vault" {
  secret_id = data.aws_secretsmanager_secret.vault.id
}

# Local to parse the JSON secret and filter by requested keys
locals {
  all_secrets = jsondecode(data.aws_secretsmanager_secret_version.vault.secret_string)

  # If secret_keys is empty, return all secrets; otherwise filter by requested keys
  filtered_secrets = length(var.secret_keys) == 0 ? local.all_secrets : {
    for key in var.secret_keys : key => local.all_secrets[key]
    if contains(keys(local.all_secrets), key)
  }
}
