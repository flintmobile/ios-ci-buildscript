#!/bin/bash
#
# Copy the ipa build by the xcodeServer and upload it to Hockey App
# Note: The locations may be different for every xcode release.
#

echo "Preparing to distribute app via Hockey App"
echo "------------------------------------------"

SOURCE_DIR="${XCS_SOURCE_DIR}"
IPA_DIR="${XCS_OUTPUT_DIR}/ExportedProduct/Apps"
DSYM_DIR="${XCS_OUTPUT_DIR}/FlintCardScanner Staging.xcarchive"
DSYM_FILE="FlintCardScanner.app.dSYM"

echo "Fetching commit logs"

# Geting last commit hash
LAST_COMMIT_FILE="/Users/Shared/XcodeServer/FlintCardScanner/Staging/lastCommitHash.log"
COMMIT_HASH=$(<$LAST_COMMIT_FILE)

# Fetching logs of all commit newer than that hash
GIT_SOURCE="$SOURCE_DIR/FlintCreditCard"
RECENT_COMMITS=$(git -C $GIT_SOURCE log --oneline --no-merges $COMMIT_HASH...HEAD)

echo $RECENT_COMMITS
echo " "

if [ "$RECENT_COMMITS" == "" ]; then
	echo "No changes! NOT Uploading to Hockey App"
else
	# Using the assets built by xcode server
	cd $SOURCE_DIR
	SUB_FOLDER="StagingIPA"
	mkdir $SUB_FOLDER
	
	echo "Copy ipa to source folder"
	cp "$IPA_DIR/FlintCardScanner Staging.ipa" "$SOURCE_DIR/$SUB_FOLDER/FlintCardScanner.ipa"

	echo "Copy dsym to source folder"
	cp -R "$DSYM_DIR/dSYMs/$DSYM_FILE" "$SOURCE_DIR/$SUB_FOLDER/"

	cd $SUB_FOLDER

	echo "Zipping dSYM"
	zip -r "$DSYM_FILE.zip" "$DSYM_FILE"
	echo " "
	
	# Debug current build number
	PLIST_FILE="$SOURCE_DIR/FlintCreditCard/FlintCardScanner/FlintCardScanner-Info.plist"
	PLIST_BUILD_NUM_STR=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$PLIST_FILE")
	
	echo "Hockey App API Key: $1"
	echo "Upload to Hockey App Build $PLIST_BUILD_NUM_STR"
	ipa distribute:hockeyapp -a "$1" --release beta --notes "$RECENT_COMMITS"
fi

# Update the last commit hash on file
git -C $GIT_SOURCE rev-parse HEAD > $LAST_COMMIT_FILE