#!/bin/bash

set -e

if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "Set the GITHUB_TOKEN env variable."
	exit 1
fi

create_issue() {
  local COMMAND=$1
  local REPO="liquibase/github-action-generator"
  local TITLE="New Action Created: $COMMAND"
  local BODY="A new action repository has been created for $COMMAND. Please release the first version to the marketplace by creating a [new release](https://github.com/liquibase-github-actions/$COMMAND/releases) and publishing to the marketplace."

  curl \
    -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    https://api.github.com/repos/$REPO/issues \
    -d "{\"title\":\"$TITLE\",\"body\":\"$BODY\",\"labels\":[\"enhancement\"]}"
}
