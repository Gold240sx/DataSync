#!/bin/bash

# Colors for terminal output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}DataSyncDesktop Environment Setup${NC}"
echo "This script will help you set up your environment variables for development."

# Check if .env file already exists
if [ -f ".env" ]; then
    echo -e "${YELLOW}Warning: .env file already exists.${NC}"
    read -p "Do you want to overwrite it? (y/n): " overwrite
    if [[ $overwrite != "y" && $overwrite != "Y" ]]; then
        echo "Setup cancelled. Your existing .env file was not modified."
        exit 0
    fi
fi

# Create .env file from template
if [ -f ".env.example" ]; then
    cp .env.example .env
    echo -e "${GREEN}Created .env file from template.${NC}"
else
    echo -e "${RED}Error: .env.example file not found.${NC}"
    echo "Creating a new .env file..."
    
    cat > .env << EOL
# Development credentials
DEV_PASSWORD=
DEV_USER_ID=

# Google Sign-In
GID_CLIENT_ID=
GOOGLE_URL_SCHEME=

# Supabase configuration
SUPABASE_PUBLISHABLE_KEY=
SUPABASE_SECRET_KEY=
SUPABASE_URL=
EOL
    echo -e "${GREEN}Created new .env file.${NC}"
fi

echo -e "${YELLOW}Please edit the .env file with your credentials.${NC}"
echo "After setting up your environment variables, you need to:"
echo "1. Run the sanitize_info_plist.sh script to use these variables in your app"
echo "2. Open the project in Xcode and configure the build settings to use these variables"

echo -e "${GREEN}Setup complete!${NC}"
