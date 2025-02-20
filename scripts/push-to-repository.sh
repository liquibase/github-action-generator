#!/bin/bash

set -e

if [[ -z "$BOT_TOKEN_TEST" ]]; then
  echo "Set the BOT_TOKEN env variable."
	exit 1
fi

COMMAND="${1/ /-}" #replace spaces with dashes
TAG=$2
REPO="https://liquibot:$BOT_TOKEN@github.com/liquibase-github-actions/$COMMAND.git"
COMMAND_DIR="$PWD/action/${COMMAND//-/_}" #replace dashes with underscore
TEMP_DIR="$PWD/action/temp"

create_issue() {
  local COMMAND=$1
  local REPO="liquibase/github-action-generator"
  local TITLE="New Action Created: $COMMAND"
  local BODY="A new action repository has been created for $COMMAND. Please release the first version to the marketplace by creating a [new release](https://github.com/liquibase-github-actions/$COMMAND/releases) and publishing to the marketplace."

  curl \
    -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $BOT_TOKEN" \
    https://api.github.com/repos/$REPO/issues \
    -d "{\"title\":\"$TITLE\",\"body\":\"$BODY\",\"labels\":[\"enhancement\"]}"
}

create_release() {
  local TAG=$1
  local REPO=$2

  curl \
    -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $BOT_TOKEN" \
    https://api.github.com/repos/liquibase-github-actions/$REPO/releases \
    -d "{\"tag_name\":\"$TAG\",\"name\":\"$TAG\",\"draft\":false,\"prerelease\":false,\"generate_release_notes\":true}"
}

# Set up target repository
{
  mkdir -p $TEMP_DIR
  cd $TEMP_DIR
  git clone --single-branch --depth 1 --branch "main" "$REPO" ./
} || {
  mkdir -p $TEMP_DIR
  cd $TEMP_DIR
  git init
  git remote add origin $REPO

  # create github issue in generator repo
  create_issue $COMMAND
}

# Copy generated files to temp dir
cp $COMMAND_DIR/* $TEMP_DIR

if [[ `git status --porcelain` ]]; then
  # Commit new files
  git add *
  git commit -m "auto generated v$TAG"

  if git show-ref --tags v$TAG --quiet; then
    # if tag exists override
    git tag -f v$TAG
    git push origin --set-upstream main
    git push origin -f v$TAG
  else
    # create and push new tag
    git tag v$TAG
    git push origin v$TAG --set-upstream main
  fi
  create_release v$TAG "$COMMAND"
else
  echo "No files changed."
  exit 0
fi


