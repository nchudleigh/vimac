# https://github.com/iseebi/TransporterPad/blob/master/appcenter-post-build.sh
BUNDLE_IDENTIFIER=dexterleng.vimac
DISTRIBUTION_FILE=$APPCENTER_OUTPUT_DIRECTORY/Vimac_distribution.zip
xcrun altool --notarize-app --primary-bundle-id $BUNDLE_IDENTIFIER --username $AC_USERNAME --password $AC_PASSWORD --file $DISTRIBUTION_FILE
