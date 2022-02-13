#!/bin/bash
# A sample script to migrate cards from one project board to another
#  
# 1. The script requires Github auth token for API communication
# https://github.com/settings/tokens/new?scopes=repo
#
# 2. To discover the board ids, you can call the following endpoints with 
# the Authorization and Accept headers used throughout this script:
# GET /orgs/{org}/projects
# GET /users/{username}/projects
# GET /repos/{owner}/{repo}/projects
#
# Bear in mind that the Accept header application/vnd.github.inertia-preview+json
# indicates that the API is in preview period and may be subject to change
# https://docs.github.com/en/rest/reference/projects

# To get the ID
# curl -H "Authorization: token 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" -H "Accept: application/vnd.github.inertia-preview+json" https://api.github.com/repos/hmcc-global/hmcchk-web/projects

# Filter when migrating cards
# is:open project:hmcc-global/hmcchk-web/3 

GITHUB_AUTH_TOKEN=<FILL-IN>
SOURCE_PROJECT_ID=<FILL-IN>
TARGET_PROJECT_ID=<FILL-IN>

sourceColumnIds=( $(curl \
  -H "Authorization: token ${GITHUB_AUTH_TOKEN}" \
  -H "Accept: application/vnd.github.inertia-preview+json" \
  https://api.github.com/projects/${SOURCE_PROJECT_ID}/columns | jq '.[].id') )

targetColumnIds=( $(curl \
  -H "Authorization: token ${GITHUB_AUTH_TOKEN}" \
  -H "Accept: application/vnd.github.inertia-preview+json" \
  https://api.github.com/projects/${TARGET_PROJECT_ID}/columns | jq '.[].id') )

echo "Source project column ids:"; printf '%s\n' "${sourceColumnIds[@]}"
echo "Target project column ids:"; printf '%s\n' "${targetColumnIds[@]}"

if [ "${#videos[@]}" -ne "${#subtitles[@]}" ]; then
    echo "Different number of columns in between projects"
    exit -1
fi

for sourceColumnIndex in "${!sourceColumnIds[@]}"
do
    sourceColumnId=${sourceColumnIds[$sourceColumnIndex]}
    sourceColumnId=${sourceColumnId//[^a-zA-Z0-9_]/}
    targetColumnId=${targetColumnIds[$sourceColumnIndex]}
    targetColumnId=${targetColumnId//[^a-zA-Z0-9_]/}
    curl \
      -H "Authorization: token ${GITHUB_AUTH_TOKEN}" \
      -H "Accept: application/vnd.github.inertia-preview+json" \
      https://api.github.com/projects/columns/${sourceColumnId}/cards \
      | jq reverse \
      | jq -c '.[]' \
      | while read card; do
        note=$(jq '.note' <<< "$card")
        data='{"note":'${note}'}'
        curl \
          -w 'HTTP Status: %{http_code}' --silent --output /dev/null \
          -X POST \
          -H "Authorization: token ${GITHUB_AUTH_TOKEN}" \
          -H "Accept: application/vnd.github.inertia-preview+json" \
          -d "${data}" \
          https://api.github.com/projects/columns/${targetColumnId}/cards
        echo " for card migration: ${note}"
    done
done

