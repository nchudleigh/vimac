xcodebuild archive -scheme Vimac -workspace Vimac.xcworkspace/ -archivePath ./build/production.xcarchive
xcodebuild -exportArchive -archivePath ./build/production.xcarchive/ -exportPath ../VimacBuilds -exportOptionsPlist ExportOptions.plist
VERSION=`/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" ./ViMac-Swift/Info.plist`
FILENAME="vimac-${VERSION}.app.zip"
zip -r ../VimacBuilds/"${FILENAME}" ../VimacBuilds/Vimac.app/
./Pods/Sparkle/bin/generate_appcast ../VimacBuilds/
rm -rf ../VimacBuilds/Vimac.app
