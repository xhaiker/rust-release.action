#!/usr/bin/env bash
set -ex

output="${1:-"header.md"}"

api="$GITHUB_API_URL/repos/$GITHUB_REPOSITORY"
repo="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY"

tag="$GITHUB_REF_NAME"
previous_tag=$(git describe --abbrev=0 --tags `git rev-list --tags --skip=1 --max-count=1` || echo "nil")

if [[ -f "$GITHUB_WORKSPACE/docs/${tag}.md" ]]; then
  cat "$GITHUB_WORKSPACE/docs/${tag}.md" > $output
fi

if [ "$previous_tag" == "nil" ]; then
cat <<EOF | tee $output
## Release $tag
[commits](${repo}/commits)
EOF
else
cat <<EOF | tee $output
## What Different
[${previous_tag}...${tag}](${repo}/compare/${previous_tag}...${tag})
## Full Changelog
$(git log --abbrev-commit --format="[\[%h\]]($repo/commit/%H) %s" --no-merges "${previous_tag}...${tag}")
EOF
fi
