#!/bin/bash

# NeuroGuide iPhone Deployment Script
# This script builds and deploys the app to your connected iPhone

set -e  # Exit on error

echo "📱 NeuroGuide iPhone Deployment"
echo "================================"
echo ""

# Check if iPhone is connected
echo "🔍 Checking for connected iPhone..."
DEVICES=$(xcrun xctrace list devices | grep -i iphone | grep -v "Simulator")

if [ -z "$DEVICES" ]; then
    echo "❌ No iPhone detected. Please:"
    echo "   1. Connect your iPhone via USB"
    echo "   2. Unlock your iPhone"
    echo "   3. Trust this computer if prompted"
    echo ""
    exit 1
fi

echo "✅ Found iPhone(s):"
echo "$DEVICES"
echo ""

# Get first iPhone name
DEVICE_NAME=$(echo "$DEVICES" | head -1 | sed 's/ ([^)]*)//g' | awk '{$1=$1};1')
echo "📲 Will deploy to: $DEVICE_NAME"
echo ""

# Check for Team ID
echo "🔐 Checking code signing..."
TEAM_ID=$(security find-identity -v -p codesigning | grep "Apple Development" | head -1 | sed 's/.*(\(.*\)).*/\1/')

if [ -z "$TEAM_ID" ]; then
    echo "⚠️  No development certificate found."
    echo ""
    echo "Please open Xcode and:"
    echo "  1. Go to Xcode → Settings → Accounts"
    echo "  2. Add your Apple ID"
    echo "  3. Click 'Download Manual Profiles'"
    echo ""
    echo "Then re-run this script."
    exit 1
fi

echo "✅ Found Team ID: $TEAM_ID"
echo ""

# Build for device
echo "🔨 Building for iPhone..."
cd "$(dirname "$0")"

xcodebuild \
  -scheme NeuroGuideApp \
  -sdk iphoneos \
  -destination "platform=iOS,name=$DEVICE_NAME" \
  -configuration Debug \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  CODE_SIGN_STYLE=Automatic \
  clean build \
  | grep -E "^\*\*|^==|error:|warning:" || true

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo ""
    echo "❌ Build failed!"
    echo ""
    echo "If you see code signing errors:"
    echo "  1. Open the project in Xcode"
    echo "  2. Select the NeuroGuideApp target"
    echo "  3. Go to Signing & Capabilities"
    echo "  4. Enable 'Automatically manage signing'"
    echo "  5. Select your Team"
    echo ""
    exit 1
fi

echo ""
echo "✅ Build succeeded!"
echo ""

# Find the built app
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/NeuroGuideApp-*/Build/Products/Debug-iphoneos/NeuroGuideApp.app -type d 2>/dev/null | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ Could not find built app"
    exit 1
fi

echo "📦 App built at: $APP_PATH"
echo ""

# Deploy to device
echo "📲 Installing on iPhone..."
xcrun devicectl device install app --device "$DEVICE_NAME" "$APP_PATH" || {
    echo ""
    echo "⚠️  Installation requires trust:"
    echo ""
    echo "On your iPhone:"
    echo "  1. Go to Settings → General → VPN & Device Management"
    echo "  2. Find your developer app section"
    echo "  3. Tap 'Trust [Your Name]'"
    echo "  4. Run this script again"
    echo ""
    exit 1
}

echo ""
echo "✅ Deployment complete!"
echo ""
echo "🎉 NeuroGuideApp is now on your iPhone!"
echo ""
echo "To launch:"
echo "  • Find the NeuroGuideApp icon on your iPhone"
echo "  • Tap to open"
echo ""
echo "To use Live Coach with ML detection:"
echo "  1. Navigate to Live Coach tab"
echo "  2. Tap 'Start Session'"
echo "  3. Grant camera permission when prompted"
echo "  4. Watch real-time arousal detection!"
echo ""
