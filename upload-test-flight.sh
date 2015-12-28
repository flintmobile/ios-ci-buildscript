#!/bin/bash
#
# Copy the ipa build by the xcodeServer and upload it to Hockey App
# Note: The locations may be different for every xcode release.
#

echo "Preparing to distribute app via TestFlight"
echo "------------------------------------------"

SOURCE_DIR="${XCS_SOURCE_DIR}"
IPA_DIR="${XCS_OUTPUT_DIR}/ExportedProduct"
DSYM_DIR="${XCS_OUTPUT_DIR}/FlintCardScanner.xcarchive"
DSYM_FILE="FlintCardScanner.app.dSYM"

echo "Fetching commit logs"

# Geting last commit hash
LAST_COMMIT_FILE="/Users/Shared/XcodeServer/lastCommitHash_Prod.log"
COMMIT_HASH=$(<$LAST_COMMIT_FILE)

# Fetching logs of all commit newer than that hash
GIT_SOURCE="$SOURCE_DIR/FlintCreditCard"
RECENT_COMMITS=$(git -C $GIT_SOURCE log --oneline --no-merges $COMMIT_HASH...HEAD)

echo $RECENT_COMMITS
echo " "

if [ "$RECENT_COMMITS" == "" ]; then
	echo "No changes! NOT Uploading to TestFlight"
else
	# Using the assets built by xcode server
	cd $SOURCE_DIR
	SUB_FOLDER="ProductionIPA"
	mkdir $SUB_FOLDER
	
	echo "Copy ipa to source folder"
	cp "$IPA_DIR/FlintCardScanner.ipa" "$SOURCE_DIR/$SUB_FOLDER/FlintCardScanner.ipa"

	echo "Copy dsym to source folder"
	cp -R "$DSYM_DIR/dSYMs/$DSYM_FILE" "$SOURCE_DIR/$SUB_FOLDER"

	cd "$SUB_FOLDER"
	echo "Zipping dSYM"
	zip -r "$DSYM_FILE.zip" "$DSYM_FILE"
	echo " "
	
	# Debug current build number
	PLIST_FILE="$SOURCE_DIR/FlintCreditCard/FlintCardScanner/FlintCardScanner-Info.plist"
	PLIST_BUILD_NUM_STR=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$PLIST_FILE")
	
	echo "Upload to TestFlight Build $PLIST_BUILD_NUM_STR"
	if [ "$2" == "" ]; then
		ipa distribute:itunesconnect -a $1 --apple-id $3 --upload --verbose
	else
		ipa distribute:itunesconnect -a $1 -p $2 --save-keychain --apple-id $3 --upload --verbose
	fi  
fi

# Update the last commit hash on file
git -C $GIT_SOURCE rev-parse HEAD > $LAST_COMMIT_FILE