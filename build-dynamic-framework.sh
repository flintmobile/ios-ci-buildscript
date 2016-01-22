#!/bin/bash
#
# Build dynamic framework for all architectures
#
# This script is ran on the CI Server after FlintConnectSDK scheme archive succesfully
# Location: XCode > Edit Scheme > Archive > Post-actions
#

# Redirect all output to log file
exec > /tmp/xcode_build_dynamic_framework.log 2>&1

function usage()
{
    echo "Building dynamic framework with all architectures supported. This script is ran on the CI Server after FlintConnectSDK scheme archive succesfully"
    echo "Location: XCode > Edit Scheme > Archive > Post-actions"
	echo "Options:"
	echo "========"
    echo -e "\t-h --help"
    echo " "
}

# Argument Parsing
while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | sed 's/^[^=]*=//g'`
    case $PARAM in
        -h | --help)
            usage
            exit
            ;;
        *)
            echo "ERROR: unknown parameter \"$PARAM\""
            usage
            exit 1
            ;;
    esac
    shift
done

set -e
PRODUCT_FRAMEWORK="${TARGET_NAME}.framework"

DEVICE_DIR="${OBJROOT}/UninstalledProducts/iphoneos"
DEVICE_BIN="$DEVICE_DIR/$PRODUCT_FRAMEWORK"

SIMULATOR_DIR="${SYMROOT}/../../../../Products"

# We have to rebuild simulator because xcode bug does not build i386 arch
echo "Debug Source ========"
ls "${SRCROOT}"
echo "====================="

rm -rf "$SIMULATOR_DIR/Debug-iphonesimulator"
xcodebuild -project "${SRCROOT}/FlintConnect.xcodeproj" -target "FlintConnectSDK" -configuration "Release" -sdk iphonesimulator BUILD_DIR="$SIMULATOR_DIR" BUILD_ROOT="$SIMULATOR_DIR" clean build
SIMULATOR_BIN="$SIMULATOR_DIR/Debug-iphonesimulator/$PRODUCT_FRAMEWORK"

echo "Debug Product ========"
ls "$SIMULATOR_DIR"
echo "======================"

SHARED_DIR="/Users/Shared/XcodeServer/FlintConnectSDK"
ARCHIVE_PATH="$SHARED_DIR/_Archive"
rm -rf "$ARCHIVE_PATH"
mkdir "$ARCHIVE_PATH"

if [ "${CONFIGURATION}" = "Release" ]; then
	if [ -d "$DEVICE_BIN" ]; then
		DEVICE_PATH="$ARCHIVE_PATH/Release"
		mkdir "$DEVICE_PATH"
		echo "Copy framework built for device to $DEVICE_PATH"
		cp -r "$DEVICE_BIN" "$DEVICE_PATH"
		echo "Create placeholder framework to build final product"
		cp -r "$DEVICE_BIN" "$ARCHIVE_PATH"
	fi
	
	if [ -d "$SIMULATOR_BIN" ]; then
		SIMULATOR_PATH="$ARCHIVE_PATH/Debug"
		mkdir "$SIMULATOR_PATH"
		echo "Copy framework built for simulator to $SIMULATOR_PATH"
		cp -r "$SIMULATOR_BIN" "$SIMULATOR_PATH"
	fi
	
	PRODUCT_BIN="$ARCHIVE_PATH/$PRODUCT_FRAMEWORK"
	echo "Combined the architecture for final product at $PRODUCT_BIN"
	lipo -create "$DEVICE_BIN/${TARGET_NAME}" "$SIMULATOR_BIN/${TARGET_NAME}" -output "$PRODUCT_BIN/${TARGET_NAME}"
	
	echo "architectures in the binary"
	lipo -info "$PRODUCT_BIN/${TARGET_NAME}"
	
	echo "Zipping the framework"
	cd "$ARCHIVE_PATH"
	zip -r "$PRODUCT_FRAMEWORK.zip" "$PRODUCT_FRAMEWORK"
fi

exit 0;