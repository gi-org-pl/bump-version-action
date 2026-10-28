#!/usr/bin/env bash
set -euo pipefail

if [ -z "$BASE_REF" ]; then
  echo "❌ No base branch. Run the action on a pull request or set the base-ref input."
  exit 1
fi

git fetch --depth=1 origin "$BASE_REF"
NEXT_VERSION=$(git show FETCH_HEAD:./package.json | jq -r '.version' | awk -F. -v OFS=. '{ $3 += 1; print }')

if [ "$(jq -r '.version' package.json)" = "$NEXT_VERSION" ]; then
  echo "✅ The version is already $NEXT_VERSION."
  exit 0
fi

npm version "$NEXT_VERSION" --no-git-tag-version --ignore-scripts
USER_ID=$(gh api "/users/${APP_SLUG}[bot]" --jq '.id')
git config user.name "${APP_SLUG}[bot]"
git config user.email "${USER_ID}+${APP_SLUG}[bot]@users.noreply.github.com"
git commit -am "Bump the version to $NEXT_VERSION [dependabot skip]"
git push

echo "✅ Bumped the version to $NEXT_VERSION."
