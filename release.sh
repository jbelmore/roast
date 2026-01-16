#!/bin/bash

# Roast Release Script
# Usage: ./release.sh <version> <path-to-app> <private-key>
# Example: ./release.sh 1.0.1 ~/Desktop/Roast.app "YOUR_PRIVATE_KEY"

set -e

VERSION=$1
APP_PATH=$2
PRIVATE_KEY=$3

if [ -z "$VERSION" ] || [ -z "$APP_PATH" ] || [ -z "$PRIVATE_KEY" ]; then
    echo "Usage: ./release.sh <version> <path-to-app> <private-key>"
    echo ""
    echo "Example:"
    echo "  ./release.sh 1.0.1 ~/Desktop/Roast.app \"your-private-key-here\""
    echo ""
    echo "Steps before running:"
    echo "  1. In Xcode: Product → Archive"
    echo "  2. In Organizer: Distribute App → Copy App"
    echo "  3. Run this script with the exported .app path"
    exit 1
fi

ZIP_NAME="Roast-${VERSION}.zip"

echo "=== Roast Release Script ==="
echo ""
echo "Version: $VERSION"
echo "App: $APP_PATH"
echo ""

# Check if Sparkle sign_update exists
SIGN_UPDATE=""
if [ -f "/tmp/Sparkle/build/Release/sign_update" ]; then
    SIGN_UPDATE="/tmp/Sparkle/build/Release/sign_update"
elif command -v sign_update &> /dev/null; then
    SIGN_UPDATE="sign_update"
else
    echo "Error: sign_update tool not found."
    echo ""
    echo "Build it first:"
    echo "  cd /tmp"
    echo "  git clone https://github.com/sparkle-project/Sparkle.git"
    echo "  cd Sparkle"
    echo "  xcodebuild -project Sparkle.xcodeproj -scheme sign_update -configuration Release SYMROOT=build"
    exit 1
fi

# Create ZIP
echo "Creating ZIP..."
cd "$(dirname "$APP_PATH")"
zip -r -y "$ZIP_NAME" "$(basename "$APP_PATH")"
mv "$ZIP_NAME" /tmp/

# Sign
echo "Signing..."
SIGNATURE=$("$SIGN_UPDATE" "/tmp/$ZIP_NAME" -s "$PRIVATE_KEY" 2>&1 | grep "sparkle:edSignature" | sed 's/.*sparkle:edSignature="\([^"]*\)".*/\1/')

if [ -z "$SIGNATURE" ]; then
    # Try alternate output format
    SIGNATURE=$("$SIGN_UPDATE" "/tmp/$ZIP_NAME" -s "$PRIVATE_KEY")
fi

# Get file size
SIZE=$(stat -f%z "/tmp/$ZIP_NAME")

# Get current date in RFC 2822 format
PUBDATE=$(date -R)

echo ""
echo "============================================"
echo "Release ready!"
echo "============================================"
echo ""
echo "ZIP: /tmp/$ZIP_NAME"
echo "Size: $SIZE bytes"
echo "Signature: $SIGNATURE"
echo ""
echo "=== NEXT STEPS ==="
echo ""
echo "1. Create GitHub Release:"
echo "   gh release create v$VERSION /tmp/$ZIP_NAME --title \"v$VERSION\" --notes \"Release notes here\""
echo ""
echo "2. Add this to appcast.xml (before </channel>):"
echo ""
cat << APPCAST
        <item>
            <title>Version $VERSION</title>
            <description><![CDATA[
                <h2>What's New in $VERSION</h2>
                <ul>
                    <li>Your release notes here</li>
                </ul>
            ]]></description>
            <pubDate>$PUBDATE</pubDate>
            <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
            <enclosure
                url="https://github.com/jbelmore/roast/releases/download/v$VERSION/$ZIP_NAME"
                sparkle:version="BUILD_NUMBER_HERE"
                sparkle:shortVersionString="$VERSION"
                length="$SIZE"
                type="application/octet-stream"
                sparkle:edSignature="$SIGNATURE"
            />
        </item>
APPCAST
echo ""
echo "3. Commit and push appcast.xml"
echo ""
echo "4. Done! Users will see the update."
