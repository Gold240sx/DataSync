#!/bin/bash

# Path to the Info.plist file
INFO_PLIST="DataSyncDesktop/Info.plist"
SANITIZED_PLIST="DataSyncDesktop/Info.plist.sanitized"

# Check if the sanitized file exists
if [ -f "$SANITIZED_PLIST" ]; then
    # Make a backup of the original file
    cp "$INFO_PLIST" "${INFO_PLIST}.backup"
    
    # Copy the sanitized version to the actual Info.plist
    cp "$SANITIZED_PLIST" "$INFO_PLIST"
    
    echo "Info.plist has been sanitized. Original file backed up to ${INFO_PLIST}.backup"
else
    echo "Error: Sanitized Info.plist file not found at $SANITIZED_PLIST"
    exit 1
fi
