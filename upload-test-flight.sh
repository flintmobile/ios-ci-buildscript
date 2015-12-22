#!/bin/bash
#
# Copy the ipa build by the xcodeServer and upload it to Hockey App
# Note: The locations may be different for every xcode release.
#

echo "Preparing to distribute app via TestFlight"
echo "------------------------------------------"

SOURCE_DIR="${XCS_SOURCE_DIR}"
IPA_DIR="${XCS_OUTPUT_DIR}/ExportedProduct/Apps"
DSYM_DIR="${XCS_OUTPUT_DIR}/FlintCardScanner.xcarchive"
DSYM_FILE="FlintCardScanner.app.dSYM"

echo "Fetching commit logs"
RECENT_COMMITS_FILE="/Users/Shared/XcodeServer/recentCommits_Prod.log"
RECENT_COMMITS=$(<$RECENT_COMMITS_FILE)
echo $RECENT_COMMITS
echo " "

if [ "$RECENT_COMMITS" == "" ]; then
	echo "No changes! NOT Uploading to TestFlight"
else
	# Using the assets built by xcode server
	cd $SOURCE_DIR
	SUB_FOLDER="Prodution Product"
	mkdir $SUB_FOLDER
	
	echo "Copy ipa to source folder"
	cp "$IPA_DIR/FlintCardScanner.ipa" "$SOURCE_DIR/$SUB_FOLDER/FlintCardScanner.ipa"

	echo "Copy dsym to source folder"
	cp -R "$DSYM_DIR/dSYMs/$DSYM_FILE" "$SOURCE_DIR/$SUB_FOLDER"

	cd $SUB_FOLDER
	echo "Zipping dSYM"
	zip -r "$DSYM_FILE.zip" "$DSYM_FILE"
	echo " "
	
	# Debug current build number
	PLIST_FILE="$SOURCE_DIR/FlintCreditCard/FlintCardScanner/FlintCardScanner-Info.plist"
	PLIST_BUILD_NUM_STR=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$PLIST_FILE")
	
	echo "Upload to TestFlight Build $PLIST_BUILD_NUM_STR"
	ipa distribute:itunesconnect -a $ITUNES_ACCOUNT -p $ITUNES_PASSWORD --save-keychain --apple-id $ITUNES_APP_ID --upload  
fi
