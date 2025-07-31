# Vault Secrets Module

A Terraform module for directly accessing AWS Secrets Manager vaults created by the vault-manager stack. This module eliminates the need for remote state dependencies and provides real-time access to secrets without requiring vault-manager plan/apply cycles.

## Features

- **Direct AWS Secrets Manager Access**: Queries secrets directly from AWS without remote state dependencies
- **Cross-Account Authentication**: Uses cross-account IAM role assumption for secure vault access
- **OIDC and Spacelift Support**: Works with both GitHub OIDC and Spacelift role authentication
- **Vault Selection**: Support for all three vault types (liquibase, lbio, devops)
- **Selective Secret Access**: Ability to retrieve specific secrets or all secrets from a vault
- **File Content Access**: Direct access to file-type secrets (like PEM keys) via module outputs
- **Real-time Updates**: Automatically reflects secret changes without Terraform refreshes

## Available Vaults

| Vault Type | Secret Path | Description | Access Pattern |
|------------|-------------|-------------|----------------|
| `liquibase` | `/vault/liquibase` | Repo-wide secrets (LIQUIBOT_PAT_GPM_ACCESS, SONATYPE_USERNAME, etc.) | All repos in liquibase/datical orgs |
| `lbio` | `/vault/lbio` | LBIO-specific secrets (fusionauth_api_key, sendgrid_api_key, etc.) | Specific LBIO repositories only |
| `devops` | `/vault/devops` | DevOps internal tooling secrets | liquibase-infrastructure repo only |

## Usage

### Basic Usage - Get All Secrets

```hcl
module "vault_secrets" {
  source = "../../modules/vault-secrets"
  
  vault_type = "devops"
}

# Access secrets
resource "github_repository" "example" {
  name         = "test-repo"
  private      = true
  description  = "Example using vault secrets"
  
  # Use a secret from the vault
  homepage_url = module.vault_secrets.secrets["HOMEPAGE_URL"]
}
```

### Selective Secret Access

```hcl
module "github_secrets" {
  source = "../../modules/vault-secrets"
  
  vault_type  = "devops"
  secret_keys = ["GITHUB_TOKEN", "GITHUB_APP_ID", "GITHUB_APP_PRIVATE_KEY"]
}

# Use specific secrets
provider "github" {
  token = module.github_secrets.secrets["GITHUB_TOKEN"]
  app_auth {
    id       = module.github_secrets.secrets["GITHUB_APP_ID"]
    pem_file = module.github_secrets.secrets["GITHUB_APP_PRIVATE_KEY"]
  }
}
```

### Custom Role ARN

```hcl
module "vault_secrets" {
  source = "../../modules/vault-secrets"
  
  vault_type = "liquibase"
  role_arn   = "arn:aws:iam::339712820770:role/custom-vault-role"
}
```

### Different AWS Region

```hcl
module "vault_secrets" {
  source = "../../modules/vault-secrets"
  
  vault_type = "lbio"
  aws_region = "us-east-2"
}
```

### File Secrets

For secrets that contain file content (like PEM keys), you can access them directly using the `secrets` output:

```hcl
module "vault_secrets" {
  source = "../../modules/vault-secrets"
  
  vault_type  = "devops"
  secret_keys = ["GITHUB_OWNER", "LIQUIBASE_TERRAFORM_GH_APP_ID", "LIQUIBASE_TERRAFORM_GH_APP_PRIVATE_KEY"]
}

# Use file content directly in provider configuration
provider "github" {
  owner = module.vault_secrets.secrets["GITHUB_OWNER"]
  app_auth {
    id       = module.vault_secrets.secrets["LIQUIBASE_TERRAFORM_GH_APP_ID"]
    pem_file = module.vault_secrets.secrets["LIQUIBASE_TERRAFORM_GH_APP_PRIVATE_KEY"]
  }
}
```

## Authentication

This module uses cross-account IAM role assumption to access vault secrets in the vault-manager AWS account (339712820770). It can be used from different AWS accounts by assuming the appropriate vault-specific OIDC roles:

- **liquibase vault**: `arn:aws:iam::339712820770:role/liquibase-vault-oidc-role`
- **lbio vault**: `arn:aws:iam::339712820770:role/lbio-vault-oidc-role`
- **devops vault**: `arn:aws:iam::339712820770:role/devops-vault-oidc-role`

The module automatically retrieves these role ARNs from the vault-manager remote state, or you can provide a custom `role_arn` parameter.

## Migration from Remote State

To migrate from the current remote state approach:

### Before (using remote state):
```hcl
provider "github" {
  owner = var.GITHUB_OWNER
  app_auth {
    id              = var.LIQUIBASE_TERRAFORM_GH_APP_ID
    installation_id = var.LIQUIBASE_TERRAFORM_GH_INSTALL_ID
    pem_file        = file(var.LIQUIBASE_TERRAFORM_GH_APP_PRIVATE_KEY)
  }
  write_delay_ms = 200 # Performance tuning
}

provider "github" {
  alias = "datical"
  owner = var.GITHUB_OWNER_DATICAL
  app_auth {
    id              = var.LIQUIBASE_TERRAFORM_GH_APP_ID
    installation_id = var.LIQUIBASE_TERRAFORM_GH_INSTALL_ID_DATICAL
    pem_file        = file(var.LIQUIBASE_TERRAFORM_GH_APP_PRIVATE_KEY)
  }
  write_delay_ms = 200 # Performance tuning
}
```

### After (using this module):
```hcl
module "devops_vault_secrets" {
  source     = "../modules/vault-secrets"
  vault_type = "devops"
  secret_keys = [
    "GITHUB_OWNER",
    "GITHUB_OWNER_DATICAL",
    "LIQUIBASE_TERRAFORM_GH_APP_ID",
    "LIQUIBASE_TERRAFORM_GH_INSTALL_ID",
    "LIQUIBASE_TERRAFORM_GH_APP_PRIVATE_KEY",
    "LIQUIBASE_TERRAFORM_GH_INSTALL_ID_DATICAL"
  ]
}

# variables for this are stored in TF as a variable set
provider "github" {
  owner = module.devops_vault_secrets.secrets["GITHUB_OWNER"]
  app_auth {
    id              = module.devops_vault_secrets.secrets["LIQUIBASE_TERRAFORM_GH_APP_ID"]
    installation_id = module.devops_vault_secrets.secrets["LIQUIBASE_TERRAFORM_GH_INSTALL_ID"]
    pem_file        = module.devops_vault_secrets.secrets["LIQUIBASE_TERRAFORM_GH_APP_PRIVATE_KEY"]
  }
  write_delay_ms = 200 # Performance tuning
}

provider "github" {
  alias = "datical"
  owner = module.devops_vault_secrets.secrets["GITHUB_OWNER_DATICAL"]
  app_auth {
    id              = module.devops_vault_secrets.secrets["LIQUIBASE_TERRAFORM_GH_APP_ID"]
    installation_id = module.devops_vault_secrets.secrets["LIQUIBASE_TERRAFORM_GH_INSTALL_ID_DATICAL"]
    pem_file        = module.devops_vault_secrets.secrets["LIQUIBASE_TERRAFORM_GH_APP_PRIVATE_KEY"]
  }
  write_delay_ms = 200 # Performance tuning
}
```
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_secretsmanager_secret.vault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |
| [aws_secretsmanager_secret_version.vault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) | data source |
| [terraform_remote_state.vault_manager](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region where the secrets are stored | `string` | `"us-east-1"` | no |
| <a name="input_role_arn"></a> [role\_arn](#input\_role\_arn) | ARN of the IAM role to assume for accessing the vault. If not provided, will use the default vault-specific OIDC role. | `string` | `null` | no |
| <a name="input_secret_keys"></a> [secret\_keys](#input\_secret\_keys) | List of specific secret keys to retrieve from the vault. If empty, all secrets will be returned. | `list(string)` | `[]` | no |
| <a name="input_vault_type"></a> [vault\_type](#input\_vault\_type) | The type of vault to access (liquibase, lbio, devops) | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_available_keys"></a> [available\_keys](#output\_available\_keys) | List of all available secret keys in the vault |
| <a name="output_secret_values"></a> [secret\_values](#output\_secret\_values) | Individual secret values (only populated when specific secret\_keys are requested) |
| <a name="output_secrets"></a> [secrets](#output\_secrets) | Map of secret keys to their values from the specified vault |
| <a name="output_vault_info"></a> [vault\_info](#output\_vault\_info) | Information about the vault being accessed |
<!-- END_TF_DOCS -->