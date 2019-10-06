xcodebuild archive -scheme Vimac -workspace Vimac.xcworkspace/ -archivePath ./build/production.xcarchive
xcodebuild -exportArchive -archivePath ./build/production.xcarchive/ -exportPath ../VimacBuilds -exportOptionsPlist ExportOptions.plist
