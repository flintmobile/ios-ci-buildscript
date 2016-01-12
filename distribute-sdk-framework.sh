#!/bin/bash
#
# Upload the SDK to the public repository for distribution
#

function usage()
{
    echo "Distribute the SDK framework to github. This script is run after the FlintConnectSDK bot archive completed"
	echo "Options:"
	echo "========"
    echo -e "\t-h --help"
	echo -e "\t-a --account the username for Github. This is required"
	echo -e "\t-p --password the password for Github. This is required"
	echo -e "\t-b --branch The branch to apply this script to. Default to dev"
    echo " "
}

#argument parsing
GIT_USER=""
GIT_PWD=""
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
            GIT_USER="$VALUE"
            ;;
	    -p | --password)
	        GIT_PWD="$VALUE"
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

SHARED_DIR="/Users/Shared/XcodeServer"
FRAMEWORK_DIR="$SHARED_DIR/FlintConnectSDK/_Archive"
DIST_DIR="$SHARED_DIR/ios-flint-connect-sdk"

#determine the sdk version
SOURCE_DIR="${XCS_SOURCE_DIR}/ios-flint-connect"
cd "$SOURCE_DIR"
SDK_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "./Framework/FlintConnect/FlintConnect/Info.plist")
FOLDER="$SDK_VERSION"

if [ "$BRANCH" = "dev" ]; then
	FOLDER="beta"
	SDK_VERSION="$SDK_VERSION-beta"
fi

#Copy over the products
echo "Copy to folder $FOLDER for version $SDK_VERSION"
cd "$DIST_DIR"
git pull
if [ -d "$FOLDER" ]; then
	echo "Remove previous version"
	rm -rf "$FOLDER"
fi

echo "Copy in the new version"
mkdir "$FOLDER"
cp "$FRAMEWORK_DIR/FlintConnectSDK.framework.zip" "$DIST_DIR/$FOLDER"
chmod -R 777 "$FOLDER"
echo " "

#distribute
echo "Commit and upload the framework"
git add .
git commit -am "Update SDK for branch:$BRANCH version:$SDK_VERSION integration:${XCS_INTEGRATION_NUMBER}"
git push "https://$GIT_USER:$GIT_PWD@github.com/flintmobile/ios-flint-connect-sdk.git"