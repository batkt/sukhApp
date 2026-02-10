cd /Users/macbookairm4/sukhApp
./scripts/sync_alternate_icons_from_primary.sh
flutter clean
flutter pub get
#!/usr/bin/env bash
# Copy primary AppIcon images into black, blue, green so alternate icons
# show the same as default (fixes blank icon on home screen).
# Run from project root: ./scripts/sync_alternate_icons_from_primary.sh

set -e
cd "$(dirname "$0")/.."
SRC="ios/Runner/Assets.xcassets/AppIcon.appiconset"

for set in black blue green; do
  DST="ios/Runner/Assets.xcassets/${set}.appiconset"
  for f in "$SRC"/Icon-App-*.png; do
    [ -f "$f" ] && cp -f "$f" "$DST/"
  done
  touch "$DST/Contents.json"
  echo "Synced AppIcon → $set.appiconset"
done
echo ""
echo "Done. Next: delete the app from your iPhone, then in Xcode:"
echo "  Product → Clean Build Folder (Shift+Cmd+K)"
echo "  Product → Run (Cmd+R)"
echo "  (Or: Xcode → Window → Projects → Runner → Delete Derived Data, then build)"
