#!/bin/bash

# Roast Build Script
# This script helps you build the Roast app

set -e

echo "=== Roast Build Script ==="
echo ""

# Check if XcodeGen is installed
if command -v xcodegen &> /dev/null; then
    echo "XcodeGen found. Generating Xcode project..."
    xcodegen generate
    echo ""
    echo "Xcode project generated successfully!"
    echo "Opening Roast.xcodeproj..."
    open Roast.xcodeproj
else
    echo "XcodeGen not found."
    echo ""
    echo "You have two options:"
    echo ""
    echo "Option 1: Install XcodeGen and run this script again"
    echo "  brew install xcodegen"
    echo "  ./build.sh"
    echo ""
    echo "Option 2: Build with Swift Package Manager"
    echo "  swift build"
    echo "  swift run"
    echo ""
    echo "Option 3: Create Xcode project manually"
    echo "  1. Open Xcode"
    echo "  2. Create new macOS App project"
    echo "  3. Copy source files from this directory"
    echo "  4. Add GRDB.swift and Sparkle package dependencies"
    echo "  5. Configure Info.plist and entitlements"
    echo ""

    # Try building with SPM
    read -p "Would you like to try building with Swift Package Manager? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Resolving dependencies..."
        swift package resolve
        echo ""
        echo "Building..."
        swift build
        echo ""
        echo "Build complete! Run with: swift run"
    fi
fi
