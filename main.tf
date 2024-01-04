terraform {
  required_version = "1.5.7"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 4.0"
    }
  }
}

provider "github" {
  token = var.BOT_TOKEN
  owner = "liquibase"
}

locals {
  commands = jsondecode(file("${path.module}/commands.json"))
}


