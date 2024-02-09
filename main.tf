terraform {
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

data "external" "commands" {
  program = ["cat", "/mnt/workspace/commands.json"]
}

locals {
  commands = jsondecode("{ \"commands\": ${data.external.commands.result} }")["commands"]
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
