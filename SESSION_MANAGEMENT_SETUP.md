# Session Management & Auto-Logout Setup

## Overview
The app now includes automatic logout after 12 hours of login with push notifications to inform users when their session has expired.

## Features Implemented

### 1. Session Tracking
- Login timestamp is saved when user successfully logs in
- Session is valid for 12 hours from login time
- Session is checked on:
  - App startup
  - App returning to foreground (from background)

### 2. Auto-Logout
- After 12 hours, the user is automatically logged out
- All authentication data is cleared
- User is redirected to login screen

### 3. Notifications
- When session expires and user tries to access the app, a notification is shown
- Notification informs user that their session has expired
- User needs to login again

## Files Created/Modified

### New Files
1. `lib/services/notification_service.dart` - Handles local notifications
2. `lib/services/session_service.dart` - Manages session validation and auto-logout

### Modified Files
1. `pubspec.yaml` - Added `flutter_local_notifications` package
2. `lib/main.dart` - Added lifecycle observer to check session
3. `lib/services/api_service.dart` - Save login timestamp on successful login

## Platform-Specific Setup Required

### Android Setup
Add the following to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Add these permissions -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>

    <application>
        <!-- Add this receiver inside <application> tag -->
        <receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"
            android:exported="false" />
        <receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver"
            android:exported="false">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
            </intent-filter>
        </receiver>
    </application>
</manifest>
```

### iOS Setup
No additional setup required. Permissions are requested at runtime.

## Usage

### For Developers

#### Check Session Status
```dart
import 'package:sukh_app/services/session_service.dart';

// Check if session is valid
bool isValid = await SessionService.isSessionValid();

// Get remaining time
Duration? remaining = await SessionService.getRemainingSessionTime();

// Get session info (for debugging)
Map<String, dynamic> info = await SessionService.getSessionInfo();
print('Login time: ${info['loginTime']}');
print('Valid: ${info['isValid']}');
print('Remaining hours: ${info['remainingHours']}');
```

#### Manual Logout
```dart
await SessionService.logout();
```

#### Send Custom Notification
```dart
import 'package:sukh_app/services/notification_service.dart';

await NotificationService.showNotification(
  id: 1,
  title: 'Title',
  body: 'Message',
  payload: 'optional_data',
);
```

## Testing

### Test Auto-Logout (Development)
To test the auto-logout feature without waiting 12 hours:

1. Temporarily change session duration in `lib/services/session_service.dart`:
```dart
static const Duration _sessionDuration = Duration(minutes: 1); // For testing
```

2. Login to the app
3. Wait 1 minute
4. Close the app and reopen it (or send to background and bring back)
5. You should see the notification and be logged out

**Important:** Change it back to 12 hours after testing!

## How It Works

1. **On Login:**
   - User logs in successfully
   - Current timestamp is saved to SharedPreferences
   - User can access the app

2. **On App Start:**
   - App checks if user is logged in
   - If logged in, checks if 12 hours have passed since login
   - If expired: shows notification, logs out, redirects to login
   - If valid: user continues normally

3. **On App Resume (from background):**
   - Same check as app start
   - Ensures session is validated whenever user returns to app

4. **Notification:**
   - Uses flutter_local_notifications
   - Shows system notification with title and message
   - User can tap notification (currently just prints payload)

## Future Enhancements

Potential improvements you could add:

1. **Extend Session:** Allow users to extend their session before it expires
2. **Activity-Based Timeout:** Reset the timer on user activity
3. **Custom Duration:** Let users choose session duration in settings
4. **Scheduled Check:** Periodically check session in background
5. **Biometric Re-auth:** Allow biometric authentication to extend session
