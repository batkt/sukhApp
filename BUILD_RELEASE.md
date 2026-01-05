# Building Release APK/AAB for Google Play Store

## Prerequisites
- Flutter SDK installed
- Java JDK installed
- Android SDK configured

## Step 1: Create Keystore (If you don't have one)

### Option A: Using PowerShell Script (Windows)
```powershell
cd android
.\create_keystore.ps1
```

### Option B: Manual Creation
```bash
cd android
keytool -genkey -v -keystore upload-keystore.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

**Important:** Remember your passwords! You'll need them for signing.

## Step 2: Create key.properties File

Create a file named `key.properties` in the `android` directory with the following content:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
```

Replace:
- `YOUR_STORE_PASSWORD` with your keystore password
- `YOUR_KEY_PASSWORD` with your key password (can be same as store password)
- `upload` with your key alias if different
- `upload-keystore.jks` with your keystore filename if different

**Security Note:** Add `key.properties` to `.gitignore` to avoid committing passwords!

## Step 3: Build Release Bundle (AAB) - Recommended for Google Play

Google Play Store requires an **Android App Bundle (AAB)** file, not an APK:

```bash
flutter build appbundle --release
```

The AAB file will be located at:
```
build/app/outputs/bundle/release/app-release.aab
```

## Step 4: Build Release APK (Optional)

If you need an APK file instead (for direct distribution or testing):

```bash
flutter build apk --release
```

The APK file will be located at:
```
build/app/outputs/flutter-apk/app-release.apk
```

## Step 5: Upload to Google Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app
3. Go to **Production** → **Create new release**
4. Upload the `app-release.aab` file
5. Fill in release notes and submit for review

## Troubleshooting

### Error: "key.properties not found"
- Make sure `key.properties` exists in the `android` directory
- Check that all properties are correctly set

### Error: "Keystore file not found"
- Verify the `storeFile` path in `key.properties` is correct
- Make sure the keystore file exists in the `android` directory

### Error: "Wrong password"
- Double-check your passwords in `key.properties`
- Ensure there are no extra spaces or special characters

## Current App Version
- Version Name: 1.0.0
- Version Code: 2

To update the version, edit `pubspec.yaml`:
```yaml
version: 1.0.1+3  # versionName+versionCode
```




