#!/bin/bash

# Colors for terminal output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}GitHub Repository Connection${NC}"
echo "This script will help you connect your local repository to your existing GitHub repository."

# Check if git is initialized
if [ ! -d ".git" ]; then
    echo -e "${RED}Error: Git repository not found in the current directory.${NC}"
    exit 1
fi

# Ask for GitHub repository URL
read -p "Enter your GitHub repository URL (e.g., https://github.com/yourusername/DataSync.git): " github_url

if [ -z "$github_url" ]; then
    echo -e "${RED}Error: GitHub repository URL cannot be empty.${NC}"
    exit 1
fi

# Check if remote already exists
remote_exists=$(git remote | grep -c "^origin$")

if [ $remote_exists -eq 0 ]; then
    # Add the remote
    git remote add origin $github_url
    echo -e "${GREEN}Added remote 'origin' with URL: $github_url${NC}"
else
    # Update the remote URL
    git remote set-url origin $github_url
    echo -e "${GREEN}Updated remote 'origin' with URL: $github_url${NC}"
fi

# Verify the remote
echo -e "${YELLOW}Remote configuration:${NC}"
git remote -v

# Ask if user wants to push changes
read -p "Do you want to push your changes to GitHub now? (y/n): " push_now

if [[ $push_now == "y" || $push_now == "Y" ]]; then
    # Get the current branch name
    current_branch=$(git rev-parse --abbrev-ref HEAD)
    
    # Push to GitHub
    echo -e "${YELLOW}Pushing to GitHub...${NC}"
    git push -u origin $current_branch
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Successfully pushed to GitHub!${NC}"
    else
        echo -e "${RED}Failed to push to GitHub. Please check your repository URL and try again.${NC}"
    fi
else
    echo -e "${YELLOW}You can push your changes later using:${NC}"
    echo "git push -u origin $(git rev-parse --abbrev-ref HEAD)"
fi

echo -e "${GREEN}GitHub connection setup complete!${NC}"
