#!/bin/bash
#
# Build dynamic framework for all architectures
#
# This script is ran on the CI Server after FlintConnectSDK scheme archive succesfully
# Location: XCode > Edit Scheme > Archive > Post-actions
#

# Redirect all output to log file
exec > /tmp/xcode_build_dynamic_framework.log 2>&1

set -e
PRODUCT_FRAMEWORK="${TARGET_NAME}.framework"

DEVICE_DIR="${OBJROOT}/UninstalledProducts/iphoneos"
DEVICE_BIN="$DEVICE_DIR/$PRODUCT_FRAMEWORK"

SIMULATOR_DIR="${SYMROOT}/../../../../Products/Debug-iphonesimulator/"
SIMULATOR_BIN="$SIMULATOR_DIR/$PRODUCT_FRAMEWORK"

SHARED_DIR="/Users/Shared/XcodeServer/"
ARCHIVE_PATH="$SHARED_DIR/_Archive"
rm -rf "$ARCHIVE_PATH"
mkdir "$ARCHIVE_PATH"

if [ "${CONFIGURATION}" = "Release" ]; then
	if [ -d "$DEVICE_BIN" ]; then
		DEVICE_PATH="$ARCHIVE_PATH/Release"
		mkdir "$DEVICE_PATH"
		echo "Copy framework built for device to $DEVICE_PATH"
		cp -r "$DEVICE_BIN" "$DEVICE_PATH"
		echo "Create place holder framework to build final product"
		cp -r "$DEVICE_BIN" "$ARCHIVE_PATH"
	fi
	
	if [ -d "$SIMULATOR_BIN" ]; then
		SIMULATOR_PATH="$ARCHIVE_PATH/Debug"
		mkdir "$SIMULATOR_PATH"
		echo "Copy framework built for simulator to $SIMULATOR_PATH"
		cp -r "$SIMULATOR_BIN" "$SIMULATOR_PATH"
	fi
	
	PRODUCT_BIN="$ARCHIVE_PATH/$PRODUCT_FRAMEWORK"
	lipo -create "$DEVICE_BIN/${TARGET_NAME}" "$SIMULATOR_BIN/${TARGET_NAME}" -output "$PRODUCT_BIN/${TARGET_NAME}"
	
	# Copy the framework to a shared location
	# ditto "${SIMULATOR_PATH}/${TARGET_NAME}.framework" "${HOME}/Desktop/${TARGET_NAME}.framework"
	# ditto "${SIMULATOR_PATH}/${TARGET_NAME}.framework" "/Users/Shared/XcodeServer/${TARGET_NAME}.framework"
fi

exit 0;