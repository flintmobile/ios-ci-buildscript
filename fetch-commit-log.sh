#!/bin/bash
#
# Fetching the commit logs using the last
# commits saved on disk. 
#

LAST_COMMIT_FILE="/Users/Shared/XcodeServer/lastCommitHash.log"
RECENT_COMMITS_FILE="/Users/Shared/XcodeServer/recentCommits.log"

echo "get last commit"
cat $LAST_COMMIT_FILE

COMMIT_HASH=$(<$LAST_COMMIT_FILE)
echo "list all changes since $COMMIT_HASH"

GIT_SOURCE="${XCS_SOURCE_DIR}/FlintCreditCard"

git -C $GIT_SOURCE log --oneline --no-merges $COMMIT_HASH...HEAD > $RECENT_COMMITS_FILE

cat $RECENT_COMMITS_FILE

echo "update last commit"
git -C $GIT_SOURCE rev-parse HEAD > $LAST_COMMIT_FILE

cat $LAST_COMMIT_FILE
