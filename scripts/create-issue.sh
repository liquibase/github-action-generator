#!/bin/bash

set -e

if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "Set the GITHUB_TOKEN env variable."
	exit 1
fi

COMMAND=$1
REPO="liquibase/github-action-generator"
TITLE="New Action Created: $COMMAND"
BODY="A new action repository has been created for $COMMAND. Please release the first version to the marketplace by creating a [new release here](https://github.com/liquibase-github-actions/$COMMAND/releases)."

curl \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  https://api.github.com/repos/$REPO/issues \
  -d "{\"title\":\"$TITLE\",\"body\":\"$BODY\",\"labels\":[\"enhancement\"]}"