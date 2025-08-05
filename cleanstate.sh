#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Check for uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
    echo "Error: You have uncommitted changes. Please commit or stash them before running this script."
    exit 1
fi

# Delete local state branch if it exists, continue if it doesn't
git branch -D state || echo "No local 'state' branch to delete"

# Delete remote state branch if it exists, continue if it doesn't
git push origin --delete state || echo "No remote 'state' branch to delete"

# Create a new orphan branch
git switch --orphan state

# Make an empty commit
git commit --allow-empty -m "Initialize state branch"

# Push to remote
git push origin state

# Switch back to main
git checkout main