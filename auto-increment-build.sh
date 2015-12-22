#!/bin/bash
#
# Automatic build number
#

PLIST_FILE="${XCS_SOURCE_DIR}/FlintCreditCard/FlintCardScanner/FlintCardScanner-Info.plist"
LAST_BUILD_FILE="/Users/Shared/XcodeServer/lastBuildNum.log"

# Getting the build numbers as string
PLIST_BUILD_STRING=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$PLIST_FILE")
LAST_BUILD_STRING=$(<$LAST_BUILD_FILE)

# Casting them to number and increment
PLIST_BUILD_NUM=$(($PLIST_BUILD_STRING+1))
LAST_BUILD_NUM=$(($LAST_BUILD_STRING+1))

echo "compare plist build $PLIST_BUILD_NUM and server build $LAST_BUILD_NUM"
BUILD_NUM=$LAST_BUILD_NUM
if [ $PLIST_BUILD_NUM -gt $LAST_BUILD_NUM ]; then
echo "using plist build number"
BUILD_NUM=$PLIST_BUILD_NUM
fi

echo "increase to build $BUILD_NUM"
/usr/libexec/Plistbuddy -c "Set CFBundleVersion $BUILD_NUM" "$PLIST_FILE"

echo "update last build file"
echo $BUILD_NUM > $LAST_BUILD_FILE
cat $LAST_BUILD_FILE
