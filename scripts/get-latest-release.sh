#!/bin/bash

set -e

if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "Set the GITHUB_TOKEN env variable."
	exit 1
fi

get_latest_release_tag() {
  local RELEASE=$(curl -s \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    https://api.github.com/repos/liquibase/liquibase/releases/latest \
  )

  local TAG=$(echo $RELEASE | jq -r '.tag_name')

  if [[ $TAG == v* ]];
  then echo "${TAG:1}";
  else echo $TAG
  fi
}

get_workflow_release_tag() {
  while IFS= read -r line; do
    if [[ $line == *LIQUIBASE_VERSION:* ]];
    then
      echo ${line#*:}
      break
    fi
  done < ./.github/workflows/generate.yml
}

RELEASE_TAG=$(get_latest_release_tag)
WORKFLOW_TAG=$(get_workflow_release_tag)

echo "Release Tag: $RELEASE_TAG \n"
echo "Workflow Tag: $WORKFLOW_TAG \n"

check_docker_hub_for_release() {
  local TAG=$1
  local DOCKER=$(curl -s https://hub.docker.com/v2/namespaces/liquibase/repositories/liquibase/tags?page_size=100)
  local CHECK=$(echo $DOCKER | jq --arg search "$TAG" -r '.results[] | select(.name == $search)')
  if [[ -n "$CHECK" ]]; then
    echo "Docker Tag $TAG found \n"
    return 0
  else
    echo "Docker Tag $TAG not found \n"
    return 1
  fi
}

if [[ "$RELEASE_TAG" != "$WORKFLOW_TAG" ]] && check_docker_hub_for_release "$RELEASE_TAG";
then
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/LIQUIBASE_VERSION: $WORKFLOW_TAG/LIQUIBASE_VERSION: $RELEASE_TAG/g" ./.github/workflows/generate.yml
  else
    sed -i "s/LIQUIBASE_VERSION: $WORKFLOW_TAG/LIQUIBASE_VERSION: $RELEASE_TAG/g" ./.github/workflows/generate.yml
  fi
fi
