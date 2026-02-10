#!/usr/bin/env bash
# Clear Xcode/Flutter caches so the app uses the current alternate app icons
# (not the old template). Run from project root.

set -e
cd "$(dirname "$0")/.."

echo "1. Syncing alternate icon sets from primary AppIcon (so they match default)..."
./scripts/sync_alternate_icons_from_primary.sh

echo ""
echo "2. Flutter clean..."
flutter clean
flutter pub get

echo ""
echo "Done. IMPORTANT – do these so the template icon stops showing:"
echo ""
echo "  A) Delete the app from your iPhone/Simulator"
echo "     (long-press app icon → Remove App / Delete App)"
echo ""
echo "  B) Clear Xcode's cache for this project:"
echo "     Xcode → Window → Projects → select 'Runner' → click 'Delete' next to Derived Data"
echo ""
echo "  C) Open the iOS project in Xcode and build from there:"
echo "     open ios/Runner.xcworkspace"
echo "     Then: Product → Clean Build Folder (Shift+Cmd+K)"
echo "     Then: Product → Run (Cmd+R)"
echo ""
echo "Building from Xcode (not 'flutter run') forces the asset catalog to recompile with your current icons."
