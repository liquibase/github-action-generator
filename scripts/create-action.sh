#!/bin/bash

COMMAND="${1//-/_}" #replace dashes with underscore
COMMAND="${COMMAND/ /_}" #replace spaces with underscore

VERSION=$2
path="./action/$COMMAND"

if [[ $COMMAND == "global_options" ]]; then
  exit 0
fi

mkdir -p $path
cp global_options.proto $path/global_options.proto
mv $COMMAND.proto $path/$COMMAND.proto
protoc --proto_path=. --liquibase_out=. --liquibase_opt=paths=source_relative --liquibase_opt=version=$VERSION $path/$COMMAND.proto
chmod +x $path/$COMMAND.sh