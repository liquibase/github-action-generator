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

  # create issue in generator repo to release new action to marketplace
}

# Copy generated files to temp dir
cp $COMMAND_DIR/* $TEMP_DIR

# Commit new files and tag
git add *
git commit -m "auto generated v$TAG"
git tag v$TAG

# push commit
git push origin v$TAG --set-upstream main