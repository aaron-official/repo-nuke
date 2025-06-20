#!/bin/bash
# Dependency installer for Unix/Linux

# Install GitHub CLI if not present
if ! command -v gh &> /dev/null; then
    echo "Installing GitHub CLI..."
    if [ -x "$(command -v apt)" ]; then
        sudo apt update && sudo apt install -y gh
    elif [ -x "$(command -v brew)" ]; then
        brew install gh
    else
        echo "Please install GitHub CLI manually: https://cli.github.com/manual/installation"
        exit 1
    fi
else
    echo "GitHub CLI already installed."
fi

# (Optional) Install jq for JSON parsing
if ! command -v jq &> /dev/null; then
    echo "Installing jq..."
    if [ -x "$(command -v apt)" ]; then
        sudo apt update && sudo apt install -y jq
    elif [ -x "$(command -v brew)" ]; then
        brew install jq
    else
        echo "Please install jq manually: https://stedolan.github.io/jq/download/"
        exit 1
    fi
else
    echo "jq already installed."
fi

# No Python dependencies required for RepoNuke
