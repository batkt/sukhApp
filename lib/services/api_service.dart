import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/services/session_service.dart';

class ApiService {
  static const String baseUrl = 'http://103.143.40.46:8084';

  static List<Map<String, dynamic>>? _cachedLocationData;

  static Future<List<Map<String, dynamic>>> fetchLocationData() async {
    if (_cachedLocationData != null) {
      return _cachedLocationData!;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/baiguullagaBairshilaarAvya'),
        headers: {'Content-Type': 'application/json'},
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
        headers: {'Content-Type': 'application/json'},
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
    required String utas,
    required String code,
    required String baiguullagiinId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/dugaarBatalgaajuulakh'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'utas': utas,
          'code': code,
          'baiguullagiinId': baiguullagiinId,
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

  // Check if phone number is registered for password reset
  static Future<Map<String, dynamic>> validatePhoneForPasswordReset({
    required String utas,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orshinSuugchBatalgaajuulya'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'utas': utas}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        return json.decode(response.body);
      } else {
        throw Exception('Алдаа гарлаа: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Алдаа гарлаа: $e');
    }
  }

  static Future<Map<String, dynamic>?> checkPhoneExists({
    required String utas,
  }) async {
    try {
      // Send only utas and baiguullagiinId to check
      final checkPayload = {'utas': utas};

      final response = await http.post(
        Uri.parse('$baseUrl/davhardsanOrshinSuugchShalgayy'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(checkPayload),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

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
        headers: {'Content-Type': 'application/json'},
        body: json.encode(registrationData),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 500) {
        final data = json.decode(response.body);

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
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'utas': utas, 'nuutsUg': nuutsUg}),
      );

      if (response.statusCode == 200) {
        final loginData = json.decode(response.body);

        if (loginData['success'] == true && loginData['token'] != null) {
          await StorageService.saveToken(loginData['token']);
          await StorageService.saveUserData(loginData);
          await SessionService.saveLoginTimestamp();
        }

        return loginData;
      } else {
        throw Exception('Утасны дугаар эсвэл нууц үг буруу байна');
      }
    } catch (e) {
      throw Exception('Нэвтрэхэд алдаа гарлаа: $e');
    }
  }

  static Future<void> logoutUser() async {
    await StorageService.clearAuthData();
  }

  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String utas,
    required String code,
    required String shineNuutsUg,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/nuutsUgSergeeye'),
        headers: {'Content-Type': 'application/json'},
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

  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final headers = await getAuthHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/tokenoorOrshinSuugchAvya'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['_id'] != null) {
          return {'success': true, 'result': data};
        } else if (data['result'] != null) {
          return {'success': true, 'result': data['result']};
        } else if (data['success'] != null) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Хэрэглэгчийн мэдээлэл олдсонгүй');
        }
      } else {
        throw Exception(
          'Хэрэглэгчийн мэдээлэл татахад алдаа гарлаа: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error in getUserProfile: $e');
      throw Exception('Хэрэглэгчийн мэдээлэл татахад алдаа гарлаа: $e');
    }
  }

  static Future<void> updateTaniltsuulgaKharakhEsekh({
    required bool taniltsuulgaKharakhEsekh,
  }) async {
    try {
      final userId = await StorageService.getUserId();
      final baiguullagiinId = await StorageService.getBaiguullagiinId();

      if (userId == null || baiguullagiinId == null) {
        throw Exception('Хэрэглэгчийн мэдээлэл олдсонгүй');
      }

      final headers = await getAuthHeaders();

      final response = await http.put(
        Uri.parse('$baseUrl/orshinSuugch/$userId'),
        headers: headers,
        body: json.encode({
          '_id': userId,
          'baiguullagiinId': baiguullagiinId,
          'taniltsuulgaKharakhEsekh': taniltsuulgaKharakhEsekh,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Танилцуулга харах тохиргоо хадгалахад алдаа гарлаа: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error updating taniltsuulgaKharakhEsekh: $e');
      throw Exception('Танилцуулга харах тохиргоо хадгалахад алдаа гарлаа: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchGeree(String orshinSuugchId) async {
    try {
      final headers = await getAuthHeaders();

      final uri = Uri.parse('$baseUrl/geree').replace(
        queryParameters: {'query': '{"orshinSuugchId":"$orshinSuugchId"}'},
      );

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Гэрээний мэдээлэл татахад алдаа гарлаа: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching geree: $e');
      throw Exception('Гэрээний мэдээлэл татахад алдаа гарлаа: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchNekhemjlekh({
    required int khuudasniiDugaar,
    required int khuudasniiKhemjee,
  }) async {
    try {
      final headers = await getAuthHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/nekhemjlekhiinTuukh'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);

          if (data is String) {
            print('API returned string instead of JSON: $data');
            return {'jagsaalt': []};
          }
          return data;
        } catch (e) {
          print('JSON parsing failed. Response body: ${response.body}');
          return {'jagsaalt': []};
        }
      } else {
        throw Exception(
          'Нэхэмжлэхийн мэдээлэл татахад алдаа гарлаа: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching nekhemjlekh: $e');
      throw Exception('Нэхэмжлэхийн мэдээлэл татахад алдаа гарлаа: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchNekhemjlekhiinTuukh({
    required String gereeniiDugaar,
    int khuudasniiDugaar = 1,
    int khuudasniiKhemjee = 10,
  }) async {
    try {
      final headers = await getAuthHeaders();

      final queryObject = json.encode({'gereeniiDugaar': gereeniiDugaar});

      final uri = Uri.parse(
        '$baseUrl/nekhemjlekhiinTuukh',
      ).replace(queryParameters: {'query': queryObject});

      print('Fetching nekhemjlekhiinTuukh with URL: $uri');

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);

          if (data is String) {
            print('API returned string instead of JSON: $data');
            return {'jagsaalt': []};
          }
          return data;
        } catch (e) {
          print('JSON parsing failed. Response body: ${response.body}');
          return {'jagsaalt': []};
        }
      } else {
        throw Exception(
          'Нэхэмжлэхийн түүх татахад алдаа гарлаа: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching nekhemjlekhiinTuukh: $e');
      throw Exception('Нэхэмжлэхийн түүх татахад алдаа гарлаа: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchBaiguullaga({
    int khuudasniiDugaar = 1,
    int khuudasniiKhemjee = 100,
  }) async {
    try {
      final headers = await getAuthHeaders();

      final uri = Uri.parse('$baseUrl/baiguullaga').replace(
        queryParameters: {
          'khuudasniiDugaar': khuudasniiDugaar.toString(),
          'khuudasniiKhemjee': khuudasniiKhemjee.toString(),
        },
      );

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Байгууллагын мэдээлэл татахад алдаа гарлаа: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching baiguullaga: $e');
      throw Exception('Байгууллагын мэдээлэл татахад алдаа гарлаа: $e');
    }
  }

  static Future<Map<String, dynamic>> qpayGargaya({
    required String baiguullagiinId,
    required String barilgiinId,
    required double dun,
    required String turul,
    required String zakhialgiinDugaar,
    required String dansniiDugaar,
    required String burtgeliinDugaar,
    required String nekhemjlekhiinId,
  }) async {
    try {
      final headers = await getAuthHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/qpayGargaya'),
        headers: headers,
        body: json.encode({
          'baiguullagiinId': baiguullagiinId,
          'barilgiinId': barilgiinId,
          'dun': dun,
          'turul': turul,
          'zakhialgiinDugaar': zakhialgiinDugaar,
          'dansniiDugaar': dansniiDugaar,
          'burtgeliinDugaar': burtgeliinDugaar,
          'nekhemjlekhiinId': nekhemjlekhiinId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'QPay төлбөр үүсгэхэд алдаа гарлаа: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error creating QPay payment: $e');
      throw Exception('QPay төлбөр үүсгэхэд алдаа гарлаа: $e');
    }
  }
}
