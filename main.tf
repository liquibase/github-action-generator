terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 4.0"
    }
  }
}

# The GitHub App credentials, from the github-terraform-installs grouped secret (TECHOPS-1645).
module "vault_github_terraform_installs" {
  source      = "./modules/vault-grouped-secrets"
  group       = "github-terraform-installs"
  secret_keys = ["LIQUIBASE_TERRAFORM_GH_APP_ID", "LIQUIBASE_TERRAFORM_GH_INSTALL_ID_ACTIONS", "LIQUIBASE_TERRAFORM_GH_APP_PRIVATE_KEY"]
}

provider "github" {
  owner = "liquibase-github-actions"
  app_auth {
    id              = module.vault_github_terraform_installs.secrets["LIQUIBASE_TERRAFORM_GH_APP_ID"]
    installation_id = module.vault_github_terraform_installs.secrets["LIQUIBASE_TERRAFORM_GH_INSTALL_ID_ACTIONS"]
    pem_file        = module.vault_github_terraform_installs.secrets["LIQUIBASE_TERRAFORM_GH_APP_PRIVATE_KEY"]
  }
  write_delay_ms = 200 # Performance tuning
}

locals {
  commands = jsondecode(file("${path.module}/commands.json"))
}

resource "github_repository" "liquibase-github-actions" {
  for_each      = toset(local.commands)
  name          = replace(each.key, " ", "-")
  description   = "🚨 DEPRECATED - Use liquibase/setup-liquibase | Official GitHub Action to run Liquibase ${title(replace(each.key, "-", " "))}"
  homepage_url  = "https://github.com/liquibase/setup-liquibase"
  topics        = ["deprecated", "liquibase-4x-only", "migrate-to-setup-liquibase"]
  visibility    = "public"
  has_downloads = false
  has_issues    = false
  has_projects  = false
  has_wiki      = false
}
