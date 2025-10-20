# Using Saved Token - Quick Examples

After a user logs in successfully, the token is automatically saved. Here's how to use it in your API calls:

## Method 1: Using getAuthHeaders() (Recommended)

```dart
import 'package:sukh_app/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> fetchUserProfile() async {
  // Get headers with saved token automatically included
  final headers = await ApiService.getAuthHeaders();

  final response = await http.get(
    Uri.parse('${ApiService.baseUrl}/userProfile'),
    headers: headers,
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    print('User profile: $data');
  }
}
```

## Method 2: POST Request with Token

```dart
import 'package:sukh_app/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> submitComplaint(String message) async {
  final headers = await ApiService.getAuthHeaders();

  final response = await http.post(
    Uri.parse('${ApiService.baseUrl}/submitComplaint'),
    headers: headers,
    body: json.encode({
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    }),
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    print('Complaint submitted: $data');
  }
}
```

## Method 3: Direct Token Access

```dart
import 'package:sukh_app/services/storage_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> fetchData() async {
  final token = await StorageService.getToken();

  if (token == null) {
    print('User not logged in');
    return;
  }

  final response = await http.get(
    Uri.parse('https://api.example.com/data'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    print('Data: $data');
  }
}
```

## Method 4: Adding to Existing ApiService Methods

If you want to add new API methods to ApiService that use authentication:

```dart
// In lib/services/api_service.dart

static Future<Map<String, dynamic>> getUserTransactions() async {
  try {
    final headers = await getAuthHeaders();

    final response = await http.get(
      Uri.parse('$baseUrl/userTransactions'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch transactions');
    }
  } catch (e) {
    throw Exception('Error fetching transactions: $e');
  }
}

static Future<Map<String, dynamic>> updateUserProfile({
  required String name,
  required String phone,
}) async {
  try {
    final headers = await getAuthHeaders();

    final response = await http.post(
      Uri.parse('$baseUrl/updateProfile'),
      headers: headers,
      body: json.encode({
        'name': name,
        'phone': phone,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update profile');
    }
  } catch (e) {
    throw Exception('Error updating profile: $e');
  }
}
```

## Example: Complete Feature with Authentication

Here's a complete example showing a screen that uses the saved token:

```dart
import 'package:flutter/material.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TransactionsScreen extends StatefulWidget {
  @override
  _TransactionsScreenState createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<dynamic> transactions = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Get headers with saved token
      final headers = await ApiService.getAuthHeaders();

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/transactions'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          transactions = data['transactions'] ?? [];
          isLoading = false;
        });
      } else if (response.statusCode == 401) {
        // Token expired or invalid - logout user
        await ApiService.logoutUser();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        throw Exception('Failed to load transactions');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Transactions')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Transactions')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(errorMessage!),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchTransactions,
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Transactions')),
      body: ListView.builder(
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          return ListTile(
            title: Text(transaction['description'] ?? 'N/A'),
            subtitle: Text(transaction['date'] ?? ''),
            trailing: Text('\$${transaction['amount']}'),
          );
        },
      ),
    );
  }
}
```

## Handling Token Expiration

```dart
Future<void> makeAuthenticatedRequest() async {
  try {
    final headers = await ApiService.getAuthHeaders();

    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/protected'),
      headers: headers,
    );

    if (response.statusCode == 401) {
      // Token expired or invalid
      print('Authentication failed - logging out');
      await ApiService.logoutUser();

      // Navigate to login
      // Navigator.pushReplacementNamed(context, '/login');
    } else if (response.statusCode == 200) {
      // Success
      final data = json.decode(response.body);
      print('Success: $data');
    }
  } catch (e) {
    print('Error: $e');
  }
}
```

## Quick Reference

### Get Token
```dart
final token = await StorageService.getToken();
```

### Get Auth Headers
```dart
final headers = await ApiService.getAuthHeaders();
// Returns: {'Content-Type': 'application/json', 'Authorization': 'Bearer <token>'}
```

### Check If Logged In
```dart
final isLoggedIn = await StorageService.isLoggedIn();
```

### Get User Info
```dart
final userName = await StorageService.getUserName();
final userId = await StorageService.getUserId();
final orgId = await StorageService.getBaiguullagiinId();
```

### Logout
```dart
await ApiService.logoutUser();
// or
await AuthConfig.instance.logout();
```

## Common Patterns

### Pattern 1: Check Auth Before API Call
```dart
final isLoggedIn = await StorageService.isLoggedIn();
if (!isLoggedIn) {
  // Redirect to login
  return;
}

final headers = await ApiService.getAuthHeaders();
// Make API call...
```

### Pattern 2: Try API Call, Handle 401
```dart
final response = await http.get(url, headers: await ApiService.getAuthHeaders());

if (response.statusCode == 401) {
  await ApiService.logoutUser();
  // Redirect to login
} else {
  // Handle response
}
```

### Pattern 3: Add to ApiService (Best Practice)
```dart
// In api_service.dart
static Future<List<Map<String, dynamic>>> getNotifications() async {
  final headers = await getAuthHeaders();
  final response = await http.get(
    Uri.parse('$baseUrl/notifications'),
    headers: headers,
  );

  if (response.statusCode == 200) {
    return List<Map<String, dynamic>>.from(json.decode(response.body)['data']);
  }
  throw Exception('Failed to fetch notifications');
}

// In your widget
final notifications = await ApiService.getNotifications();
```

## Summary

1. **Best Practice**: Add authenticated endpoints to `ApiService` and use `getAuthHeaders()`
2. **Token is automatically included** when you use `getAuthHeaders()`
3. **Handle 401 responses** by logging out the user and redirecting to login
4. **No manual token management needed** - it's all handled automatically after login!
