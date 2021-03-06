#!/bin/bash
#
# Automatic build number
#

echo "Handling automatic build number"
echo "-------------------------------"

SOURCE_DIR="${XCS_SOURCE_DIR}/ios-flint-app"
PLIST_FILE="$SOURCE_DIR/FlintCardScanner/FlintCardScanner-Info.plist"
LAST_BUILD_FILE="/Users/Shared/XcodeServer/FlintCardScanner/lastBuildInfo.log"

# Getting the plist build number
PLIST_BUILD_NUM_STR=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$PLIST_FILE")
PLIST_BUILD_NUM=$(($PLIST_BUILD_NUM_STR+0))
echo "current plist build: $PLIST_BUILD_NUM"

# Getting the server last saved automatic build number
LAST_BUILD_INFO_STRING=$(<$LAST_BUILD_FILE)
LAST_BUILD_INFO=($LAST_BUILD_INFO_STRING)
LAST_BUILD_NUM_STR=${LAST_BUILD_INFO[0]}
LAST_BUILD_NUM=$(($LAST_BUILD_NUM_STR+0))
echo "current ci server build: $LAST_BUILD_NUM"

BUILD_NUM=$LAST_BUILD_NUM
if [ $PLIST_BUILD_NUM -gt $LAST_BUILD_NUM ]; then
	BUILD_NUM=$PLIST_BUILD_NUM
fi
echo "Using build number: $BUILD_NUM"
echo " "

# Comparing commmit hash to see if we actually have changes
LAST_BUILD_HASH=${LAST_BUILD_INFO[1]}
echo "Last build hash: $LAST_BUILD_HASH"

LATEST_COMMIT_HASH=$(git -C "$SOURCE_DIR" rev-parse HEAD)
echo "Latest commit hash: $LATEST_COMMIT_HASH"

if [ $LAST_BUILD_HASH == $LATEST_COMMIT_HASH ]; then
	echo "No new commit, not increment build"
else
	BUILD_NUM=$(($BUILD_NUM+1))
	echo "Increase to build $BUILD_NUM"
fi
/usr/libexec/Plistbuddy -c "Set CFBundleVersion $BUILD_NUM" "$PLIST_FILE"

echo " "
echo "Clean up - Update last build info"
echo "$BUILD_NUM $LATEST_COMMIT_HASH"> $LAST_BUILD_FILE
cat $LAST_BUILD_FILE
