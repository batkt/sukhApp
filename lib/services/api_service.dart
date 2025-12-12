import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/services/session_service.dart';

class ApiService {
  static const String baseUrl = 'http://103.50.205.80:8084';
  static const String walletApiBaseUrl = 'https://dev-api.bpay.mn/v1';

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

  static Future<List<Map<String, dynamic>>> getWalletCities() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/walletAddress/city'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return [];
      } else {
        throw Exception('Хот авахад алдаа гарлаа: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Хот авахад алдаа гарлаа: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getWalletDistricts(
    String cityId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/walletAddress/district/$cityId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return [];
      } else {
        throw Exception('Дүүрэг авахад алдаа гарлаа: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Дүүрэг авахад алдаа гарлаа: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getWalletKhoroos(
    String districtId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/walletAddress/khoroo/$districtId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return [];
      } else {
        throw Exception('Хороо авахад алдаа гарлаа: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Хороо авахад алдаа гарлаа: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getWalletBuildings(
    String khorooId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/walletAddress/bair/$khorooId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return [];
      } else {
        throw Exception('Барилга авахад алдаа гарлаа: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Барилга авахад алдаа гарлаа: $e');
    }
  }

  // ==================== Wallet API Services ====================

  // Biller Services
  static Future<List<Map<String, dynamic>>> getWalletBillers() async {
    try {
      final headers = await getWalletApiHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/wallet/billers'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          if (data['data'] is List) {
            return List<Map<String, dynamic>>.from(data['data']);
          }
        }
        return [];
      } else if (response.statusCode == 401) {
        throw Exception('Нэвтрэх шаардлагатай');
      } else if (response.statusCode == 404) {
        print(
          '❌ [GET-WALLET-BILLERS] 404 Error - URL: $baseUrl/wallet/billers',
        );
        print('❌ [GET-WALLET-BILLERS] Response body: ${response.body}');
        try {
          final errorData = json.decode(response.body);
          final errorMessage =
              errorData['message'] ??
              'Биллерүүд авах endpoint олдсонгүй (404). URL: $baseUrl/wallet/billers';
          throw Exception(errorMessage);
        } catch (_) {
          throw Exception(
            'Биллерүүд авах endpoint олдсонгүй (404). URL: $baseUrl/wallet/billers',
          );
        }
      } else {
        final errorData = json.decode(response.body);
        final errorMessage =
            errorData['message'] ??
            'Биллерүүд авахад алдаа гарлаа: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e.toString().contains('404')) {
        rethrow;
      }
      throw Exception('Биллерүүд авахад алдаа гарлаа: $e');
    }
  }

  // Billing Services
  static Future<Map<String, dynamic>> findBillingByBillerAndCustomerCode({
    required String billerCode,
    required String customerCode,
  }) async {
    http.Response? response;
    try {
      final headers = await getWalletApiHeaders();
      final url = '$baseUrl/wallet/billing/biller/$billerCode/$customerCode';

      print('🔍 [FIND-BILLING] Starting request...');
      print('🔍 [FIND-BILLING] URL: $url');
      print('🔍 [FIND-BILLING] BillerCode: $billerCode');
      print('🔍 [FIND-BILLING] CustomerCode: $customerCode');
      print(
        '🔍 [FIND-BILLING] Has Auth Header: ${headers.containsKey('Authorization')}',
      );

      response = await http.get(Uri.parse(url), headers: headers);

      print('🔍 [FIND-BILLING] Response status: ${response.statusCode}');
      print('🔍 [FIND-BILLING] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        print('🔍 [FIND-BILLING] Decoded type: ${decoded.runtimeType}');
        print('🔍 [FIND-BILLING] Decoded value: $decoded');

        // Handle both Map and List responses
        Map<String, dynamic> data;
        if (decoded is Map<String, dynamic>) {
          print('🔍 [FIND-BILLING] Response is Map');
          data = decoded;
        } else if (decoded is List) {
          print(
            '🔍 [FIND-BILLING] Response is List, length: ${decoded.length}',
          );
          if (decoded.isEmpty) {
            print('❌ [FIND-BILLING] List is empty');
            throw Exception('Биллингийн мэдээлэл олдсонгүй');
          }
          // If response is a list, wrap it in a map structure
          final firstItem = decoded[0];
          print('🔍 [FIND-BILLING] First item type: ${firstItem.runtimeType}');
          print('🔍 [FIND-BILLING] First item value: $firstItem');
          if (firstItem is Map<String, dynamic>) {
            data = {'success': true, 'data': firstItem};
            print('✅ [FIND-BILLING] Wrapped list item into Map structure');
          } else {
            print('❌ [FIND-BILLING] First item is not Map<String, dynamic>');
            throw Exception('Биллингийн мэдээлэл буруу форматтай байна');
          }
        } else {
          print(
            '❌ [FIND-BILLING] Response is neither Map nor List: ${decoded.runtimeType}',
          );
          throw Exception('Биллингийн мэдээлэл олдсонгүй');
        }

        print('🔍 [FIND-BILLING] Final data structure: $data');
        if (data['success'] == true) {
          // Check if data field is a List and extract first item
          if (data['data'] is List) {
            final dataList = data['data'] as List;
            print(
              '🔍 [FIND-BILLING] data field is List, length: ${dataList.length}',
            );
            if (dataList.isNotEmpty) {
              print('🔍 [FIND-BILLING] Extracting first item from List');
              final firstItem = dataList[0];
              print(
                '🔍 [FIND-BILLING] First item type: ${firstItem.runtimeType}',
              );
              print('🔍 [FIND-BILLING] First item: $firstItem');
              if (firstItem is Map<String, dynamic>) {
                data['data'] = Map<String, dynamic>.from(firstItem);
                print('✅ [FIND-BILLING] Converted List to single Map object');
              } else {
                print(
                  '❌ [FIND-BILLING] First item is not Map<String, dynamic>',
                );
                throw Exception('Биллингийн мэдээлэл буруу форматтай байна');
              }
            } else {
              print('❌ [FIND-BILLING] data List is empty');
              throw Exception('Биллингийн мэдээлэл олдсонгүй');
            }
          } else {
            print('🔍 [FIND-BILLING] data field is already a single object');
          }
          print('✅ [FIND-BILLING] Success! Returning data: $data');
          return data;
        } else {
          print('❌ [FIND-BILLING] Success flag is false: ${data['message']}');
          throw Exception(data['message'] ?? 'Биллингийн мэдээлэл олдсонгүй');
        }
      } else if (response.statusCode == 404) {
        print('❌ [FIND-BILLING] 404 - Not found');
        throw Exception('Биллингийн мэдээлэл олдсонгүй');
      } else if (response.statusCode == 401) {
        print('❌ [FIND-BILLING] 401 - Unauthorized');
        throw Exception('Нэвтрэх шаардлагатай');
      } else {
        print('❌ [FIND-BILLING] Error status: ${response.statusCode}');
        throw Exception('Биллинг авахад алдаа гарлаа: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [FIND-BILLING] Exception caught: $e');
      print('❌ [FIND-BILLING] Exception type: ${e.runtimeType}');
      if (response != null) {
        print('❌ [FIND-BILLING] Response status: ${response.statusCode}');
        print('❌ [FIND-BILLING] Response body: ${response.body}');
      }
      if (e.toString().contains('is not a subtype') ||
          e.toString().contains('List<dynamic>') ||
          e.toString().contains('Map<String, dynamic>')) {
        print('❌ [FIND-BILLING] Type casting error detected');
        throw Exception('Биллингийн мэдээлэл буруу форматтай байна');
      }
      throw Exception('Биллинг авахад алдаа гарлаа: $e');
    }
  }

  static Future<Map<String, dynamic>> findBillingByCustomerId({
    required String customerId,
  }) async {
    try {
      final headers = await getWalletApiHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/wallet/billing/customer/$customerId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Биллингийн мэдээлэл олдсонгүй');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Биллингийн мэдээлэл олдсонгүй');
      } else if (response.statusCode == 401) {
        throw Exception('Нэвтрэх шаардлагатай');
      } else {
        throw Exception('Биллинг авахад алдаа гарлаа: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Биллинг авахад алдаа гарлаа: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getWalletBillingList() async {
    try {
      final headers = await getWalletApiHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/wallet/billing/list'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          if (data['data'] is List) {
            return List<Map<String, dynamic>>.from(data['data']);
          }
        }
        return [];
      } else if (response.statusCode == 401) {
        throw Exception('Нэвтрэх шаардлагатай');
      } else {
        throw Exception(
          'Биллингийн жагсаалт авахад алдаа гарлаа: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Биллингийн жагсаалт авахад алдаа гарлаа: $e');
    }
  }

  static Future<Map<String, dynamic>> getWalletBillingBills({
    required String billingId,
  }) async {
    try {
      final headers = await getWalletApiHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/wallet/billing/bills/$billingId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📄 [API] Billing bills response: $data');

        if (data['responseCode'] == true && data['data'] != null) {
          // Return the full data object which includes billingId, billingName, newBills, etc.
          final result = Map<String, dynamic>.from(data['data']);
          print('📄 [API] Extracted data object: $result');
          if (result['newBills'] != null) {
            print(
              '📄 [API] newBills found: ${result['newBills']} (type: ${result['newBills'].runtimeType})',
            );
            if (result['newBills'] is List) {
              print(
                '📄 [API] newBills is List with ${(result['newBills'] as List).length} items',
              );
            }
          } else {
            print('📄 [API] newBills is null or missing');
          }
          return result;
        } else if (data['success'] == true && data['data'] != null) {
          // Fallback for different response format
          if (data['data'] is Map) {
            return Map<String, dynamic>.from(data['data']);
          } else if (data['data'] is List) {
            // If it's a list, wrap it in a map with newBills key
            return {'newBills': List<Map<String, dynamic>>.from(data['data'])};
          }
        }
        print('📄 [API] No valid data found, returning empty map');
        return {};
      } else if (response.statusCode == 401) {
        throw Exception('Нэвтрэх шаардлагатай');
      } else {
        throw Exception('Биллүүд авахад алдаа гарлаа: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Биллүүд авахад алдаа гарлаа: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getWalletBillingPayments({
    required String billingId,
  }) async {
    try {
      final headers = await getWalletApiHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/wallet/billing/payments/$billingId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          if (data['data'] is List) {
            return List<Map<String, dynamic>>.from(data['data']);
          }
        }
        return [];
      } else if (response.statusCode == 401) {
        throw Exception('Нэвтрэх шаардлагатай');
      } else {
        throw Exception(
          'Төлбөрийн түүх авахад алдаа гарлаа: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Төлбөрийн түүх авахад алдаа гарлаа: $e');
    }
  }

  static Future<Map<String, dynamic>> findBillingByAddress({
    required String bairId,
    required String doorNo,
  }) async {
    try {
      final headers = await getWalletApiHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/wallet/billing/address/$bairId/$doorNo'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Биллингийн мэдээлэл олдсонгүй');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Биллингийн мэдээлэл олдсонгүй');
      } else if (response.statusCode == 401) {
        throw Exception('Нэвтрэх шаардлагатай');
      } else {
        throw Exception('Биллинг авахад алдаа гарлаа: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Биллинг авахад алдаа гарлаа: $e');
    }
  }

  static Future<Map<String, dynamic>> saveWalletBilling({
    required String billingId,
    String? billingName,
    String? customerId,
    String? customerCode,
  }) async {
    try {
      final headers = await getWalletApiHeaders();
      final requestBody = <String, dynamic>{'billingId': billingId};

      if (billingName != null && billingName.isNotEmpty) {
        requestBody['billingName'] = billingName;
      }
      if (customerId != null && customerId.isNotEmpty) {
        requestBody['customerId'] = customerId;
      }
      if (customerCode != null && customerCode.isNotEmpty) {
        requestBody['customerCode'] = customerCode;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/wallet/billing'),
        headers: headers,
        body: json.encode(requestBody),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Биллинг хадгалахад алдаа гарлаа');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Нэвтрэх шаардлагатай');
      } else {
        throw Exception(
          data['message'] ??
              'Биллинг хадгалахад алдаа гарлаа: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Биллинг хадгалахад алдаа гарлаа: $e');
    }
  }

  static Future<Map<String, dynamic>> removeWalletBilling({
    required String billingId,
  }) async {
    try {
      final headers = await getWalletApiHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/wallet/billing/$billingId'),
        headers: headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Биллинг устгахад алдаа гарлаа');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Нэвтрэх шаардлагатай');
      } else {
        throw Exception(
          data['message'] ??
              'Биллинг устгахад алдаа гарлаа: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Биллинг устгахад алдаа гарлаа: $e');
    }
  }

  static Future<Map<String, dynamic>> removeWalletBill({
    required String billingId,
    required String billId,
  }) async {
    try {
      final headers = await getWalletApiHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/wallet/billing/$billingId/bill/$billId'),
        headers: headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Билл устгахад алдаа гарлаа');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Нэвтрэх шаардлагатай');
      } else {
        throw Exception(
          data['message'] ??
              'Билл устгахад алдаа гарлаа: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Билл устгахад алдаа гарлаа: $e');
    }
  }

  static Future<Map<String, dynamic>> recoverWalletBill({
    required String billingId,
  }) async {
    try {
      final headers = await getWalletApiHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/wallet/billing/$billingId/recover'),
        headers: headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Билл сэргээхэд алдаа гарлаа');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Нэвтрэх шаардлагатай');
      } else {
        throw Exception(
          data['message'] ??
              'Билл сэргээхэд алдаа гарлаа: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Билл сэргээхэд алдаа гарлаа: $e');
    }
  }

  static Future<Map<String, dynamic>> changeWalletBillingName({
    required String billingId,
    required String name,
  }) async {
    try {
      final headers = await getWalletApiHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/wallet/billing/$billingId/name'),
        headers: headers,
        body: json.encode({'name': name}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(
            data['message'] ?? 'Биллингийн нэр өөрчлөхөд алдаа гарлаа',
          );
        }
      } else if (response.statusCode == 401) {
        throw Exception('Нэвтрэх шаардлагатай');
      } else {
        throw Exception(
          data['message'] ??
              'Биллингийн нэр өөрчлөхөд алдаа гарлаа: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Биллингийн нэр өөрчлөхөд алдаа гарлаа: $e');
    }
  }

  // Invoice Services
  static Future<Map<String, dynamic>> createWalletInvoice({
    required String billingId,
    required List<String> billIds,
    required String vatReceiveType,
    String? vatCompanyReg,
  }) async {
    try {
      final headers = await getWalletApiHeaders();
      final requestBody = <String, dynamic>{
        'billingId': billingId,
        'billIds': billIds,
        'vatReceiveType': vatReceiveType,
      };

      if (vatCompanyReg != null && vatCompanyReg.isNotEmpty) {
        requestBody['vatCompanyReg'] = vatCompanyReg;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/wallet/invoice'),
        headers: headers,
        body: json.encode(requestBody),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Нэхэмжлэх үүсгэхэд алдаа гарлаа');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Нэвтрэх шаардлагатай');
      } else {
        throw Exception(
          data['message'] ??
              'Нэхэмжлэх үүсгэхэд алдаа гарлаа: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Нэхэмжлэх үүсгэхэд алдаа гарлаа: $e');
    }
  }

  static Future<Map<String, dynamic>> getWalletInvoice({
    required String invoiceId,
  }) async {
    try {
      final headers = await getWalletApiHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/wallet/invoice/$invoiceId'),
        headers: headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Нэхэмжлэх олдсонгүй');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Нэхэмжлэх олдсонгүй');
      } else if (response.statusCode == 401) {
        throw Exception('Нэвтрэх шаардлагатай');
      } else {
        throw Exception(
          data['message'] ??
              'Нэхэмжлэх авахад алдаа гарлаа: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Нэхэмжлэх авахад алдаа гарлаа: $e');
    }
  }

  static Future<Map<String, dynamic>> cancelWalletInvoice({
    required String invoiceId,
  }) async {
    try {
      final headers = await getWalletApiHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/wallet/invoice/$invoiceId/cancel'),
        headers: headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Нэхэмжлэх цуцлахад алдаа гарлаа');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Нэвтрэх шаардлагатай');
      } else {
        throw Exception(
          data['message'] ??
              'Нэхэмжлэх цуцлахад алдаа гарлаа: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Нэхэмжлэх цуцлахад алдаа гарлаа: $e');
    }
  }

  // Payment Services
  static Future<Map<String, dynamic>> createWalletPayment({
    required String invoiceId,
  }) async {
    try {
      final headers = await getWalletApiHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/wallet/payment'),
        headers: headers,
        body: json.encode({'invoiceId': invoiceId}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Төлбөр үүсгэхэд алдаа гарлаа');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Нэвтрэх шаардлагатай');
      } else {
        throw Exception(
          data['message'] ??
              'Төлбөр үүсгэхэд алдаа гарлаа: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Төлбөр үүсгэхэд алдаа гарлаа: $e');
    }
  }

  // User Services
  static Future<Map<String, dynamic>> updateWalletUser({
    String? email,
    String? phone,
  }) async {
    try {
      final headers = await getWalletApiHeaders();
      final requestBody = <String, dynamic>{};

      if (email != null && email.isNotEmpty) {
        requestBody['email'] = email;
      }
      if (phone != null && phone.isNotEmpty) {
        requestBody['phone'] = phone;
      }

      if (requestBody.isEmpty) {
        throw Exception('Хамгийн багадаа нэг талбар бөглөх шаардлагатай');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/wallet/user'),
        headers: headers,
        body: json.encode(requestBody),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(
            data['message'] ?? 'Хэрэглэгчийн мэдээлэл шинэчлэхэд алдаа гарлаа',
          );
        }
      } else if (response.statusCode == 401) {
        throw Exception('Нэвтрэх шаардлагатай');
      } else {
        throw Exception(
          data['message'] ??
              'Хэрэглэгчийн мэдээлэл шинэчлэхэд алдаа гарлаа: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Хэрэглэгчийн мэдээлэл шинэчлэхэд алдаа гарлаа: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchWalletBilling({
    required String bairId,
    required String doorNo,
    String? duureg,
    String? horoo,
    String? soh,
    String? toot,
    String? davkhar,
    String? orts,
  }) async {
    try {
      final requestBody = <String, dynamic>{'bairId': bairId, 'doorNo': doorNo};

      if (duureg != null && duureg.isNotEmpty) {
        requestBody['duureg'] = duureg;
      }
      if (horoo != null && horoo.isNotEmpty) {
        requestBody['horoo'] = horoo;
      }
      if (soh != null && soh.isNotEmpty) {
        requestBody['soh'] = soh;
      }
      if (toot != null && toot.isNotEmpty) {
        requestBody['toot'] = toot;
      }
      if (davkhar != null && davkhar.isNotEmpty) {
        requestBody['davkhar'] = davkhar;
      }
      if (orts != null && orts.isNotEmpty) {
        requestBody['orts'] = orts;
      }

      final headers = await getWalletApiHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/walletBillingHavakh'),
        headers: headers,
        body: json.encode(requestBody),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['success'] == false) {
          if (data['message'] != null) {
            throw Exception(data['message']);
          } else if (data['aldaa'] != null) {
            throw Exception(data['aldaa']);
          } else {
            throw Exception('Биллингийн мэдээлэл авахад алдаа гарлаа');
          }
        }

        // Save updated user data if result is present
        if (data['result'] != null) {
          await StorageService.saveUserData(data);
        }

        return data;
      } else {
        if (data['message'] != null) {
          throw Exception(data['message']);
        } else if (data['aldaa'] != null) {
          throw Exception(data['aldaa']);
        } else {
          throw Exception(
            'Биллингийн мэдээлэл авахад алдаа гарлаа: ${response.statusCode}',
          );
        }
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Биллингийн мэдээлэл авахад алдаа гарлаа: $e');
    }
  }

  static Future<Map<String, dynamic>> registerWalletUser({
    required String utas,
    required String mail,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/walletBurtgey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'utas': utas, 'mail': mail}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['success'] == false) {
          if (data['message'] != null) {
            throw Exception(data['message']);
          } else if (data['aldaa'] != null) {
            throw Exception(data['aldaa']);
          } else {
            throw Exception('Бүртгэл үүсгэхэд алдаа гарлаа');
          }
        }
        return data;
      } else {
        if (data['message'] != null) {
          throw Exception(data['message']);
        } else if (data['aldaa'] != null) {
          throw Exception(data['aldaa']);
        } else {
          throw Exception(
            'Бүртгэл үүсгэхэд алдаа гарлаа: ${response.statusCode}',
          );
        }
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Бүртгэл үүсгэхэд алдаа гарлаа: $e');
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
    String? firebaseToken,
    String? bairId,
    String? doorNo,
    String? barilgiinId,
    String? duureg,
    String? horoo,
    String? soh,
    String? toot,
    String? davkhar,
    String? orts,
  }) async {
    final requestBody = <String, dynamic>{'utas': utas};

    if (firebaseToken != null && firebaseToken.isNotEmpty) {
      requestBody['firebaseToken'] = firebaseToken;
    }
    if (bairId != null && bairId.isNotEmpty) {
      requestBody['bairId'] = bairId;
    }
    if (doorNo != null && doorNo.isNotEmpty) {
      requestBody['doorNo'] = doorNo;
    }
    if (barilgiinId != null && barilgiinId.isNotEmpty) {
      requestBody['barilgiinId'] = barilgiinId;
    }
    if (duureg != null && duureg.isNotEmpty) {
      requestBody['duureg'] = duureg;
    }
    if (horoo != null && horoo.isNotEmpty) {
      requestBody['horoo'] = horoo;
    }
    if (soh != null && soh.isNotEmpty) {
      requestBody['soh'] = soh;
    }
    if (toot != null && toot.isNotEmpty) {
      requestBody['toot'] = toot;
    }
    if (davkhar != null && davkhar.isNotEmpty) {
      requestBody['davkhar'] = davkhar;
    }
    if (orts != null && orts.isNotEmpty) {
      requestBody['orts'] = orts;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/orshinSuugchNevtrey'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(requestBody),
    );

    final loginData = json.decode(response.body);

    if (loginData['success'] == false) {
      if (loginData['message'] != null) {
        throw Exception(loginData['message']);
      } else if (loginData['aldaa'] != null) {
        throw Exception(loginData['aldaa']);
      } else {
        throw Exception('Нэвтрэхэд алдаа гарлаа');
      }
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (loginData['success'] == true && loginData['token'] != null) {
        await StorageService.saveToken(loginData['token']);
        await StorageService.saveUserData(loginData);
        await SessionService.saveLoginTimestamp();
      }

      return loginData;
    } else {
      throw Exception(loginData['message'] ?? 'Нэвтрэхэд алдаа гарлаа');
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

  /// Get auth headers for Wallet API calls
  /// Wallet API requires userId header with phone number (NOT UUID)
  static Future<Map<String, String>> getWalletApiHeaders() async {
    final token = await StorageService.getToken();

    // Get phone number from user profile (most reliable source)
    String? userId;
    try {
      final userProfile = await getUserProfile();
      if (userProfile['result']?['utas'] != null) {
        userId = userProfile['result']['utas'].toString();
      } else if (userProfile['result']?['nevtrekhNer'] != null) {
        // Fallback to nevtrekhNer if utas is not available
        userId = userProfile['result']['nevtrekhNer'].toString();
      }
    } catch (e) {
      print('⚠️ [WALLET API] Could not get phone number from profile: $e');
      // Try saved phone as fallback
      userId = await StorageService.getSavedPhoneNumber();
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    // Wallet API requires userId header with phone number (NOT UUID)
    if (userId != null && userId.isNotEmpty) {
      headers['userId'] = userId;
      print('📱 [WALLET API] Using phone number in userId header: $userId');
    } else {
      print(
        '⚠️ [WALLET API] Warning: No phone number available for userId header',
      );
      print('   This may cause Wallet API calls to fail');
    }

    return headers;
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
