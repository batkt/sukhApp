# Authentication Usage Guide

This guide explains how to use the updated authentication system with automatic token storage and management.

## Overview

The authentication system has been updated to:
1. Remove token requirement from the login endpoint
2. Automatically save the authentication token after successful login
3. Automatically include the saved token in authenticated API requests
4. Persist user session data using SharedPreferences

## Login Flow

### Basic Login

```dart
import 'package:sukh_app/services/api_service.dart';

// Login user
try {
  final response = await ApiService.loginUser(
    utas: '99536945',
    nuutsUg: 'password123',
  );

  if (response['success'] == true) {
    // Token and user data are automatically saved!
    print('Login successful!');
    print('User: ${response['result']['ner']}');
    print('Organization: ${response['result']['baiguullagiinNer']}');

    // Navigate to home screen
    // Navigator.pushReplacementNamed(context, '/home');
  }
} catch (e) {
  print('Login failed: $e');
}
```

The `loginUser` method now automatically:
- Sends login request WITHOUT requiring a bearer token
- Receives the response with token
- Saves the token to SharedPreferences
- Saves user data (ID, name, organization, etc.)

## Using Saved Token for API Calls

### Method 1: Using getAuthHeaders() Helper

```dart
import 'package:sukh_app/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Make authenticated API call
final headers = await ApiService.getAuthHeaders();

final response = await http.get(
  Uri.parse('${ApiService.baseUrl}/some-protected-endpoint'),
  headers: headers,
);

if (response.statusCode == 200) {
  final data = json.decode(response.body);
  // Process data
}
```

### Method 2: Manually Getting Token

```dart
import 'package:sukh_app/services/storage_service.dart';
import 'package:http/http.dart' as http;

// Get saved token
final token = await StorageService.getToken();

if (token != null) {
  final response = await http.post(
    Uri.parse('https://api.example.com/endpoint'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: json.encode({'key': 'value'}),
  );
}
```

## Checking Login Status

### On App Startup

```dart
import 'package:sukh_app/core/auth_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize from saved session
  final isLoggedIn = await AuthConfig.instance.initializeFromStorage();

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: isLoggedIn ? '/home' : '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}
```

### Before Protected Routes

```dart
import 'package:sukh_app/services/storage_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final isLoggedIn = await StorageService.isLoggedIn();

    if (!isLoggedIn) {
      // Redirect to login
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Your UI
  }
}
```

## Accessing User Data

### Get Saved User Information

```dart
import 'package:sukh_app/core/auth_config.dart';

// Get all user data
final userData = await AuthConfig.instance.getUserData();
print('User ID: ${userData['userId']}');
print('User Name: ${userData['userName']}');
print('Organization ID: ${userData['baiguullagiinId']}');
print('Organization Name: ${userData['baiguullagiinNer']}');
print('Expiration Date: ${userData['duusakhOgnoo']}');

// Or get individual fields
import 'package:sukh_app/services/storage_service.dart';

final userName = await StorageService.getUserName();
final userId = await StorageService.getUserId();
final orgId = await StorageService.getBaiguullagiinId();
```

## Logout

### Complete Logout

```dart
import 'package:sukh_app/core/auth_config.dart';

// Logout user (clears all auth data)
await AuthConfig.instance.logout();

// Navigate to login screen
Navigator.pushReplacementNamed(context, '/login');
```

### Alternative Using ApiService

```dart
import 'package:sukh_app/services/api_service.dart';

// Logout using API service
await ApiService.logoutUser();

// Navigate to login screen
Navigator.pushReplacementNamed(context, '/login');
```

## Complete Login Example

```dart
import 'package:flutter/material.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/core/auth_config.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.loginUser(
        utas: _phoneController.text,
        nuutsUg: _passwordController.text,
      );

      if (response['success'] == true) {
        // Token is automatically saved!

        // Initialize AuthConfig with user's organization
        if (response['result']?['baiguullagiinId'] != null) {
          AuthConfig.instance.setBaiguullagiinId(
            response['result']['baiguullagiinId']
          );
        }

        // Navigate to home
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showError(response['message'] ?? 'Login failed');
      }
    } catch (e) {
      _showError('Login failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              child: _isLoading
                  ? CircularProgressIndicator()
                  : Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## API Response Structure

When you call `loginUser`, you receive this response:

```json
{
  "result": {
    "_id": "68f5b8eb77838731c4fbc51a",
    "ner": "Zolbayar",
    "toot": "m201",
    "ovog": "Ts",
    "utas": "99536945",
    "register": "mn12345678",
    "baiguullagiinId": "68ecc6add3ec8ad389b64697",
    "baiguullagiinNer": "nihaoma",
    "erkh": "OrshinSuugch",
    "duureg": "Сүхбаатар дүүрэг",
    "horoo": "1-р хороо",
    "soh": "СӨХ-001",
    "salbaruud": [...],
    "duusakhOgnoo": "2026-10-01T09:30:11.217Z"
  },
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

All this data is automatically saved for you!

## Summary of Changes

### What Changed:
1. **Login endpoint** (`orshinSuugchNevtrey`) - No longer requires bearer token in request
2. **Automatic token storage** - Token is saved automatically after successful login
3. **User data persistence** - User information stored in SharedPreferences
4. **Helper methods** - Easy access to tokens and user data throughout the app

### Key Files:
- `lib/services/storage_service.dart` - Token and user data storage
- `lib/services/api_service.dart` - Updated login method + helper methods
- `lib/core/auth_config.dart` - Enhanced with session management

### Best Practices:
1. Always check `isLoggedIn()` before accessing protected routes
2. Use `getAuthHeaders()` for authenticated API calls
3. Call `AuthConfig.instance.initializeFromStorage()` on app startup
4. Use `logout()` to properly clear all authentication data
