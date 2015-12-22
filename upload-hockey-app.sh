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
RECENT_COMMITS_FILE="/Users/Shared/XcodeServer/recentCommits.log"
RECENT_COMMITS=$(<$RECENT_COMMITS_FILE)
echo $RECENT_COMMITS
echo " "

if [ "$RECENT_COMMITS" == "" ]; then
	echo "No changes! NOT Uploading to Hockey App"
else
	# Using the assets built by xcode server
	echo "Copy ipa to source folder"
	cp "$IPA_DIR/FlintCardScanner Staging.ipa" "$SOURCE_DIR/FlintCardScanner.ipa"

	echo "Copy dsym to source folder"
	cp -R "$DSYM_DIR/dSYMs/$DSYM_FILE" "$SOURCE_DIR/"

	cd $SOURCE_DIR

	echo "Zipping dSYM"
	zip -r "$DSYM_FILE.zip" "$DSYM_FILE"
	echo " "
	
	# Debug current build number
	PLIST_FILE="$SOURCE_DIR/FlintCreditCard/FlintCardScanner/FlintCardScanner-Info.plist"
	PLIST_BUILD_NUM_STR=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$PLIST_FILE")
	
	echo "Upload to Hockey App Build $PLIST_BUILD_NUM_STR"
	ipa distribute:hockeyapp -a $0 --release beta --notes "$RECENT_COMMITS"
fi
