#!/bin/bash
#
# Copy the ipa build by the xcodeServer and upload it to Hockey App
# Note: The IPA_DIR may be different for every xcode release.
#

function usage()
{
    echo "Copy the ipa build by the xcodeServer and upload it to Hockey App. This script is ran as an after trigger for the bot that archive the FlintCardScanner Staging scheme"
	echo "Options:"
	echo "========"
    echo -e "\t-h --help"
	echo -e "\t-a --account Hockey App API Key. This is required"
	echo -e "\t--appstore Mark this as an app store build in release note"
	echo -e "\t-b --branch The branch to apply this script to. Default to dev"
    echo " "
}

# Argument Parsing
HOCKEY_APP_API_KEY=""
IS_APP_STORE_BUILD=0
BRANCH="dev"

while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | sed 's/^[^=]*=//g'`
    case $PARAM in
        -h | --help)
            usage
            exit
            ;;
        -a | --account)
            HOCKEY_APP_API_KEY="$VALUE"
            ;;
        --appstore)
            IS_APP_STORE_BUILD=1
            ;;
        -b | --branch)
            BRANCH="$VALUE"
            ;;
        *)
            echo "ERROR: unknown parameter \"$PARAM\""
            usage
            exit 1
            ;;
    esac
    shift
done

echo "Preparing to distribute app via Hockey App"
echo "------------------------------------------"

SOURCE_DIR="${XCS_SOURCE_DIR}"
IPA_DIR="${XCS_OUTPUT_DIR}/ExportedProduct/Apps"
DSYM_DIR="${XCS_OUTPUT_DIR}/FlintCardScanner Staging.xcarchive"
DSYM_FILE="FlintCardScanner.app.dSYM"

echo "Fetching commit logs"

# Geting last commit hash
LAST_COMMIT_FILE="/Users/Shared/XcodeServer/FlintCardScanner/$BRANCH/Staging/lastCommitHash.log"
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
	
	echo "Upload to Hockey App Build $PLIST_BUILD_NUM_STR"
	NOTES="$RECENT_COMMITS"
	if [ IS_APP_STORE_BUILD ]; then
		NOTES="Release Candidate: $RECENT_COMMITS"
	fi
	
	echo "$NOTES"
	#ipa distribute:hockeyapp -a "$HOCKEY_APP_API_KEY" --release beta --notes "$NOTES"
fi

# Update the last commit hash on file
git -C $GIT_SOURCE rev-parse HEAD > $LAST_COMMIT_FILE