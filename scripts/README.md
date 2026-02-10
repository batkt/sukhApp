# Scripts

## generate_ios_alternate_icons.sh

Generates the **black**, **blue**, and **green** iOS alternate app icons from your logo assets so the home screen shows the real logos instead of placeholders.

**When to run:** After adding or changing `lib/assets/img/logo_3black.jpg`, `logo_3blue.jpg`, or `logo_3green.jpg`.

**From project root:**
```bash
./scripts/generate_ios_alternate_icons.sh
```

Then do a **full clean rebuild**:
1. Delete the app from the device/simulator (removes cached icon).
2. `flutter clean && flutter pub get`
3. In Xcode: **Product → Clean Build Folder**, then build and run.

**If the alternate icon still shows white or blank:**
- Ensure the source logos (`logo_3black.jpg`, etc.) are not mostly white and have clear, visible content.
- In Xcode, open **Runner/Assets.xcassets**, select **black** (or blue/green), and confirm the icon images look correct in the preview.
- Try building from Xcode (not only `flutter run`) so the asset catalog is fully recompiled.

**Requires:** macOS (uses `sips`).

---

## clean_ios_icon_cache.sh

If the **alternate app icon still shows the grid/template** instead of your logo:

1. Run from project root: `./scripts/clean_ios_icon_cache.sh`
2. Then follow the printed steps: delete the app from the device, clear Derived Data in Xcode, and build from Xcode (not `flutter run`).

This forces the asset catalog to be recompiled with the current icon images.
