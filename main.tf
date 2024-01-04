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
  owner = "liquibase-github-actions"
}

locals {
  commands = jsondecode(["calculate-checksum","changelog-sync","changelog-sync-sql","changelog-sync-to-tag","changelog-sync-to-tag-sql","checks bulk-set","checks copy","checks create","checks customize","checks delete","checks disable","checks enable","checks reset","checks run","checks show","clear-checksums","connect","db-doc","diff","diff-changelog","drop-all","execute-sql","flow","flow validate","future-rollback-count-sql","future-rollback-from-tag-sql","future-rollback-sql","generate-changelog","history","init copy","init project","init start-h2","list-locks","mark-next-changeset-ran","mark-next-changeset-ran-sql","release-locks","rollback","rollback-count","rollback-count-sql","rollback-one-changeset","rollback-one-changeset-sql","rollback-one-update","rollback-one-update-sql","rollback-sql","rollback-to-date","rollback-to-date-sql","set-contexts","set-labels","snapshot","snapshot-reference","status","tag","tag-exists","unexpected-changesets","update","update-count","update-count-sql","update-one-changeset","update-one-changeset-sql","update-sql","update-testing-rollback","update-to-tag","update-to-tag-sql","validate"])
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
