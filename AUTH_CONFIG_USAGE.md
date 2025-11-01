# AuthConfig Usage Guide

## Overview

`AuthConfig` is a singleton class that manages `baiguullagiinId` dynamically throughout your application. It fetches the ID from the `baiguullagaBairshilaarAvya` service based on user's selected location (duureg, districtCode, sohNer).

## File Location

```
lib/core/auth_config.dart
```

## How to Use

### 1. Import the AuthConfig

```dart
import 'package:sukh_app/core/auth_config.dart';
```

### 2. Initialize with Location Data

Initialize `AuthConfig` when the user selects their location:

```dart

final baiguullagiinId = await AuthConfig.instance.initialize(
  duureg: 'Баянгол',
  districtCode: '10201',
  sohNer: '001',
);

if (baiguullagiinId != null) {
  // baiguullagiinId is now stored and can be used
  print('Organization ID: $baiguullagiinId');
} else {
  // Handle error - organization not found
  print('Organization not found for this location');
}
```

### 3. Get baiguullagiinId Anywhere in the App

After initialization, you can access the `baiguullagiinId` from anywhere:

```dart
// Method 1: Using getter property
String? id = AuthConfig.instance.baiguullagiinId;

// Method 2: Using getter method
String? id = AuthConfig.instance.getBaiguullagiinId();

// Method 3: Check if initialized
if (AuthConfig.instance.isInitialized) {
  String id = AuthConfig.instance.baiguullagiinId!;
}
```

### 4. Update Location

Update the location if the user changes their selection:

```dart
final newBaiguullagiinId = await AuthConfig.instance.updateLocation(
  duureg: 'Сүхбаатар',
  districtCode: '10301',
  sohNer: '002',
);
```

### 5. Get All Location Data

```dart
Map<String, String?> locationData = AuthConfig.instance.getLocationData();
// Returns:
// {
//   'baiguullagiinId': '68ecc6add3ec8ad389b64697',
//   'duureg': 'Баянгол',
//   'districtCode': '10201',
//   'sohCode': '001'
// }
```

### 6. Clear Data (e.g., on logout)

```dart
AuthConfig.instance.clear();
```

## Updated Files

The following files have been updated to use `AuthConfig`:

### 1. `lib/screens/burtguulekh/burtguulekh_dorow.dart`

- Registration page (password step)
- Initializes AuthConfig and uses dynamic baiguullagiinId

### 2. `lib/screens/burtguulekh/burtguulekh_guraw.dart`

- Registration page (phone verification step)
- Initializes AuthConfig on phone verification
- Uses cached baiguullagiinId for secret code verification

## Example Flow

### Registration Flow

```dart
// Step 1: User selects location (duureg, horoo, soh)
// Step 2: Phone verification
await AuthConfig.instance.initialize(
  duureg: selectedDuureg,
  districtCode: selectedHoroo,
  sohNer: selectedSoh,
);

// Step 3: Verify phone with dynamic baiguullagiinId
await ApiService.verifyPhoneNumber(
  baiguullagiinId: AuthConfig.instance.baiguullagiinId!,
  utas: phoneNumber,
  duureg: selectedDuureg,
  horoo: selectedHoroo,
  soh: selectedSoh,
);

// Step 4: Verify secret code (reuses stored baiguullagiinId)
await ApiService.verifySecretCode(
  baiguullagiinId: AuthConfig.instance.baiguullagiinId!,
  utas: phoneNumber,
  code: pin,
);

// Step 5: Register user (reuses stored baiguullagiinId)
await ApiService.registerUser({
  'baiguullagiinId': AuthConfig.instance.baiguullagiinId,
  // ... other fields
});
```

## Benefits

1. **Centralized Management**: Single source of truth for baiguullagiinId
2. **No Hardcoding**: Eliminates hardcoded organization IDs
3. **Dynamic Loading**: Automatically fetches correct ID based on location
4. **Easy Access**: Available anywhere in the app via singleton pattern
5. **Caching**: Stores location data to avoid repeated API calls
6. **Type Safety**: Returns null if not found, preventing silent errors

## API Methods Reference

| Method                 | Parameters                      | Returns              | Description                        |
| ---------------------- | ------------------------------- | -------------------- | ---------------------------------- |
| `initialize()`         | duureg?, districtCode?, sohNer? | Future<String?>      | Fetches and stores baiguullagiinId |
| `updateLocation()`     | duureg?, districtCode?, sohNer? | Future<String?>      | Updates location and refetches ID  |
| `getBaiguullagiinId()` | -                               | String?              | Returns stored baiguullagiinId     |
| `getLocationData()`    | -                               | Map<String, String?> | Returns all location data          |
| `clear()`              | -                               | void                 | Clears all stored data             |

## Properties

| Property          | Type    | Description                             |
| ----------------- | ------- | --------------------------------------- |
| `baiguullagiinId` | String? | The stored organization ID              |
| `duureg`          | String? | The stored district                     |
| `districtCode`    | String? | The stored district code                |
| `sohNer`          | String? | The stored SOH code                     |
| `isInitialized`   | bool    | Whether AuthConfig has been initialized |

## Notes

- AuthConfig uses a singleton pattern - always access via `AuthConfig.instance`
- The baiguullagiinId is fetched from `ApiService.getBaiguullagiinId()`
- All parameters in `initialize()` are optional for flexible filtering
- Returns `null` if no matching organization is found
- Data persists throughout app lifecycle until cleared
