#!/usr/bin/env bash
# Generate iOS alternate app icons (black, blue, green) from logo assets.
# Run from project root: ./scripts/generate_ios_alternate_icons.sh
# Requires: macOS (uses sips), logo files in lib/assets/img/

set -e
cd "$(dirname "$0")/.."
IOS_ASSETS="ios/Runner/Assets.xcassets"
SRC="lib/assets/img"

# filename → height width (sips -z height width)
sizes() {
  echo "Icon-App-20x20@1x.png 20 20"
  echo "Icon-App-20x20@2x.png 40 40"
  echo "Icon-App-20x20@3x.png 60 60"
  echo "Icon-App-29x29@1x.png 29 29"
  echo "Icon-App-29x29@2x.png 58 58"
  echo "Icon-App-29x29@3x.png 87 87"
  echo "Icon-App-40x40@1x.png 40 40"
  echo "Icon-App-40x40@2x.png 80 80"
  echo "Icon-App-40x40@3x.png 120 120"
  echo "Icon-App-60x60@2x.png 120 120"
  echo "Icon-App-60x60@3x.png 180 180"
  echo "Icon-App-76x76@1x.png 76 76"
  echo "Icon-App-76x76@2x.png 152 152"
  echo "Icon-App-83.5x83.5@2x.png 167 167"
  echo "Icon-App-1024x1024@1x.png 1024 1024"
}

generate_set() {
  local variant=$1
  local src_img=$2
  local out_dir=$3
  if [[ ! -f "$src_img" ]]; then
    echo "Missing source: $src_img"
    return 1
  fi
  echo "Generating $variant from $src_img"
  while read -r filename height width; do
    sips -z "$height" "$width" -s format png "$src_img" --out "$out_dir/$filename"
  done < <(sizes)
}

generate_set "black" "$SRC/logo_3black.jpg" "$IOS_ASSETS/black.appiconset"
generate_set "blue"  "$SRC/logo_3blue.jpg"  "$IOS_ASSETS/blue.appiconset"
generate_set "green" "$SRC/logo_3green.jpg" "$IOS_ASSETS/green.appiconset"

echo "Done. Rebuild the iOS app to see the new alternate icons."
