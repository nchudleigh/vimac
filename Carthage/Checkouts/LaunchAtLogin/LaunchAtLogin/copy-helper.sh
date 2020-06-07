#!/bin/bash

origin_helper_path="$BUILT_PRODUCTS_DIR/$FRAMEWORKS_FOLDER_PATH/LaunchAtLogin.framework/Resources/LaunchAtLoginHelper.app"
helper_dir="$BUILT_PRODUCTS_DIR/$CONTENTS_FOLDER_PATH/Library/LoginItems"
helper_path="$helper_dir/LaunchAtLoginHelper.app"

rm -rf "$helper_path"
mkdir -p "$helper_dir"
cp -rf "$origin_helper_path" "$helper_dir/"

defaults write "$helper_path/Contents/Info" CFBundleIdentifier -string "$PRODUCT_BUNDLE_IDENTIFIER-LaunchAtLoginHelper"

if [[ $CONFIGURATION == "Release" ]]; then
	rm -rf "$origin_helper_path"
	rm "$(dirname "$origin_helper_path")/copy-helper.sh"
fi
