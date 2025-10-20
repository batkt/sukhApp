import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://103.143.40.46:8084';
  static const String bearerToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY4ZWNjNmFkZDNlYzhhZDM4OWI2NDY5YSIsIm5lciI6Im5paGFvbWEiLCJiYWlndXVsbGFnaWluSWQiOiI2OGVjYzZhZGQzZWM4YWQzODliNjQ2OTciLCJzYWxiYXJ1dWQiOlt7InNhbGJhcmlpbklkIjoiNjhlY2M2YWRkM2VjOGFkMzg5YjY0Njk4IiwiZHV1c2FraE9nbm9vIjoiMjAyNi0xMC0wMVQwOTozMDoxMS4yMTdaIn1dLCJkdXVzYWtoT2dub28iOiIyMDI2LTEwLTAxVDA5OjMwOjExLjIxN1oiLCJpYXQiOjE3NjA2NjQ1MzksImV4cCI6MTc2MDcwNzczOX0.sASrN_gd9S5E1fIk5hviwWN8LedLrmXWNIz-uOcYYiE';

  static List<Map<String, dynamic>>? _cachedLocationData;

  static Future<List<Map<String, dynamic>>> fetchLocationData() async {
    if (_cachedLocationData != null) {
      return _cachedLocationData!;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/baiguullagaBairshilaarAvya'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['result'] != null && data['result'] is List) {
          _cachedLocationData = List<Map<String, dynamic>>.from(data['result']);
          return _cachedLocationData!;
        }

        return [];
      } else {
        throw Exception(
          'Сервертэй холбогдох үед алдаа гарлаа: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Алдаа гарлаа: $e');
    }
  }

  static Future<List<String>> fetchDistricts() async {
    final data = await fetchLocationData();
    Set<String> districts = {};

    for (var item in data) {
      if (item['duureg'] != null && item['duureg'].toString().isNotEmpty) {
        districts.add(item['duureg'].toString());
      }
    }

    return districts.toList();
  }

  static Future<List<String>> fetchKhotkhons(String districtName) async {
    try {
      final data = await fetchLocationData();
      Set<String> khotkhonCodes = {};

      for (var item in data) {
        if (item['duureg'] == districtName &&
            item['districtCode'] != null &&
            item['districtCode'].toString().isNotEmpty) {
          khotkhonCodes.add(item['districtCode'].toString());
        }
      }

      return khotkhonCodes.toList();
    } catch (e) {
      throw Exception('Хотхон мэдээлэл татахад алдаа гарлаа: $e');
    }
  }

  static Future<List<String>> fetchSOKH(String khotkhonCode) async {
    try {
      final data = await fetchLocationData();
      Set<String> sokhCodes = {};

      for (var item in data) {
        if (item['districtCode'] == khotkhonCode &&
            item['sohCode'] != null &&
            item['sohCode'].toString().isNotEmpty) {
          sokhCodes.add(item['sohCode'].toString());
        }
      }

      return sokhCodes.toList();
    } catch (e) {
      throw Exception('СӨХ мэдээлэл татахад алдаа гарлаа: $e');
    }
  }

  // Get baiguullagiinId based on selected location (duureg, khotkhon, soh)
  static Future<String?> getBaiguullagiinId({
    String? duureg,
    String? districtCode,
    String? sohCode,
  }) async {
    try {
      final data = await fetchLocationData();

      for (var item in data) {
        bool matches = true;

        if (duureg != null && item['duureg'] != duureg) {
          matches = false;
        }

        if (districtCode != null && item['districtCode'] != districtCode) {
          matches = false;
        }

        if (sohCode != null && item['sohCode'] != sohCode) {
          matches = false;
        }

        if (matches && item['baiguullagiinId'] != null) {
          return item['baiguullagiinId'].toString();
        }
      }

      return null;
    } catch (e) {
      throw Exception('BaiguullagiinId олоход алдаа гарлаа: $e');
    }
  }

  static Future<Map<String, dynamic>> verifyPhoneNumber({
    required String baiguullagiinId,
    required String utas,
    required String duureg,
    required String horoo,
    required String soh,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/dugaarBatalgaajuulya'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'baiguullagiinId': baiguullagiinId,
          'utas': utas,
          'duureg': duureg,
          'horoo': horoo,
          'soh': soh,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Утасны дугаар баталгаажуулахад алдаа гарлаа: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Утасны дугаар баталгаажуулахад алдаа гарлаа: $e');
    }
  }

  static Future<Map<String, dynamic>> verifySecretCode({
    required String baiguullagiinId,
    required String utas,
    required String code,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/dugaarBatalgaajuulakh'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'baiguullagiinId': baiguullagiinId,
          'utas': utas,
          'code': code,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == false || data['error'] != null) {
          throw Exception(data['message'] ?? 'Баталгаажуулах код буруу байна');
        }
        return data;
      } else {
        throw Exception(
          'Баталгаажуулах код буруу байна: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Баталгаажуулах код шалгахад алдаа гарлаа: $e');
    }
  }

  // Check if register already exists using davhardsanOrshinSuugchShalgayy service
  // Returns error message if exists, null if available
  static Future<String?> checkRegisterExists({
    required String register,
    required String baiguullagiinId,
  }) async {
    try {
      // Send only register and baiguullagiinId to check
      final checkPayload = {
        'register': register,
        'baiguullagiinId': baiguullagiinId,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/davhardsanOrshinSuugchShalgayy'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(checkPayload),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // If success is false, return the message (register exists)
        if (data['success'] == false && data['message'] != null) {
          return data['message'].toString();
        }

        // If success is true, register is available
        if (data['success'] == true) {
          return null; // Available
        }
      }

      return null; // On any other status, allow continuation
    } catch (e) {
      // On error, return null to allow continuation
      return null;
    }
  }

  // Check if phone number already exists using davhardsanOrshinSuugchShalgayy service
  // Returns error message if exists, null if available
  static Future<String?> checkPhoneExists({
    required String utas,
    required String baiguullagiinId,
  }) async {
    try {
      // Send only utas and baiguullagiinId to check
      final checkPayload = {'utas': utas, 'baiguullagiinId': baiguullagiinId};

      final response = await http.post(
        Uri.parse('$baseUrl/davhardsanOrshinSuugchShalgayy'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(checkPayload),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // If success is false, return the message (phone exists)
        if (data['success'] == false && data['message'] != null) {
          return data['message'].toString();
        }

        // If success is true, phone is available
        if (data['success'] == true) {
          return null; // Available
        }
      }

      return null; // On any other status, allow continuation
    } catch (e) {
      // On error, return null to allow continuation
      return null;
    }
  }

  static Future<Map<String, dynamic>> registerUser(
    Map<String, dynamic> registrationData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orshinSuugchBurtgey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(registrationData),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 500) {
        final data = json.decode(response.body);

        if (data['success'] == false && data['aldaa'] != null) {
          throw Exception(data['aldaa']);
        }

        return data;
      } else {
        throw Exception(
          'Бүртгэл үүсгэхэд алдаа гарлаа: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Бүртгэл үүсгэхэд алдаа гарлаа: $e');
    }
  }

  static Future<Map<String, dynamic>> loginUser({
    required String utas,
    required String nuutsUg,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orshinSuugchNevtrey'),
        headers: {
          'Authorization': 'Bearer $bearerToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({'utas': utas, 'nuutsUg': nuutsUg}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Утасны дугаар эсвэл нууц үг буруу байна');
      }
    } catch (e) {
      throw Exception('Нэвтрэхэд алдаа гарлаа: $e');
    }
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String utas,
    required String code,
    required String shineNuutsUg,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/nuutsUgSergeeye'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'utas': utas,
          'code': code,
          'shineNuutsUg': shineNuutsUg,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Нууц үг сэргээхэд алдаа гарлаа: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Нууц үг сэргээхэд алдаа гарлаа: $e');
    }
  }
}
