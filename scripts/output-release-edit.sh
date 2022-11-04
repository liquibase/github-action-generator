#!/bin/bash

set -e

TAG=$1

for row in $(jq -r '.[]' commands.json); do
    COMMAND="${row/ /-}" #replace spaces with dashes
    echo "https://github.com/liquibase-github-actions/$COMMAND/releases/edit/$TAG"
done

