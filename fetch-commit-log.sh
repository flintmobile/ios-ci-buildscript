#!/bin/bash
#
# Fetching the commits log using the last commit hash saved on disk. 
#

echo "Manually pulling the latest commit log since last build"
echo "-------------------------------------------------------"

LAST_COMMIT_FILE="/Users/Shared/XcodeServer/lastCommitHash.log"
RECENT_COMMITS_FILE="/Users/Shared/XcodeServer/recentCommits.log"

# Geting last commit hash
COMMIT_HASH=$(<$LAST_COMMIT_FILE)

# Fetching logs of all commit newer than that hash
GIT_SOURCE="${XCS_SOURCE_DIR}/FlintCreditCard"
git -C $GIT_SOURCE log --oneline --no-merges $COMMIT_HASH...HEAD > $RECENT_COMMITS_FILE

echo "list all changes since $COMMIT_HASH"
cat $RECENT_COMMITS_FILE
echo " "

# Update the last commit hash on file
git -C $GIT_SOURCE rev-parse HEAD > $LAST_COMMIT_FILE

echo "update last commit"
cat $LAST_COMMIT_FILE
