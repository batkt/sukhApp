import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/services/session_service.dart';

class ApiService {
  static const String baseUrl = 'http://103.50.205.80:8084';

  // Helper method to wrap HTTP calls with better error handling

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
            item['sohNer'] != null &&
            item['sohNer'].toString().isNotEmpty) {
          sokhCodes.add(item['sohNer'].toString());
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
    String? sohNer,
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

        if (sohNer != null && item['sohNer'] != sohNer) {
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
    required String purpose,
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
          'purpose': purpose,
          'utas': utas,
          'duureg': duureg,
          'horoo': horoo,
          'soh': soh,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 409) {
        throw Exception('409');
      } else {
        throw Exception(
          'Утасны дугаар баталгаажуулахад алдаа гарлаа: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> verifySecretCode({
    required String utas,
    required String code,
    required String baiguullagiinId,
    required String purpose,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/dugaarBatalgaajuulakh'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'utas': utas,
          'code': code,
          'baiguullagiinId': baiguullagiinId,
          'purpose': purpose,
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
    final response = await http.post(
      Uri.parse('$baseUrl/orshinSuugchNevtrey'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'utas': utas, 'nuutsUg': nuutsUg}),
    );

    // Try to decode the response body regardless of status code
    final loginData = json.decode(response.body);

    // Check if login was unsuccessful (check for 'aldaa' field first)
    if (loginData['success'] == false) {
      if (loginData['aldaa'] != null) {
        throw Exception(loginData['aldaa']);
      } else {
        throw Exception('Утасны дугаар эсвэл нууц үг буруу байна');
      }
    }

    if (response.statusCode == 200 || response.statusCode == 500) {
      if (loginData['success'] == true && loginData['token'] != null) {
        await StorageService.saveToken(loginData['token']);
        await StorageService.saveUserData(loginData);
        await SessionService.saveLoginTimestamp();
      }

      return loginData;
    } else {
      throw Exception('Утасны дугаар эсвэл нууц үг буруу байна');
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

      final queryJson = json.encode({'gereeniiDugaar': gereeniiDugaar});
      final uri = Uri.parse(
        '$baseUrl/nekhemjlekhiinTuukh',
      ).replace(queryParameters: {'query': queryJson});

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

  static Future<Map<String, dynamic>> fetchEbarimtJagsaaltAvya({
    required String nekhemjlekhiinId,
    int khuudasniiDugaar = 1,
    int khuudasniiKhemjee = 10,
  }) async {
    try {
      final headers = await getAuthHeaders();

      final queryJson = json.encode({'nekhemjlekhiinId': nekhemjlekhiinId});
      final uri = Uri.parse('$baseUrl/ebarimtJagsaaltAvya').replace(
        queryParameters: {
          'query': queryJson,
          'khuudasniiDugaar': khuudasniiDugaar.toString(),
          'khuudasniiKhemjee': khuudasniiKhemjee.toString(),
        },
      );

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
        throw Exception('Баримт татахад алдаа гарлаа: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching ebarimtJagsaaltAvya: $e');
      throw Exception('Баримт татахад алдаа гарлаа: $e');
    }
  }

  static Future<Map<String, dynamic>> checkPaymentStatus({
    required String invoiceId,
  }) async {
    try {
      final headers = await getAuthHeaders();

      final uri = Uri.parse(
        '$baseUrl/qpayTuluviinShalgakh',
      ).replace(queryParameters: {'invoiceId': invoiceId});

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Төлбөрийн төлөв шалгахад алдаа гарлаа: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error checking payment status: $e');
      throw Exception('Төлбөрийн төлөв шалгахад алдаа гарлаа: $e');
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

    required List<String> nekhemjlekhiinTuukh,
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

          'nekhemjlekhiinTuukh': nekhemjlekhiinTuukh,
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

  static Future<Map<String, dynamic>> updateNekhemjlekhiinTuluv({
    required List<String> nekhemjlekhiinIds,
    required String tuluv,
  }) async {
    try {
      final headers = await getAuthHeaders();

      final response = await http.put(
        Uri.parse('$baseUrl/nekhemjlekhiinTuukhTuluviinSolikh'),
        headers: headers,
        body: json.encode({
          'nekhemjlekhiinIds': nekhemjlekhiinIds,
          'tuluv': tuluv,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Нэхэмжлэхийн төлөв шинэчлэхэд алдаа гарлаа: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error updating nekhemjlekh status: $e');
      throw Exception('Нэхэмжлэхийн төлөв шинэчлэхэд алдаа гарлаа: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchNekhemjlekhCron({
    required String baiguullagiinId,
  }) async {
    try {
      final headers = await getAuthHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/nekhemjlekhCron/$baiguullagiinId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Нэхэмжлэхийн Cron мэдээлэл татахад алдаа гарлаа: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching nekhemjlekh cron: $e');
      throw Exception('Нэхэмжлэхийн Cron мэдээлэл татахад алдаа гарлаа: $e');
    }
  }

  static Future<Map<String, dynamic>> changePassword({
    required String odoogiinNuutsUg,
    required String shineNuutsUg,
    required String davtahNuutsUg,
  }) async {
    try {
      final headers = await getAuthHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/orshinSuugchNuutsUgSoliyo'),
        headers: headers,
        body: json.encode({
          'odoogiinNuutsUg': odoogiinNuutsUg,
          'shineNuutsUg': shineNuutsUg,
          'davtahNuutsUg': davtahNuutsUg,
        }),
      );

      final data = json.decode(response.body);

      // Return the response data regardless of status code
      // The UI will check the 'success' field
      return data;
    } catch (e) {
      print('Error changing password: $e');
      throw Exception('Нууц үг солиход алдаа гарлаа: $e');
    }
  }

  static Future<Map<String, dynamic>> deleteUser({
    required String nuutsUg,
  }) async {
    try {
      final headers = await getAuthHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/orshinSuugch/oorooUstgakh'),
        headers: headers,
        body: json.encode({'nuutsUg': nuutsUg}),
      );

      final data = json.decode(response.body);
      return data;
    } catch (e) {
      print('Error deleting user: $e');
      throw Exception('Бүртгэлтэй хаяг устгахад алдаа гарлаа: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchBuildingDetails({
    required String baiguullagiinId,
  }) async {
    try {
      final data = await fetchLocationData();

      final matchingBaiguullaga = data.firstWhere(
        (item) => item['baiguullagiinId'] == baiguullagiinId,
        orElse: () => {},
      );

      if (matchingBaiguullaga.isEmpty ||
          matchingBaiguullaga['barilguud'] == null) {
        return {'barilguud': <Map<String, dynamic>>[]};
      }

      return {'barilguud': matchingBaiguullaga['barilguud'] as List};
    } catch (e) {
      print('Error fetching building details: $e');
      throw Exception('Барилгын мэдээлэл татахад алдаа гарлаа: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchAjiltan({
    int khuudasniiDugaar = 1,
    int khuudasniiKhemjee = 500,
  }) async {
    try {
      final headers = await getAuthHeaders();
      final baiguullagiinId = await StorageService.getBaiguullagiinId();
      final barilgiinId = await StorageService.getBarilgiinId();

      if (baiguullagiinId == null || barilgiinId == null) {
        throw Exception('Байгууллага эсвэл барилгын мэдээлэл олдсонгүй');
      }

      final uri = Uri.parse(
        '$baseUrl/ajiltan',
      ).replace(queryParameters: {'baiguullagiinId': baiguullagiinId});

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Filter jagsaalt by baiguullagiinId on client side
        if (data['jagsaalt'] != null && data['jagsaalt'] is List) {
          final filteredList = (data['jagsaalt'] as List).where((ajiltan) {
            return ajiltan['baiguullagiinId'] == baiguullagiinId;
          }).toList();

          data['jagsaalt'] = filteredList;
          data['niitMur'] = filteredList.length;
          data['niitKhuudas'] = (filteredList.length / khuudasniiKhemjee)
              .ceil();
        }

        return data;
      } else {
        throw Exception(
          'Ажилтны мэдээлэл татахад алдаа гарлаа: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching ajiltan: $e');
      throw Exception('Ажилтны мэдээлэл татахад алдаа гарлаа: $e');
    }
  }

  // ============================================
  // MEDEGDEL (Notifications) API Methods
  // ============================================

  static Future<Map<String, dynamic>> fetchMedegdel({
    String? barilgiinId,
  }) async {
    try {
      final baiguullagiinId = await StorageService.getBaiguullagiinId();
      var tukhainBaaziinKholbolt =
          await StorageService.getTukhainBaaziinKholbolt();

      if (tukhainBaaziinKholbolt == 'amarSukh' ||
          tukhainBaaziinKholbolt == null) {
        try {
          final userProfile = await getUserProfile();
          if (userProfile['result']?['tukhainBaaziinKholbolt'] != null) {
            tukhainBaaziinKholbolt =
                userProfile['result']['tukhainBaaziinKholbolt'].toString();
            // Save it for future use
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
              'tukhain_baaziin_kholbolt',
              tukhainBaaziinKholbolt,
            );
          }
        } catch (e) {
          print('Could not fetch tukhainBaaziinKholbolt from user profile: $e');
        }
      }

      if (baiguullagiinId == null ||
          tukhainBaaziinKholbolt == null ||
          tukhainBaaziinKholbolt.isEmpty) {
        throw Exception('Холболтын мэдээлэл олдсонгүй. Та дахин нэвтэрнэ үү.');
      }

      final headers = await getAuthHeaders();

      // Get current user ID for filtering notifications
      final userId = await StorageService.getUserId();

      // Build query parameters
      // Note: Some APIs might not support turul filter, so we'll filter client-side
      final queryParams = <String, String>{
        'baiguullagiinId': baiguullagiinId,
        'tukhainBaaziinKholbolt': tukhainBaaziinKholbolt,
        // Try without turul first - filter client-side instead
        // 'turul': 'мэдэгдэл',
      };

      if (barilgiinId != null && barilgiinId.isNotEmpty) {
        queryParams['barilgiinId'] = barilgiinId;
      }

      // Add user ID filter to get only notifications for current user
      if (userId != null && userId.isNotEmpty) {
        queryParams['orshinSuugchId'] = userId;
      }

      // Ensure we're using the correct endpoint - construct URI explicitly
      final endpoint = '/medegdel';
      final uri = Uri.parse(
        '$baseUrl$endpoint',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Filter to only include notifications where turul = "app"
        // Also filter by userId as a fallback in case API doesn't filter properly
        // (filtering client-side in case API doesn't support turul parameter)
        if (data['data'] != null && data['data'] is List) {
          final filteredData = (data['data'] as List).where((item) {
            final turul = item['turul']?.toString().toLowerCase() ?? '';
            // Accept "app" type and "khariu" (reply) notifications
            final matchesTurul =
                turul == 'app' ||
                turul == 'khariu' ||
                turul == 'хариу' ||
                turul == 'hariu';

            // Also filter by userId as fallback (in case API doesn't filter properly)
            if (userId != null && userId.isNotEmpty) {
              final itemUserId = item['orshinSuugchId']?.toString() ?? '';
              return matchesTurul && itemUserId == userId;
            }

            return matchesTurul;
          }).toList();

          data['data'] = filteredData;
          if (data['count'] != null) {
            data['count'] = filteredData.length;
          }
        }
        return data;
      } else if (response.statusCode == 400) {
        // Handle 400 error - might be a backend validation issue
        // Return empty data instead of throwing error
        return {'success': true, 'data': <dynamic>[], 'count': 0};
      } else {
        // Try to get error message from response body
        String errorMessage =
            'Мэдэгдэл татахад алдаа гарлаа: ${response.statusCode}';
        try {
          final errorBody = json.decode(response.body);
          if (errorBody['message'] != null) {
            errorMessage = errorBody['message'].toString();
          } else if (errorBody['aldaa'] != null) {
            errorMessage = errorBody['aldaa'].toString();
          }
        } catch (_) {
          // If parsing fails, use default message
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Мэдэгдэл татахад алдаа гарлаа: $e');
    }
  }

  /// Get user's complaints and suggestions (Гомдол, Санал) for tracking progress
  static Future<Map<String, dynamic>> fetchUserGomdolSanal({
    String? barilgiinId,
  }) async {
    try {
      final baiguullagiinId = await StorageService.getBaiguullagiinId();
      final tukhainBaaziinKholbolt =
          await StorageService.getTukhainBaaziinKholbolt();
      final userId = await StorageService.getUserId();

      if (baiguullagiinId == null ||
          tukhainBaaziinKholbolt == null ||
          userId == null) {
        throw Exception('Хэрэглэгчийн мэдээлэл олдсонгүй');
      }

      final headers = await getAuthHeaders();

      final queryParams = <String, String>{
        'baiguullagiinId': baiguullagiinId,
        'tukhainBaaziinKholbolt': tukhainBaaziinKholbolt,
        'orshinSuugchId': userId,
      };

      if (barilgiinId != null) {
        queryParams['barilgiinId'] = barilgiinId;
      }

      // Ensure we're using the correct endpoint - construct URI explicitly
      final endpoint = '/medegdel';
      final uri = Uri.parse(
        '$baseUrl$endpoint',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['data'] != null) {
          if (data['data'] is Map) {
            // Handle single object response
            final item = data['data'] as Map;
            // Convert single object to array for consistency
            data['data'] = [item];
          }
        } else {
          data['data'] = [];
        }

        // Filter to only include "gomdol" and "sanal"
        if (data['data'] != null && data['data'] is List) {
          final filteredData = (data['data'] as List).where((item) {
            final turul = item['turul']?.toString().toLowerCase() ?? '';
            final matches = turul == 'gomdol' || turul == 'sanal';
            return matches;
          }).toList();
          data['data'] = filteredData;
          data['count'] = filteredData.length;
        }
        return data;
      } else {
        // Try to get error message from response body
        String errorMessage =
            'Гомдол, санал татахад алдаа гарлаа: ${response.statusCode}';
        try {
          final errorBody = json.decode(response.body);
          if (errorBody['message'] != null) {
            errorMessage = errorBody['message'].toString();
          } else if (errorBody['aldaa'] != null) {
            errorMessage = errorBody['aldaa'].toString();
          }
        } catch (_) {
          // If parsing fails, use default message
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Гомдол, санал татахад алдаа гарлаа: $e');
    }
  }

  /// Submit complaint or suggestion (Гомдол or Санал)
  static Future<Map<String, dynamic>> submitGomdolSanal({
    required String title,
    required String message,
    required String turul, // "gomdol" or "sanal"
  }) async {
    final turulLower = turul.toLowerCase();
    try {
      final baiguullagiinId = await StorageService.getBaiguullagiinId();
      final barilgiinId = await StorageService.getBarilgiinId();
      final tukhainBaaziinKholbolt =
          await StorageService.getTukhainBaaziinKholbolt();
      final userId = await StorageService.getUserId();

      if (baiguullagiinId == null ||
          tukhainBaaziinKholbolt == null ||
          userId == null) {
        throw Exception('Хэрэглэгчийн мэдээлэл олдсонгүй');
      }

      if (turulLower != 'gomdol' && turulLower != 'sanal') {
        throw Exception(
          'Буруу төрөл. Зөвхөн "gomdol" эсвэл "sanal" байх ёстой',
        );
      }

      final headers = await getAuthHeaders();

      final requestBody = {
        'medeelel': {'title': title, 'body': message},
        'orshinSuugchId': userId,
        'baiguullagiinId': baiguullagiinId,
        'tukhainBaaziinKholbolt': tukhainBaaziinKholbolt,
        'turul': turulLower, // Use lowercase version
      };

      if (barilgiinId != null && barilgiinId.isNotEmpty) {
        requestBody['barilgiinId'] = barilgiinId;
      }

      // Debug logging
      print('=== Submitting ${turul} ===');
      print('Endpoint: /medegdelIlgeeye');
      print('Request body: ${json.encode(requestBody)}');
      print('tukhainBaaziinKholbolt: $tukhainBaaziinKholbolt');

      // Use /medegdelIlgeeye endpoint - this is the correct endpoint for creating notifications
      // Note: This endpoint requires Firebase token, but we'll handle that error gracefully
      final response = await http.post(
        Uri.parse('$baseUrl/medegdelIlgeeye'),
        headers: headers,
        body: json.encode(requestBody),
      );

      // Debug response
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // The API returns "done" as a string, so we return a success response
        final responseBody = response.body.trim();
        if (responseBody.toLowerCase() == 'done' ||
            responseBody.contains('success') ||
            responseBody.isEmpty) {
          return {
            'success': true,
            'message': turulLower == 'gomdol'
                ? 'Гомдол амжилттай илгээгдлээ'
                : 'Санал амжилттай илгээгдлээ',
          };
        }
        // If response is JSON, try to parse it
        try {
          final data = json.decode(responseBody);
          if (data['success'] == true || data['message'] != null) {
            return {
              'success': true,
              'message': turulLower == 'gomdol'
                  ? 'Гомдол амжилттай илгээгдлээ'
                  : 'Санал амжилттай илгээгдлээ',
            };
          }
        } catch (_) {
          // If not JSON, assume success if status is 200
        }
        // Default success response
        return {
          'success': true,
          'message': turulLower == 'gomdol'
              ? 'Гомдол амжилттай илгээгдлээ'
              : 'Санал амжилттай илгээгдлээ',
        };
      } else {
        // Try to get error message from response body
        String errorMessage =
            '${turulLower == 'gomdol' ? 'Гомдол' : 'Санал'} илгээхэд алдаа гарлаа: ${response.statusCode}';
        try {
          // Check if response is HTML (404 error page)
          if (response.body.contains('<!DOCTYPE html>') ||
              response.body.contains('Cannot POST') ||
              response.body.contains('Cannot GET')) {
            errorMessage = 'Серверийн алдаа гарлаа. Дахин оролдоно уу.';
          } else {
            final errorBody = json.decode(response.body);
            if (errorBody['message'] != null) {
              errorMessage = errorBody['message'].toString();
            } else if (errorBody['aldaa'] != null) {
              errorMessage = errorBody['aldaa'].toString();
            } else if (errorBody['error'] != null) {
              errorMessage = errorBody['error'].toString();
            }

            // Handle Firebase token error with a user-friendly message
            if (errorMessage.contains('Firebase token') ||
                errorMessage.contains('firebaseToken')) {
              errorMessage =
                  'Мэдэгдэл илгээхэд алдаа гарлаа. Системийн тохиргоо шаардлагатай.';
            }
          }
        } catch (_) {
          // If response is not JSON, use the raw body if it's not empty
          if (response.body.trim().isNotEmpty &&
              !response.body.contains('<!DOCTYPE html>')) {
            errorMessage = response.body.trim();
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception(
        '${turulLower == 'gomdol' ? 'Гомдол' : 'Санал'} илгээхэд алдаа гарлаа: $e',
      );
    }
  }

  /// Mark notification as read
  static Future<Map<String, dynamic>> markMedegdelAsRead(
    String medegdelId,
  ) async {
    try {
      final baiguullagiinId = await StorageService.getBaiguullagiinId();
      final tukhainBaaziinKholbolt =
          await StorageService.getTukhainBaaziinKholbolt();

      if (baiguullagiinId == null || tukhainBaaziinKholbolt == null) {
        throw Exception('Хэрэглэгчийн мэдээлэл олдсонгүй');
      }

      final headers = await getAuthHeaders();

      // Ensure Content-Type header is set
      final requestHeaders = Map<String, String>.from(headers);
      requestHeaders['Content-Type'] = 'application/json';

      final requestBody = {
        'baiguullagiinId': baiguullagiinId,
        'tukhainBaaziinKholbolt': tukhainBaaziinKholbolt,
        'kharsanEsekh': true,
      };

      final url = '$baseUrl/medegdel/$medegdelId';

      final response = await http.put(
        Uri.parse(url),
        headers: requestHeaders,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);
          // Verify the response indicates success
          if (responseData['success'] == true ||
              (responseData['data'] != null &&
                  responseData['data']['kharsanEsekh'] == true)) {
            return responseData;
          }
          // If response doesn't have success flag, assume it worked if status is 200
          return {'success': true, 'data': responseData};
        } catch (e) {
          // If response is not JSON, assume success if status is 200
          return {'success': true};
        }
      } else {
        String errorMessage =
            'Мэдэгдэл тэмдэглэхэд алдаа гарлаа: ${response.statusCode}';
        try {
          final errorBody = json.decode(response.body);
          if (errorBody['message'] != null) {
            errorMessage = errorBody['message'].toString();
          } else if (errorBody['aldaa'] != null) {
            errorMessage = errorBody['aldaa'].toString();
          }
        } catch (_) {
          // Use default error message
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Мэдэгдэл тэмдэглэхэд алдаа гарлаа: $e');
    }
  }
}
