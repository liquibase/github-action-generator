terraform {
  cloud {
    organization = "liquibase"
    workspaces {
      name = "liquibase-github-actions"
    }
  }
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 4.0"
    }
  }
}

provider "github" {
  token = var.BOT_TOKEN
  owner = "liquibase-github-actions"
}

locals {
  commands = toset(jsondecode(file("${path.module}/commands.json")))
}

resource "github_repository" "liquibase-github-actions" {
  for_each = local.commands
  name            = replace(each.key, " ", "-")
  description     = "Official GitHub Action to run Liquibase ${title(replace(each.key, "-", " "))}"
  visibility      = "public"
  has_downloads   = false
  has_issues      = false
  has_projects    = false
  has_wiki        = false
}
