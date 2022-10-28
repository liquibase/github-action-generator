#!/bin/bash

set -e

COMMAND="${1/ /-}" #replace spaces with dashes
TAG=$2
REPO="https://liquibot:$BOT_TOKEN@github.com/liquibase-github-actions/$COMMAND.git"
COMMAND_DIR="$PWD/action/$COMMAND"
TEMP_DIR="$PWD/action/temp"

if [[ -z "$BOT_TOKEN" ]]; then
  echo "Set the BOT_TOKEN env variable."
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
    -H "Authorization: Bearer $BOT_TOKEN" \
    https://api.github.com/repos/$REPO/issues \
    -d "{\"title\":\"$TITLE\",\"body\":\"$BODY\",\"labels\":[\"enhancement\"]}"
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

# Commit new files and tag
git add *
git commit -m "auto generated v$TAG"
git tag v$TAG

# push commit
git push origin v$TAG --set-upstream main