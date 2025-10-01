#!/bin/bash

# Update references in the Xcode project file
sed -i '' 's/DataSync\//DataSyncDesktop\//g' DataSync.xcodeproj/project.pbxproj

# Update any file system references
find DataSync.xcodeproj -type f -name "*.pbxproj" -o -name "*.xcscheme" -o -name "*.plist" | xargs sed -i '' 's/DataSync\//DataSyncDesktop\//g'

echo "Project references updated from DataSync/ to DataSyncDesktop/"
