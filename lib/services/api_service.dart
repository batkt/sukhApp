import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://103.143.40.46:8084';
  static const String bearerToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY4ZWNjNmFkZDNlYzhhZDM4OWI2NDY5YSIsIm5lciI6Im5paGFvbWEiLCJiYWlndXVsbGFnaWluSWQiOiI2OGVjYzZhZGQzZWM4YWQzODliNjQ2OTciLCJzYWxiYXJ1dWQiOlt7InNhbGJhcmlpbklkIjoiNjhlY2M2YWRkM2VjOGFkMzg5YjY0Njk4IiwiZHV1c2FraE9nbm9vIjoiMjAyNi0xMC0wMVQwOTozMDoxMS4yMTdaIn1dLCJkdXVzYWtoT2dub28iOiIyMDI2LTEwLTAxVDA5OjMwOjExLjIxN1oiLCJpYXQiOjE3NjA2NjQ1MzksImV4cCI6MTc2MDcwNzczOX0.sASrN_gd9S5E1fIk5hviwWN8LedLrmXWNIz-uOcYYiE';

  static Future<Map<String, dynamic>> fetchLocationData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/baiguullagaBairshilaarAvya'),
        headers: {
          'Authorization': 'Bearer $bearerToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        Set<String> districts = {};
        Set<String> khotkhons = {};

        if (data['result'] != null && data['result'] is List) {
          for (var item in data['result']) {
            if (item['duureg'] != null &&
                item['duureg'].toString().isNotEmpty) {
              districts.add(item['duureg'].toString());
            }

            if (item['districtCode'] != null &&
                item['districtCode'].toString().isNotEmpty) {
              khotkhons.add(item['districtCode'].toString());
            }
          }
        }

        return {
          'districts': districts.toList(),
          'khotkhons': khotkhons.toList(),
        };
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
    return data['districts'] as List<String>;
  }

  static Future<List<String>> fetchKhotkhons(String districtName) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/baiguullagaBairshilaarAvya'),
        headers: {
          'Authorization': 'Bearer $bearerToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        Set<String> khotkhonCodes = {};

        if (data['result'] != null && data['result'] is List) {
          for (var item in data['result']) {
            // Match the district name and extract districtCode (khotkhon)
            if (item['duureg'] == districtName &&
                item['districtCode'] != null &&
                item['districtCode'].toString().isNotEmpty) {
              khotkhonCodes.add(item['districtCode'].toString());
            }
          }
        }

        return khotkhonCodes.toList();
      } else {
        throw Exception(
          'Сервертэй холбогдох үед алдаа гарлаа: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Хотхон мэдээлэл татахад алдаа гарлаа: $e');
    }
  }

  static Future<List<String>> fetchSOKH(String khotkhonCode) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/baiguullagaBairshilaarAvya'),
        headers: {
          'Authorization': 'Bearer $bearerToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        Set<String> sokhCodes = {};

        if (data['result'] != null && data['result'] is List) {
          for (var item in data['result']) {
            // Match the khotkhon (districtCode) and extract sohCode
            if (item['districtCode'] == khotkhonCode &&
                item['sohCode'] != null &&
                item['sohCode'].toString().isNotEmpty) {
              sokhCodes.add(item['sohCode'].toString());
            }
          }
        }

        return sokhCodes.toList();
      } else {
        throw Exception(
          'Сервертэй холбогдох үед алдаа гарлаа: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('СӨХ мэдээлэл татахад алдаа гарлаа: $e');
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
          'Authorization': 'Bearer $bearerToken',
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
          'Authorization': 'Bearer $bearerToken',
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
        // Check if the response indicates success
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

  static Future<Map<String, dynamic>> registerUser(
    Map<String, dynamic> registrationData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orshinSuugchBurtgey'),
        headers: {
          'Authorization': 'Bearer $bearerToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(registrationData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Бүртгэл үүсгэхэд алдаа гарлаа: ${response.statusCode}',
        );
      }
    } catch (e) {
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
          'Authorization': 'Bearer $bearerToken',
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
        throw Exception('Нууц үг сэргээхэд алдаа гарлаа: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Нууц үг сэргээхэд алдаа гарлаа: $e');
    }
  }
}
