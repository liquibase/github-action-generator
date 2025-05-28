terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 4.0"
    }
  }
}

provider "github" {
  owner = "liquibase-github-actions"
  app_auth {
    id              = var.LIQUIBASE_TERRAFORM_GH_APP_ID
    installation_id = var.LIQUIBASE_TERRAFORM_GH_INSTALL_ID_ACTIONS
    pem_file        = file(var.LIQUIBASE_TERRAFORM_GH_APP_PRIVATE_KEY)
  }
  write_delay_ms = 200 # Performance tuning
}

locals {
  commands = jsondecode(file("${path.module}/commands.json"))
}

resource "github_repository" "liquibase-github-actions" {
  for_each      = toset(local.commands)
  name          = replace(each.key, " ", "-")
  description   = "Official GitHub Action to run Liquibase ${title(replace(each.key, "-", " "))}"
  visibility    = "public"
  has_downloads = false
  has_issues    = false
  has_projects  = false
  has_wiki      = false
}
