#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Check for uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
    echo "Error: You have uncommitted changes. Please commit or stash them before running this script."
    exit 1
fi

recreate_branch() {
    local branch_name=$1

    # Delete local state branch if it exists, continue if it doesn't
    git branch -D $branch_name || echo "No local '$branch_name' branch to delete"

    # Delete remote state branch if it exists, continue if it doesn't
    git push origin --delete $branch_name || echo "No remote '$branch_name' branch to delete"

    # Create a new orphan branch
    git switch --orphan $branch_name

    # Make an empty commit
    git commit --allow-empty -m "Initialize $branch_name branch"

    # Push to remote
    git push origin $branch_name

    # Switch back to main
    git checkout main
}

recreate_branch state
recreate_branch intent