#!/bin/bash

# Check for XcodeGen
if ! command -v xcodegen &> /dev/null; then
    echo "XcodeGen could not be found."
    if command -v brew &> /dev/null; then
        echo "Attempting to install via Homebrew..."
        brew install xcodegen
    else
        echo "Please install XcodeGen manually: https://github.com/yonaskolb/XcodeGen"
        echo "Or install Homebrew first: https://brew.sh"
        exit 1
    fi
fi

# Generate Project
echo "Generating Xcode project..."
xcodegen generate

# Open Project
if [ -f "FidelEpilepsy.xcodeproj" ]; then
    echo "Opening project..."
    open FidelEpilepsy.xcodeproj
else
    echo "Failed to generate project. Please check output for errors."
    exit 1
fi
