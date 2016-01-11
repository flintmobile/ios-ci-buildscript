#!/bin/bash
#
# Copy the ipa build by the xcodeServer and upload it to Hockey App
# Note: The locations may be different for every xcode release.
#

function usage()
{
    echo "Copy the ipa build by the xcodeServer and upload it to Hockey App. This script is ran as an after trigger for the bot that archive the FlintCardScanner Staging scheme"
	echo "Options:"
	echo "========"
    echo -e "\t-h --help"
	echo -e "\t-a --account the username for Itunes Connect. This is required"
	echo -e "\t-p --password the password for Itunes Connect. This is required"
	echo -e "\t--apple-id the apple id to identify your app. This information can be found on the App page. Also required"
	echo -e "\t-b --branch The branch to apply this script to. Default to dev"
    echo " "
}

# Argument Parsing
ITUNE_USER=""
ITUNE_PWD=""
ITUNE_APP_ID=""
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
            ITUNE_USER="$VALUE"
            ;;
	    -p | --password)
	        ITUNE_PWD="$VALUE"
	        ;;
        --apple-id)
            ITUNE_APP_ID="$VALUE"
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

echo "Preparing to distribute app via TestFlight"
echo "------------------------------------------"

SOURCE_DIR="${XCS_SOURCE_DIR}/FlintCreditCard"
IPA_DIR="${XCS_OUTPUT_DIR}/ExportedProduct"
DSYM_DIR="${XCS_OUTPUT_DIR}/FlintCardScanner.xcarchive"
DSYM_FILE="FlintCardScanner.app.dSYM"

echo "Fetching commit logs"

# Geting last commit hash
LAST_COMMIT_FILE="/Users/Shared/XcodeServer/FlintCardScanner/$BRANCH/Production/lastCommitHash.log"
COMMIT_HASH=$(<$LAST_COMMIT_FILE)

# Fetching logs of all commit newer than that hash
RECENT_COMMITS=$(git -C "$SOURCE_DIR" log --oneline --no-merges $COMMIT_HASH...HEAD)

echo $RECENT_COMMITS
echo " "

if [ "$RECENT_COMMITS" == "" ]; then
	echo "No changes! NOT Uploading to TestFlight"
else
	# Using the assets built by xcode server
	cd "$SOURCE_DIR"
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
	PLIST_FILE="$SOURCE_DIR/FlintCardScanner/FlintCardScanner-Info.plist"
	PLIST_BUILD_NUM_STR=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$PLIST_FILE")
	
	echo "Upload to TestFlight Build $PLIST_BUILD_NUM_STR"
	ipa distribute:itunesconnect -a "$ITUNE_USER" -p $"$ITUNE_PWD" --apple-id "$ITUNE_APP_ID" --upload --verbose  
fi

# Update the last commit hash on file
git -C "$SOURCE_DIR" rev-parse HEAD > $LAST_COMMIT_FILE