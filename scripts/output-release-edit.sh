#!/bin/bash

set -e

TAG=$1

FILE=$(cat commands.json)
COMMANDS="${FILE// /-}" #replace spaces with dashes

for row in $(echo $COMMANDS | jq -r '.[]'); do
    echo "https://github.com/liquibase-github-actions/$row/releases/edit/$TAG"
done
