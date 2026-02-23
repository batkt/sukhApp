import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data' show Uint8List;
import 'package:flutter/widgets.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/services/session_service.dart';
import 'package:sukh_app/services/notification_service.dart';
import 'package:sukh_app/main.dart';
import 'package:go_router/go_router.dart';

class ApiService {
  static const String baseUrl = 'https://amarhome.mn/api';
  static const String deleteBaseUrl = 'https://amarhome.mn';
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

  /// Verify OTP code for login (OTP is automatically sent on successful login)
  /// Endpoint: POST /orshinSuugch/utasBatalgaajuulakhLogin
  static Future<Map<String, dynamic>> verifyLoginOTP({
    required String utas,
    required String code,
    required String baiguullagiinId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/utasBatalgaajuulakhLogin'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'utas': utas,
          'code': code,
          'baiguullagiinId': baiguullagiinId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check for error in response
        if (data['success'] == false ||
            data['error'] != null ||
            data['aldaa'] != null) {
          final errorMessage =
              data['message'] ??
              data['aldaa'] ??
              data['error'] ??
              'Баталгаажуулах код буруу байна';
          throw Exception(errorMessage);
        }

        // Check if success is explicitly true
        if (data['success'] == true) {
          return data;
        }

        // If no explicit success/error, assume success for 200 status
        return data;
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage =
            errorBody['message'] ??
            errorBody['aldaa'] ??
            errorBody['error'] ??
            'Баталгаажуулах код буруу байна: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Баталгаажуулах код шалгахад алдаа гарлаа: $e');
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

        // Check for error in response
        if (data['success'] == false ||
            data['error'] != null ||
            data['aldaa'] != null) {
          final errorMessage =
              data['message'] ??
              data['aldaa'] ??
              data['error'] ??
              'Баталгаажуулах код буруу байна';
          throw Exception(errorMessage);
        }

        // Check if success is explicitly true
        if (data['success'] == true) {
          return data;
        }

        // If no explicit success/error, assume success for 200 status
        return data;
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage =
            errorBody['message'] ??
            errorBody['aldaa'] ??
            errorBody['error'] ??
            'Баталгаажуулах код буруу байна: ${response.statusCode}';
        throw Exception(errorMessage);
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
      final url = '$baseUrl/walletAddress/city';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null && data['data'] is List) {
          final list = List<Map<String, dynamic>>.from(data['data']);
          return list;
        } else if (data is List) {
          final list = List<Map<String, dynamic>>.from(data);
          return list;
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
      final url = '$baseUrl/walletAddress/district/$cityId';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null && data['data'] is List) {
          final list = List<Map<String, dynamic>>.from(data['data']);
          return list;
        } else if (data is List) {
          final list = List<Map<String, dynamic>>.from(data);
          return list;
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
      final url = '$baseUrl/walletAddress/khoroo/$districtId';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null && data['data'] is List) {
          final list = List<Map<String, dynamic>>.from(data['data']);
          return list;
        } else if (data is List) {
          final list = List<Map<String, dynamic>>.from(data);
          return list;
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
        await handleUnauthorized();
        throw Exception('Нэвтрэлтийн хугацаа дууссан');
      } else if (response.statusCode == 404) {
        print(
          '❌ [GET-WALLET-BILLERS] 404 Error - URL: $baseUrl/wallet/billers',
        );
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

      response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        // Handle both Map and List responses
        Map<String, dynamic> data;
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        } else if (decoded is List) {
          if (decoded.isEmpty) {
            throw Exception('Биллингийн мэдээлэл олдсонгүй');
          }
          // If response is a list, wrap it in a map structure
          final firstItem = decoded[0];
          if (firstItem is Map<String, dynamic>) {
            data = {'success': true, 'data': firstItem};
          } else {
            throw Exception('Биллингийн мэдээлэл буруу форматтай байна');
          }
        } else {
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
          throw Exception(data['message'] ?? 'Төлбөр олдсонгүй');
        }
      } else if (response.statusCode == 404) {
        print('❌ [FIND-BILLING] 404 - Not found');
        throw Exception('Төлбөр олдсонгүй');
      } else if (response.statusCode == 401) {
        print('❌ [FIND-BILLING] 401 - Unauthorized');
        await handleUnauthorized();
        throw Exception('Нэвтрэлтийн хугацаа дууссан');
      } else {
        print('❌ [FIND-BILLING] Error status: ${response.statusCode}');
        throw Exception('Биллинг авахад алдаа гарлаа: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [FIND-BILLING] Exception caught: $e');
      print('❌ [FIND-BILLING] Exception type: ${e.runtimeType}');
      if (response != null) {
      }
      if (e.toString().contains('is not a subtype') ||
          e.toString().contains('List<dynamic>') ||
          e.toString().contains('Map<String, dynamic>')) {
        print('❌ [FIND-BILLING] Type casting error detected');
        throw Exception('Биллингийн мэдээлэл буруу форматтай байна');
      }
      // Check if the error already contains "Төлбөр олдсонгүй" to avoid nested messages
      if (e.toString().contains('Төлбөр олдсонгүй') ||
          e.toString().contains('Биллингийн мэдээлэл олдсонгүй')) {
        throw Exception('Төлбөр олдсонгүй');
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
          throw Exception(data['message'] ?? 'Төлбөр олдсонгүй');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Төлбөр олдсонгүй');
      } else if (response.statusCode == 401) {
        await handleUnauthorized();
        throw Exception('Нэвтрэлтийн хугацаа дууссан');
      } else {
        throw Exception('Биллинг авахад алдаа гарлаа: ${response.statusCode}');
      }
    } catch (e) {
      // Check if the error already contains "Төлбөр олдсонгүй" to avoid nested messages
      if (e.toString().contains('Төлбөр олдсонгүй') ||
          e.toString().contains('Биллингийн мэдээлэл олдсонгүй')) {
        throw Exception('Төлбөр олдсонгүй');
      }
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
        await handleUnauthorized();
        throw Exception('Нэвтрэлтийн хугацаа дууссан');
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
        // Only print once, not on every call
        if (data['success'] == true || data['responseCode'] == true) {
          print(
            '📄 [API] Billing bills response: ${data.toString().substring(0, data.toString().length > 500 ? 500 : data.toString().length)}...',
          );
        }

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
        await handleUnauthorized();
        throw Exception('Нэвтрэлтийн хугацаа дууссан');
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
        await handleUnauthorized();
        throw Exception('Нэвтрэлтийн хугацаа дууссан');
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
        await handleUnauthorized();
        throw Exception('Нэвтрэлтийн хугацаа дууссан');
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
        await handleUnauthorized();
        throw Exception('Нэвтрэлтийн хугацаа дууссан');
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
        await handleUnauthorized();
        throw Exception('Нэвтрэлтийн хугацаа дууссан');
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
        await handleUnauthorized();
        throw Exception('Нэвтрэлтийн хугацаа дууссан');
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
        await handleUnauthorized();
        throw Exception('Нэвтрэлтийн хугацаа дууссан');
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
        await handleUnauthorized();
        throw Exception('Нэвтрэлтийн хугацаа дууссан');
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
        await handleUnauthorized();
        throw Exception('Нэвтрэлтийн хугацаа дууссан');
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
        await handleUnauthorized();
        throw Exception('Нэвтрэлтийн хугацаа дууссан');
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
        await handleUnauthorized();
        throw Exception('Нэвтрэлтийн хугацаа дууссан');
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
        await handleUnauthorized();
        throw Exception('Нэвтрэлтийн хугацаа дууссан');
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
        await handleUnauthorized();
        throw Exception('Нэвтрэлтийн хугацаа дууссан');
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

  static Future<Map<String, dynamic>> validateOwnOrgToot({
    required String toot,
    required String baiguullagiinId,
    required String barilgiinId,
  }) async {
    try {
      final requestBody = <String, dynamic>{
        'toot': toot,
        'baiguullagiinId': baiguullagiinId,
        'barilgiinId': barilgiinId,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/validateOwnOrgToot'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      } else {
        if (data['message'] != null) {
          throw Exception(data['message']);
        } else if (data['aldaa'] != null) {
          throw Exception(data['aldaa']);
        } else {
          throw Exception('Тоот баталгаажуулахад алдаа гарлаа');
        }
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Тоот баталгаажуулахад алдаа гарлаа: $e');
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
    String? baiguullagiinId,
    String? barilgiinId,
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
      if (baiguullagiinId != null && baiguullagiinId.isNotEmpty) {
        requestBody['baiguullagiinId'] = baiguullagiinId;
      }
      if (barilgiinId != null && barilgiinId.isNotEmpty) {
        requestBody['barilgiinId'] = barilgiinId;
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
    String? bairId,
    String? doorNo,
    String? bairName,
  }) async {
    try {
      final requestBody = <String, dynamic>{'utas': utas, 'mail': mail};

      // Add address fields if provided (for Wallet API addresses)
      if (bairId != null && bairId.isNotEmpty) {
        requestBody['bairId'] = bairId;
      }
      if (doorNo != null && doorNo.isNotEmpty) {
        requestBody['doorNo'] = doorNo;
      }
      if (bairName != null && bairName.isNotEmpty) {
        requestBody['bairName'] = bairName;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/walletBurtgey'),
        headers: {'Content-Type': 'application/json'},
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
    required String nuutsUg,
    String? firebaseToken,
    String? bairId,
    String? doorNo,
    String? bairName,
    String? barilgiinId,
    String? baiguullagiinId,
    String? duureg,
    String? horoo,
    String? soh,
    String? toot,
    String? davkhar,
    String? orts,
  }) async {
    final requestBody = <String, dynamic>{'utas': utas, 'nuutsUg': nuutsUg};

    if (firebaseToken != null && firebaseToken.isNotEmpty) {
      requestBody['firebaseToken'] = firebaseToken;
    }
    if (bairId != null && bairId.isNotEmpty) {
      requestBody['bairId'] = bairId;
    }
    if (doorNo != null && doorNo.isNotEmpty) {
      requestBody['doorNo'] = doorNo;
    }
    if (bairName != null && bairName.isNotEmpty) {
      requestBody['bairName'] = bairName;
    }
    if (baiguullagiinId != null && baiguullagiinId.isNotEmpty) {
      requestBody['baiguullagiinId'] = baiguullagiinId;
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

  /// Handle 401 Unauthorized response - automatically logout and redirect to login
  static Future<void> handleUnauthorized() async {
    print('🔒 [API] 401 Unauthorized - Token expired, logging out...');

    // Check if already logged out to avoid duplicate logout
    final isLoggedIn = await StorageService.isLoggedIn();
    if (!isLoggedIn) {
      print('🔒 [API] Already logged out, skipping...');
      return;
    }

    // Show session expired notification
    await NotificationService.showSessionExpiredNotification();

    // Logout user
    await SessionService.logout();

    // Navigate to login page
    final context = navigatorKey.currentContext;
    if (context != null) {
      // Use post-frame callback to ensure navigation happens after logout
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final navContext = navigatorKey.currentContext;
        if (navContext != null) {
          try {
            // Clear navigation stack and go to login
            while (navContext.canPop()) {
              navContext.pop();
            }
            navContext.go('/newtrekh');
          } catch (e) {
            print('⚠️ [API] Error navigating to login: $e');
            // Fallback: try to go directly
            try {
              navContext.go('/newtrekh');
            } catch (e2) {
              print('⚠️ [API] Fallback navigation also failed: $e2');
            }
          }
        }
      });
    }
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

  static Future<Map<String, dynamic>> updatePlateNumber(
    String mashiniiDugaar,
  ) async {
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
          'mashiniiDugaar': mashiniiDugaar,
          'dugaarUurchilsunOgnoo': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        String message = 'Дугаар солиход алдаа гарлаа';
        try {
          final data = json.decode(response.body);
          message = data['message'] ?? data['aldaa'] ?? message;
        } catch (_) {}
        throw Exception(message);
      }
    } catch (e) {
      print('Error updating plate number: $e');
      throw Exception('Дугаар солиход алдаа гарлаа: $e');
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
      final authHeaders = await getAuthHeaders();
      final headers = {
        ...authHeaders,
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
      };

      final uri = Uri.parse('$baseUrl/geree').replace(
        queryParameters: {
          'query': '{"orshinSuugchId":"$orshinSuugchId"}',
          '_t': DateTime.now().millisecondsSinceEpoch.toString(),
        },
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

      final uri = Uri.parse('$baseUrl/nekhemjlekhiinTuukh').replace(
        queryParameters: {
          '_t': DateTime.now().millisecondsSinceEpoch.toString(),
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
          // JSON parsing failed
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
    int khuudasniiKhemjee = 200,
  }) async {
    try {
      final authHeaders = await getAuthHeaders();
      final headers = {
        ...authHeaders,
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
      };

      final queryJson = json.encode({'gereeniiDugaar': gereeniiDugaar});
      final uri = Uri.parse('$baseUrl/nekhemjlekhiinTuukh').replace(
        queryParameters: {
          'query': queryJson,
          'khuudasniiDugaar': khuudasniiDugaar.toString(),
          'khuudasniiKhemjee': khuudasniiKhemjee.toString(),
          '_t': DateTime.now().millisecondsSinceEpoch.toString(),
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
          // JSON parsing failed
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

  /// Fetch gereeniiTulukhAvlaga (avlaga + ekhniiUldegdel) for merging with invoices.
  /// Matches web "Үйлчилгээний нэхэмжлэх" which merges this data for display.
  static Future<Map<String, dynamic>> fetchGereeniiTulukhAvlaga({
    required String baiguullagiinId,
    String? gereeniiDugaar,
    String? orshinSuugchId,
    String? barilgiinId,
    String? gereeniiId,
    int khuudasniiDugaar = 1,
    int khuudasniiKhemjee = 500,
  }) async {
    try {
      final authHeaders = await getAuthHeaders();
      final headers = {
        ...authHeaders,
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
      };

      final query = <String, dynamic>{'baiguullagiinId': baiguullagiinId};
      if (gereeniiId != null && gereeniiId.isNotEmpty) {
        query['gereeniiId'] = gereeniiId;
      }
      if (gereeniiDugaar != null && gereeniiDugaar.isNotEmpty) {
        query['gereeniiDugaar'] = gereeniiDugaar;
      }
      if (orshinSuugchId != null && orshinSuugchId.isNotEmpty) {
        query['orshinSuugchId'] = orshinSuugchId;
      }
      if (barilgiinId != null && barilgiinId.isNotEmpty) {
        query['barilgiinId'] = barilgiinId;
      }

      final queryJson = json.encode(query);
      final uri = Uri.parse('$baseUrl/gereeniiTulukhAvlaga').replace(
        queryParameters: {
          'query': queryJson,
          'baiguullagiinId': baiguullagiinId,
          'khuudasniiDugaar': khuudasniiDugaar.toString(),
          'khuudasniiKhemjee': khuudasniiKhemjee.toString(),
          '_t': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          if (data is String) return {'jagsaalt': []};
          return data is Map<String, dynamic> ? data : {'jagsaalt': []};
        } catch (e) {
          print(
            'JSON parsing failed for gereeniiTulukhAvlaga: ${response.body}',
          );
          return {'jagsaalt': []};
        }
      }
      return {'jagsaalt': []};
    } catch (e) {
      print('Error fetching gereeniiTulukhAvlaga: $e');
      return {'jagsaalt': []};
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
          // Check if response body is a plain string (not JSON)
          final responseBody = response.body.trim();
          if (responseBody.isEmpty) {
            return {'jagsaalt': []};
          }

          // Try to decode as JSON
          final data = json.decode(responseBody);

          // If decoded data is a string, it means the API returned a JSON-encoded string
          if (data is String) {
            print('API returned string instead of JSON object: $data');
            return {'jagsaalt': []};
          }

          // Ensure we return a Map
          if (data is Map<String, dynamic>) {
            return data;
          }

          // If it's not a Map, return empty result
          print('API returned unexpected data type: ${data.runtimeType}');
          return {'jagsaalt': []};
        } catch (e) {
          // If JSON decode fails, the response might be a plain string
          // JSON parsing failed
          print('Error: $e');
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

  /// Save ebarimt connection code
  static Future<Map<String, dynamic>> saveEbarimtConnection({
    required String code,
    bool printDocument = false,
  }) async {
    try {
      final headers = await getAuthHeaders();
      final userId = await StorageService.getUserId();
      final baiguullagiinId = await StorageService.getBaiguullagiinId();

      if (userId == null || baiguullagiinId == null) {
        throw Exception('Хэрэглэгчийн мэдээлэл олдсонгүй');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/ebarimtHavakh'),
        headers: headers,
        body: json.encode({
          'orshinSuugchId': userId,
          'baiguullagiinId': baiguullagiinId,
          'code': code,
          'printDocument': printDocument,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': 'E-barimt холболт амжилттай хадгалагдлаа',
          'data': data,
        };
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['message']?.toString() ??
              'E-barimt холболт хадгалахад алдаа гарлаа',
        );
      }
    } catch (e) {
      print('Error saving ebarimt connection: $e');
      throw Exception('E-barimt холболт хадгалахад алдаа гарлаа: $e');
    }
  }

  /// Update consumer info for easy-register
  static Future<Map<String, dynamic>> updateConsumerInfo({
    required String identity,
    required Map<String, dynamic> data,
  }) async {
    try {
      final headers = await getAuthHeaders();
      final userId = await StorageService.getUserId();
      final baiguullagiinId = await StorageService.getBaiguullagiinId();

      if (userId == null || baiguullagiinId == null) {
        throw Exception('Хэрэглэгчийн мэдээлэл олдсонгүй');
      }

      final requestBody = {
        'orshinSuugchId': userId,
        'baiguullagiinId': baiguullagiinId,
        'identity': identity,
        ...data,
      };

      final response = await http.put(
        Uri.parse('$baseUrl/easy-register/consumer'),
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = json.decode(response.body);
          return {
            'success': true,
            'message': 'Хэрэглэгчийн мэдээлэл амжилттай шинэчлэгдлээ',
            'data': responseData,
          };
        } catch (e) {
          return {
            'success': true,
            'message': 'Хэрэглэгчийн мэдээлэл амжилттай шинэчлэгдлээ',
          };
        }
      } else if (response.statusCode == 401) {
        await handleUnauthorized();
        throw Exception('Нэвтрэлтийн хугацаа дууссан');
      } else {
        String errorMessage =
            'Хэрэглэгчийн мэдээлэл шинэчлэхэд алдаа гарлаа: ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          errorMessage =
              errorData['message']?.toString() ??
              errorData['aldaa']?.toString() ??
              errorMessage;
        } catch (_) {
          // If response is not JSON, use default message
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      print('Error updating consumer info: $e');
      throw Exception('Хэрэглэгчийн мэдээлэл шинэчлэхэд алдаа гарлаа: $e');
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

  /// Fetch baiguullaga by ID
  static Future<Map<String, dynamic>> fetchBaiguullagaById(
    String baiguullagiinId, {
    String? barilgiinId,
  }) async {
    try {
      final headers = await getAuthHeaders();

      final queryParams = <String, String>{};
      if (barilgiinId != null) {
        queryParams['barilgiinId'] = barilgiinId;
      }

      final uri = Uri.parse(
        '$baseUrl/baiguullaga/$baiguullagiinId',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Байгууллагын мэдээлэл татахад алдаа гарлаа: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching baiguullaga by id: $e');
      throw Exception('Байгууллагын мэдээлэл татахад алдаа гарлаа: $e');
    }
  }

  /// Create QPay invoice
  /// Supports both Custom QPay (OWN_ORG) and Wallet QPay
  /// Auto-detects based on presence of walletUserId/walletBairId
  static Future<Map<String, dynamic>> qpayGargaya({
    String? baiguullagiinId, // For Custom QPay
    String? barilgiinId, // For Custom QPay
    String? walletUserId, // For Wallet QPay
    String? walletBairId, // For Wallet QPay
    required double dun,
    String? turul, // Optional for Wallet QPay
    String? zakhialgiinDugaar, // Optional
    String? nekhemjlekhiinId, // Single invoice ID (for Custom QPay)
    String? dansniiDugaar, // Account number (for Custom QPay)
    String? burtgeliinDugaar, // Registration number (for Custom QPay)
  }) async {
    try {
      final headers = await getAuthHeaders();

      // Build request body based on type (Custom QPay vs Wallet QPay)
      final Map<String, dynamic> requestBody = {
        'dun': dun.toString(), // Amount as string
      };

      // Custom QPay (OWN_ORG) - requires baiguullagiinId
      if (baiguullagiinId != null && barilgiinId != null) {
        requestBody['baiguullagiinId'] = baiguullagiinId;
        requestBody['barilgiinId'] = barilgiinId;

        if (dansniiDugaar != null && dansniiDugaar.isNotEmpty) {
          requestBody['dansniiDugaar'] = dansniiDugaar;
        }

        if (burtgeliinDugaar != null && burtgeliinDugaar.isNotEmpty) {
          requestBody['burtgeliinDugaar'] = burtgeliinDugaar;
        }

        if (nekhemjlekhiinId != null && nekhemjlekhiinId.isNotEmpty) {
          requestBody['nekhemjlekhiinId'] = nekhemjlekhiinId;
        }

        if (turul != null && turul.isNotEmpty) {
          requestBody['turul'] = turul;
        }

        if (zakhialgiinDugaar != null && zakhialgiinDugaar.isNotEmpty) {
          requestBody['zakhialgiinDugaar'] = zakhialgiinDugaar;
        }
      }
      // Wallet QPay - DEPRECATED: Use createWalletQPayPayment() instead
      // This old method with dun + walletUserId/walletBairId is no longer supported
      // Wallet API QPay now requires billingId + billIds (see createWalletQPayPayment)
      else if (walletUserId != null || walletBairId != null) {
        throw Exception(
          'Wallet API QPay энэ аргаар ажиллахгүй байна. '
          'billingId + billIds ашиглах шаардлагатай. '
          'createWalletQPayPayment() функцийг ашиглана уу.',
        );
      } else {
        throw Exception('QPay төрөл тодорхойлогдоогүй байна');
      }

      final endpoint = '$baseUrl/qpayGargaya';
      print('🔍 [QPAY] Calling OWN_ORG QPay endpoint: $endpoint');
      print('🔍 [QPAY] Request body: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: json.encode(requestBody),
      );

      print('🔍 [QPAY] Response status: ${response.statusCode}');
      if (response.statusCode != 200 && response.statusCode != 201) {
        print(
          '🔍 [QPAY] Response body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}',
        );
      }

      // Check if response is JSON before parsing
      final contentType = response.headers['content-type'] ?? '';
      final isJson =
          contentType.contains('application/json') ||
          (response.body.trim().startsWith('{') ||
              response.body.trim().startsWith('['));

      if (!isJson) {
        // Server returned HTML or other non-JSON response
        print(
          'QPay API returned non-JSON response: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}',
        );
        throw Exception(
          'Сервер алдаатай хариу буцааллаа. Статус код: ${response.statusCode}',
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        Map<String, dynamic> responseData;
        try {
          responseData = json.decode(response.body) as Map<String, dynamic>;
        } catch (e) {
          print('Failed to parse QPay response as JSON: $e');
          print(
            'Response body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}',
          );
          throw Exception('Серверийн хариуг уншихад алдаа гарлаа');
        }

        // Handle new response format: { "success": true, "data": { "invoice_id": "...", "qr_image": "..." } }
        // For Wallet QPay: { "success": true, "data": { "qpayInvoiceId": "...", "qrText": "..." } }
        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'];
          return {
            'invoice_id':
                data['invoice_id']?.toString() ??
                data['qpayInvoiceId']?.toString(),
            'qr_image': data['qr_image']?.toString(),
            'qrText': data['qrText']?.toString(), // For Wallet QPay
            'urls': responseData['urls'], // Keep URLs if present
          };
        }
        // Handle legacy format: { "invoice_id": "...", "qr_image": "..." }
        return responseData;
      } else {
        // Try to parse error response
        Map<String, dynamic>? errorBody;
        try {
          errorBody = json.decode(response.body) as Map<String, dynamic>?;
        } catch (e) {
          // If error response is not JSON, use status code
          print('Failed to parse error response as JSON: $e');
          throw Exception(
            'QPay төлбөр үүсгэхэд алдаа гарлаа: ${response.statusCode}',
          );
        }
        throw Exception(
          errorBody?['message']?.toString() ??
              'QPay төлбөр үүсгэхэд алдаа гарлаа: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error creating QPay payment: $e');
      // Re-throw if it's already a formatted Exception
      if (e is Exception) {
        rethrow;
      }
      throw Exception('QPay төлбөр үүсгэхэд алдаа гарлаа: $e');
    }
  }

  /// Create QPay payment for Wallet API
  /// Endpoint: POST /qpay/qpayGargaya
  /// Only for WALLET_API source
  static Future<Map<String, dynamic>> createWalletQPayPayment({
    required String billingId,
    required List<String> billIds,
    String? invoiceId, // Optional: use existing invoice
    String vatReceiveType = 'CITIZEN', // 'CITIZEN' or 'COMPANY'
    String? vatCompanyReg, // Optional, only if COMPANY
  }) async {
    try {
      final headers = await getAuthHeaders();

      // Build request body
      final Map<String, dynamic> requestBody;

      if (invoiceId != null && invoiceId.isNotEmpty) {
        // Option B: Use existing invoice
        requestBody = {'invoiceId': invoiceId};
      } else {
        // Option A: Auto-create invoice (recommended)
        requestBody = {
          'billingId': billingId,
          'billIds': billIds,
          'vatReceiveType': vatReceiveType,
        };

        if (vatReceiveType == 'COMPANY' &&
            vatCompanyReg != null &&
            vatCompanyReg.isNotEmpty) {
          requestBody['vatCompanyReg'] = vatCompanyReg;
        }
      }

      final endpoint = '$baseUrl/qpayGargaya';
      print('💳 [WALLET QPAY] Creating payment with billingId: $billingId');
      print('💳 [WALLET QPAY] Bill IDs: $billIds');
      print('💳 [WALLET QPAY] Calling Wallet QPay endpoint: $endpoint');
      print('💳 [WALLET QPAY] Request body: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: json.encode(requestBody),
      );


      if (response.statusCode != 200 && response.statusCode != 201) {
        print(
          '❌ [WALLET QPAY] Error response: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}',
        );
      } else {
        print('✅ [WALLET QPAY] Success response received');
        // Log first 500 chars of response for debugging
        final responsePreview = response.body.length > 500
            ? '${response.body.substring(0, 500)}...'
            : response.body;
        print('💳 [WALLET QPAY] Response preview: $responsePreview');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        Map<String, dynamic> responseData;
        try {
          responseData = json.decode(response.body) as Map<String, dynamic>;
          print('✅ [WALLET QPAY] Response: $responseData');
        } catch (e) {
          print('❌ [WALLET QPAY] Failed to parse response: $e');
          print(
            '❌ [WALLET QPAY] Response body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}',
          );
          throw Exception('Серверийн хариуг уншихад алдаа гарлаа: $e');
        }

        // Handle success response format - check both 'success' and 'responseCode'
        final isSuccess =
            responseData['success'] == true ||
            responseData['responseCode'] == true;

        if (isSuccess) {
          final data = responseData['data'] as Map<String, dynamic>?;

          if (data != null) {
            final qrText = data['qrText']?.toString();
            final paymentId = data['paymentId']?.toString();
            final paymentAmount = data['paymentAmount'];
            String? receiverBankCode = data['receiverBankCode']?.toString();
            String? receiverAccountNo = data['receiverAccountNo']?.toString();
            String? receiverAccountName = data['receiverAccountName']
                ?.toString();
            final transactionDescrion = data['transactionDescrion']?.toString();

            print('✅ [WALLET QPAY] Payment created!');
            print('📱 [WALLET QPAY] Payment ID: $paymentId');
            print('💰 [WALLET QPAY] Amount: $paymentAmount');
            print('🏦 [WALLET QPAY] Bank Code: $receiverBankCode');
            print('🏦 [WALLET QPAY] Account No: $receiverAccountNo');
            print('🏦 [WALLET QPAY] Account Name: $receiverAccountName');

            // If bank details are empty, fetch payment status to get full details
            if ((receiverBankCode == null || receiverBankCode.isEmpty) ||
                (receiverAccountNo == null || receiverAccountNo.isEmpty)) {
              print(
                '⚠️ [WALLET QPAY] Bank details empty, fetching payment status...',
              );

              if (paymentId != null) {
                try {
                  // Wait a moment for payment to be processed
                  await Future.delayed(const Duration(milliseconds: 500));

                  final paymentStatus = await getWalletPaymentStatus(
                    paymentId: paymentId,
                  );
                  final statusData =
                      paymentStatus['data'] as Map<String, dynamic>?;

                  if (statusData != null) {
                    // Try root level first
                    receiverBankCode ??= statusData['receiverBankCode']
                        ?.toString();
                    receiverAccountNo ??= statusData['receiverAccountNo']
                        ?.toString();
                    receiverAccountName ??= statusData['receiverAccountName']
                        ?.toString();

                    // If still empty, try to get from lines
                    if (receiverAccountNo == null ||
                        receiverAccountNo.isEmpty) {
                      final lines = statusData['lines'] as List<dynamic>?;
                      if (lines != null && lines.isNotEmpty) {
                        for (var line in lines) {
                          final billTransactions =
                              line['billTransactions'] as List<dynamic>?;
                          if (billTransactions != null &&
                              billTransactions.isNotEmpty) {
                            final transaction =
                                billTransactions.first as Map<String, dynamic>;
                            receiverBankCode ??= transaction['receiverBankCode']
                                ?.toString();
                            receiverAccountNo ??=
                                transaction['receiverAccountNo']?.toString();
                            receiverAccountName ??=
                                transaction['receiverAccountName']?.toString();
                            if (receiverAccountNo != null &&
                                receiverAccountNo.isNotEmpty) {
                              break;
                            }
                          }
                        }
                      }
                    }

                    print(
                      '🏦 [WALLET QPAY] After fetch - Bank Code: $receiverBankCode',
                    );
                    print(
                      '🏦 [WALLET QPAY] After fetch - Account No: $receiverAccountNo',
                    );
                    print(
                      '🏦 [WALLET QPAY] After fetch - Account Name: $receiverAccountName',
                    );
                  }
                } catch (e) {
                  print('⚠️ [WALLET QPAY] Error fetching payment status: $e');
                }
              }
            }

            // Generate QR code text if not provided
            String? finalQrText = qrText;
            if (finalQrText == null || finalQrText.isEmpty) {
              // Generate QPay QR code from payment details
              // Format: QPay QR code format with payment details
              if (receiverAccountNo != null &&
                  receiverAccountNo.isNotEmpty &&
                  paymentAmount != null) {
                // QPay QR format: bank code, account, amount, description
                finalQrText = _generateQPayQRText(
                  bankCode: receiverBankCode ?? '',
                  accountNo: receiverAccountNo,
                  amount: paymentAmount,
                  description: transactionDescrion ?? '',
                );
                print(
                  '📱 [WALLET QPAY] Generated QR code from payment details',
                );
              } else {
                print(
                  '⚠️ [WALLET QPAY] Cannot generate QR: missing accountNo or amount',
                );
              }
            }

            if (finalQrText != null) {
              print(
                '📱 [WALLET QPAY] QR Code: ${finalQrText.substring(0, finalQrText.length > 100 ? 100 : finalQrText.length)}...',
              );
            }

            return {
              'success': true,
              'message':
                  responseData['responseMessage']?.toString() ??
                  responseData['message']?.toString() ??
                  'QPay төлбөр амжилттай үүсгэлээ',
              'source': responseData['source']?.toString() ?? 'WALLET_API',
              'paymentId': paymentId,
              'paymentAmount': paymentAmount,
              'receiverBankCode': receiverBankCode,
              'receiverAccountName': receiverAccountName,
              'receiverAccountNo': receiverAccountNo,
              'transactionDescrion': transactionDescrion,
              'qrText': finalQrText, // Generated or from response
              'qrImage': data['qrImage']?.toString(), // Optional: QR image URL
              'invoiceId': responseData['invoiceId']
                  ?.toString(), // Returned invoice ID
            };
          }
        }

        // Fallback: return raw response
        final errorMsg =
            responseData['responseMessage']?.toString() ??
            responseData['message']?.toString() ??
            'Unknown error';
        print('⚠️ [WALLET QPAY] Response success flag is false: $errorMsg');
        throw Exception(errorMsg);
      } else {
        // Try to parse error response
        Map<String, dynamic>? errorBody;
        try {
          errorBody = json.decode(response.body) as Map<String, dynamic>?;
        } catch (e) {
          // If error response is not JSON, use status code
        }

        final errorMessage =
            errorBody?['message']?.toString() ??
            errorBody?['responseMsg']?.toString() ??
            'QPay төлбөр үүсгэхэд алдаа гарлаа: ${response.statusCode}';
        final errorCode = errorBody?['error']?.toString();

        // Handle "Bill already in invoice" error - check for existing payments
        if (response.statusCode == 400 &&
            (errorCode == 'BILL_ALREADY_IN_INVOICE' ||
                errorMessage.contains(
                  'өөр нэхэмжлэлээр төлөлт хийгдэж байна',
                ))) {
          print(
            '⚠️ [WALLET QPAY] Bill already in invoice, checking for existing payments...',
          );

          try {
            // Check for existing payments for this billing
            final existingPayments = await getWalletBillingPayments(
              billingId: billingId,
            );

            if (existingPayments.isNotEmpty) {
              // Find payment that contains the selected billIds
              for (var payment in existingPayments) {
                final paymentBillIds = payment['billIds'] as List<dynamic>?;
                if (paymentBillIds != null) {
                  // Check if any of the selected billIds are in this payment
                  final hasMatchingBills = billIds.any(
                    (billId) =>
                        paymentBillIds.any((pid) => pid.toString() == billId),
                  );

                  if (hasMatchingBills) {
                    final paymentId = payment['paymentId']?.toString();
                    if (paymentId != null) {
                      print(
                        '✅ [WALLET QPAY] Found existing payment: $paymentId',
                      );

                      // Get payment status to get bank details
                      try {
                        final paymentStatus = await getWalletPaymentStatus(
                          paymentId: paymentId,
                        );
                        final paymentData =
                            paymentStatus['data'] as Map<String, dynamic>?;

                        if (paymentData != null) {
                          // Extract bank details from payment status
                          // First try root level (if payment is ready)
                          String? receiverBankCode =
                              paymentData['receiverBankCode']?.toString();
                          String? receiverAccountNo =
                              paymentData['receiverAccountNo']?.toString();
                          String? receiverAccountName =
                              paymentData['receiverAccountName']?.toString();
                          final paymentAmount =
                              paymentData['totalAmount'] ??
                              paymentData['amount'] ??
                              paymentData['paymentAmount'];

                          // If not found at root, try to get from lines
                          if (receiverAccountNo == null) {
                            final lines =
                                paymentData['lines'] as List<dynamic>?;
                            if (lines != null && lines.isNotEmpty) {
                              for (var line in lines) {
                                final billTransactions =
                                    line['billTransactions'] as List<dynamic>?;
                                if (billTransactions != null &&
                                    billTransactions.isNotEmpty) {
                                  final transaction =
                                      billTransactions.first
                                          as Map<String, dynamic>;
                                  receiverBankCode ??=
                                      transaction['receiverBankCode']
                                          ?.toString();
                                  receiverAccountNo ??=
                                      transaction['receiverAccountNo']
                                          ?.toString();
                                  receiverAccountName ??=
                                      transaction['receiverAccountName']
                                          ?.toString();
                                  if (receiverAccountNo != null) break;
                                }
                              }
                            }
                          }

                          // Generate QR code from payment details
                          String? finalQrText;
                          if (receiverAccountNo != null &&
                              paymentAmount != null) {
                            finalQrText = _generateQPayQRText(
                              bankCode: receiverBankCode ?? '',
                              accountNo: receiverAccountNo,
                              amount: paymentAmount,
                              description:
                                  paymentData['transactionDescrion']
                                      ?.toString() ??
                                  paymentData['transactionDescription']
                                      ?.toString() ??
                                  '',
                            );
                            print(
                              '📱 [WALLET QPAY] Generated QR code from existing payment',
                            );
                          } else {
                            print(
                              '⚠️ [WALLET QPAY] Cannot generate QR: missing accountNo or amount',
                            );
                          }

                          return {
                            'success': true,
                            'message': 'Одоо байгаа төлбөрийн мэдээлэл',
                            'source': 'WALLET_API',
                            'paymentId': paymentId,
                            'paymentAmount': paymentAmount,
                            'receiverBankCode': receiverBankCode,
                            'receiverAccountName': receiverAccountName,
                            'receiverAccountNo': receiverAccountNo,
                            'transactionDescrion':
                                paymentData['transactionDescrion']
                                    ?.toString() ??
                                paymentData['transactionDescription']
                                    ?.toString(),
                            'qrText': finalQrText,
                            'qrImage': null,
                            'invoiceId': paymentData['invoiceId']?.toString(),
                          };
                        }
                      } catch (e) {
                        print(
                          '⚠️ [WALLET QPAY] Error getting payment status: $e',
                        );
                      }
                    }
                  }
                }
              }
            }
          } catch (e) {
            print('⚠️ [WALLET QPAY] Error checking existing payments: $e');
          }

          // If no existing payment found, throw the original error
          throw Exception(
            '$errorMessage\n\nЭнэ биллийг өөр нэхэмжлэлээр төлөлт хийгдэж байна. Төлбөрийн түүхийг шалгана уу.',
          );
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('QPay төлбөр үүсгэхэд алдаа гарлаа: $e');
    }
  }

  /// Generate QPay QR code text from payment details
  /// Format: QPay QR code string with bank code, account, amount, description
  /// QPay QR format in Mongolia typically uses a structured string
  static String _generateQPayQRText({
    required String bankCode,
    required String accountNo,
    required dynamic amount,
    required String description,
  }) {
    // QPay QR code format for Mongolia
    // Common format: JSON string with payment details
    // Format: {"bankCode":"XXX","account":"XXX","amount":XXX,"description":"XXX"}
    final amountValue = amount is num
        ? amount.toDouble()
        : double.tryParse(amount.toString()) ?? 0.0;
    final amountStr = amountValue.toStringAsFixed(2);

    // Create JSON structure for QPay QR code
    final qrData = {
      'bankCode': bankCode,
      'account': accountNo,
      'amount': amountStr,
      'description': description,
    };

    // Return as JSON string (QPay can parse this)
    return json.encode(qrData);
  }

  /// Check Wallet payment status
  /// Endpoint: GET /orshinSuugch/walletPayment/:paymentId
  static Future<Map<String, dynamic>> getWalletPaymentStatus({
    required String paymentId,
  }) async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/orshinSuugch/walletPayment/$paymentId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data;
      } else if (response.statusCode == 401) {
        await handleUnauthorized();
        throw Exception('Нэвтрэлтийн хугацаа дууссан');
      } else {
        throw Exception(
          'Төлбөрийн статус авахад алдаа гарлаа: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Төлбөрийн статус авахад алдаа гарлаа: $e');
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
    required String barilgiinId,
  }) async {
    try {
      final headers = await getAuthHeaders();
      // Backend expects GET request with barilgiinId as query parameter
      final uri = Uri.parse(
        '$baseUrl/nekhemjlekhCron',
      ).replace(queryParameters: {'barilgiinId': barilgiinId});

      final response = await http.get(uri, headers: headers);


      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
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

      print(
        '📞 [API] fetchAjiltan - baiguullagiinId: $baiguullagiinId, barilgiinId: $barilgiinId',
      );

      if (baiguullagiinId == null || barilgiinId == null) {
        throw Exception('Байгууллага эсвэл барилгын мэдээлэл олдсонгүй');
      }

      final uri = Uri.parse(
        '$baseUrl/ajiltan',
      ).replace(queryParameters: {'baiguullagiinId': baiguullagiinId});

      print('📞 [API] fetchAjiltan URL: $uri');

      final response = await http.get(uri, headers: headers);

      print('📞 [API] fetchAjiltan response status: ${response.statusCode}');
      print(
        '📞 [API] fetchAjiltan response body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        print('📞 [API] fetchAjiltan data keys: ${data.keys}');
        print(
          '📞 [API] fetchAjiltan jagsaalt type: ${data['jagsaalt']?.runtimeType}',
        );
        print(
          '📞 [API] fetchAjiltan jagsaalt length: ${data['jagsaalt']?.length}',
        );

        // Filter jagsaalt by baiguullagiinId on client side
        if (data['jagsaalt'] != null && data['jagsaalt'] is List) {
          final filteredList = (data['jagsaalt'] as List).where((ajiltan) {
            print(
              '📞 [API] Checking ajiltan: ${ajiltan['ner']}, baiguullagiinId: ${ajiltan['baiguullagiinId']}',
            );
            return ajiltan['baiguullagiinId'] == baiguullagiinId;
          }).toList();

          print('📞 [API] fetchAjiltan filtered count: ${filteredList.length}');

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
        // Filter to only include notifications where turul = "app" or "мэдэгдэл"
        // Also filter by userId as a fallback in case API doesn't filter properly
        // (filtering client-side in case API doesn't support turul parameter)
        if (data['data'] != null && data['data'] is List) {
          final filteredData = (data['data'] as List).where((item) {
            final turul = item['turul']?.toString().toLowerCase() ?? '';
            // Accept "app" type, "мэдэгдэл" (notification), and "khariu" (reply) notifications
            final matchesTurul =
                turul == 'app' ||
                turul == 'мэдэгдэл' ||
                turul == 'medegdel' ||
                turul == 'khariu' ||
                turul == 'хариу' ||
                turul == 'hariu';

            // Also filter by userId as fallback (in case API doesn't filter properly)
            // Allow notifications with null/empty orshinSuugchId (general/broadcast notifications)
            // and also show notifications specifically for the current user
            if (userId != null && userId.isNotEmpty) {
              final itemUserId = item['orshinSuugchId']?.toString() ?? '';
              // Show if: matches turul AND (no specific recipient OR recipient matches current user)
              return matchesTurul &&
                  (itemUserId.isEmpty || itemUserId == userId);
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

  /// Submit complaint or suggestion (Гомдол or Санал).
  /// Optional [imageFile] is uploaded as "zurag" (multipart); backend stores under public/medegdel/.
  /// Uses XFile for web support (Image.file not supported on web).
  static Future<Map<String, dynamic>> submitGomdolSanal({
    required String title,
    required String message,
    required String turul, // "gomdol" or "sanal"
    XFile? imageFile,
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

      final authHeaders = await getAuthHeaders();
      final headers = <String, String>{
        if (authHeaders['Authorization'] != null)
          'Authorization': authHeaders['Authorization']!,
      };

      final medeelel = json.encode({'title': title, 'body': message});
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/medegdelIlgeeye'),
      );
      request.headers.addAll(headers);
      request.fields['medeelel'] = medeelel;
      request.fields['orshinSuugchId'] = userId;
      request.fields['baiguullagiinId'] = baiguullagiinId;
      request.fields['tukhainBaaziinKholbolt'] = tukhainBaaziinKholbolt;
      request.fields['turul'] = turulLower;
      if (barilgiinId != null && barilgiinId.isNotEmpty) {
        request.fields['barilgiinId'] = barilgiinId;
      }
      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        if (bytes.isNotEmpty) {
          // Compress image to avoid 413; compressWithList works on web (Image.file not supported)
          final compressed = await FlutterImageCompress.compressWithList(
            bytes,
            minWidth: 1280,
            minHeight: 1280,
            quality: 80,
            format: CompressFormat.jpeg,
          );
          if (compressed.isNotEmpty) {
            request.files.add(
              http.MultipartFile.fromBytes(
                'zurag',
                compressed,
                filename: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
              ),
            );
          }
        }
      }

      print('=== Submitting ${turul} ===');
      print('Endpoint: /medegdelIlgeeye');
      print('With image: ${imageFile != null}');

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);


      if (response.statusCode == 200 || response.statusCode == 201) {
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
        } catch (_) {}
        return {
          'success': true,
          'message': turulLower == 'gomdol'
              ? 'Гомдол амжилттай илгээгдлээ'
              : 'Санал амжилттай илгээгдлээ',
        };
      } else {
        String errorMessage =
            '${turulLower == 'gomdol' ? 'Гомдол' : 'Санал'} илгээхэд алдаа гарлаа: ${response.statusCode}';
        try {
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
            if (errorMessage.contains('Firebase token') ||
                errorMessage.contains('firebaseToken')) {
              errorMessage =
                  'Мэдэгдэл илгээхэд алдаа гарлаа. Системийн тохиргоо шаардлагатай.';
            }
          }
        } catch (_) {
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

  /// Mark notification/thread as seen (PATCH /medegdel/:id/kharsanEsekh). Marks root + all replies in thread.
  static Future<Map<String, dynamic>> markMedegdelAsRead(
    String medegdelId,
  ) async {
    try {
      final baiguullagiinId = await StorageService.getBaiguullagiinId();

      if (baiguullagiinId == null) {
        throw Exception('Хэрэглэгчийн мэдээлэл олдсонгүй');
      }

      final headers = await getAuthHeaders();
      final requestHeaders = Map<String, String>.from(headers);
      requestHeaders['Content-Type'] = 'application/json';

      final uri = Uri.parse(
        '$baseUrl/medegdel/$medegdelId/kharsanEsekh',
      ).replace(queryParameters: {'baiguullagiinId': baiguullagiinId});

      final response = await http.patch(
        uri,
        headers: requestHeaders,
        body: json.encode({}),
      );

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);
          if (responseData['success'] == true ||
              (responseData['data'] != null &&
                  responseData['data']['kharsanEsekh'] == true)) {
            return responseData;
          }
          return {'success': true, 'data': responseData};
        } catch (e) {
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

  /// Get full thread (root + all replies) for chat view. [medegdelIdOrRootId] can be root or any reply in thread.
  static Future<Map<String, dynamic>> getMedegdelThread(
    String medegdelIdOrRootId,
  ) async {
    try {
      final baiguullagiinId = await StorageService.getBaiguullagiinId();
      final tukhainBaaziinKholbolt =
          await StorageService.getTukhainBaaziinKholbolt();
      if (baiguullagiinId == null || tukhainBaaziinKholbolt == null) {
        throw Exception('Хэрэглэгчийн мэдээлэл олдсонгүй');
      }
      final headers = await getAuthHeaders();
      final uri = Uri.parse('$baseUrl/medegdel/thread/$medegdelIdOrRootId')
          .replace(
            queryParameters: {
              'baiguullagiinId': baiguullagiinId,
              'tukhainBaaziinKholbolt': tukhainBaaziinKholbolt,
            },
          );
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      String msg = 'Thread татахад алдаа: ${response.statusCode}';
      try {
        final err = json.decode(response.body);
        if (err['message'] != null) msg = err['message'].toString();
      } catch (_) {}
      throw Exception(msg);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Thread татахад алдаа: $e');
    }
  }

  /// Upload chat file from bytes (use for web or XFile). Returns path (e.g. baiguullagiinId/chat-xxx.jpg).
  static Future<String> uploadMedegdelChatFileWithBytes(
    Uint8List bytes,
    String filename,
  ) async {
    final baiguullagiinId = await StorageService.getBaiguullagiinId();
    if (baiguullagiinId == null) {
      throw Exception('Хэрэглэгчийн мэдээлэл олдсонгүй');
    }
    final safeName = filename.trim().isEmpty
        ? 'image.jpg'
        : filename.split(RegExp(r'[/\\]')).last;
    final authHeaders = await getAuthHeaders();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/medegdel/uploadChatFile'),
    );
    request.headers.addAll({
      if (authHeaders['Authorization'] != null)
        'Authorization': authHeaders['Authorization']!,
    });
    request.fields['baiguullagiinId'] = baiguullagiinId;
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: safeName),
    );
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      final path = data['path']?.toString();
      if (path != null && path.isNotEmpty) return path;
    }
    String msg = 'Файл илгээхэд алдаа: ${response.statusCode}';
    try {
      final err = json.decode(response.body);
      if (err['message'] != null) msg = err['message'].toString();
    } catch (_) {}
    throw Exception(msg);
  }

  /// Upload chat file (image or voice) for medegdel reply. Use on mobile only (dart:io File). On web use uploadMedegdelChatFileWithBytes with XFile.readAsBytes().
  static Future<String> uploadMedegdelChatFile({required File file}) async {
    final baiguullagiinId = await StorageService.getBaiguullagiinId();
    if (baiguullagiinId == null) {
      throw Exception('Хэрэглэгчийн мэдээлэл олдсонгүй');
    }
    print(
      '[ApiService] uploadMedegdelChatFile path=${file.path} exists=${file.existsSync()} size=${file.existsSync() ? file.lengthSync() : 0}',
    );
    final filename = file.path.split(RegExp(r'[/\\]')).last;
    if (filename.isEmpty || !file.existsSync()) {
      throw Exception('Файл олдсонгүй эсвэл нэр алга');
    }
    final bytes = await file.readAsBytes();
    return uploadMedegdelChatFileWithBytes(bytes, filename);
  }

  /// Send user reply in a notification thread (chat). At least one of message, zurag, or voiceUrl required.
  static Future<Map<String, dynamic>> sendMedegdelReply({
    required String rootMedegdelId,
    String message = '',
    String? zurag,
    String? voiceUrl,
  }) async {
    try {
      final baiguullagiinId = await StorageService.getBaiguullagiinId();
      final userId = await StorageService.getUserId();
      if (baiguullagiinId == null || userId == null) {
        throw Exception('Хэрэглэгчийн мэдээлэл олдсонгүй');
      }
      final hasMessage = message.trim().isNotEmpty;
      final hasZurag = zurag != null && zurag.trim().isNotEmpty;
      final hasVoice = voiceUrl != null && voiceUrl.trim().isNotEmpty;
      if (!hasMessage && !hasZurag && !hasVoice) {
        throw Exception('Хариу эсвэл зураг/дуу оруулна уу');
      }
      final headers = await getAuthHeaders();
      final requestHeaders = Map<String, String>.from(headers);
      requestHeaders['Content-Type'] = 'application/json';
      final body = <String, dynamic>{
        'parentId': rootMedegdelId,
        'message': message.trim(),
        'orshinSuugchId': userId,
        'baiguullagiinId': baiguullagiinId,
      };
      if (hasZurag) body['zurag'] = zurag!.trim();
      if (hasVoice) body['voiceUrl'] = voiceUrl!.trim();
      final response = await http.post(
        Uri.parse('$baseUrl/medegdel/reply'),
        headers: requestHeaders,
        body: json.encode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
      String msg = 'Хариу илгээхэд алдаа: ${response.statusCode}';
      try {
        final err = json.decode(response.body);
        if (err['message'] != null) msg = err['message'].toString();
      } catch (_) {}
      throw Exception(msg);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Хариу илгээхэд алдаа: $e');
    }
  }

  // ============================================
  // ZOCHIN URIKH (Guest Invitation) API Methods
  // ============================================

  /// Unified Guest Registration (Save & Link)
  static Future<Map<String, dynamic>> zochinHadgalya({
    required String mashiniiDugaar,
    required String baiguullagiinId,
    String? barilgiinId,
    required String ezemshigchiinUtas,
    Map<String, dynamic>? orshinSuugchMedeelel,
  }) async {
    try {
      final headers = await getAuthHeaders();
      final tukhainBaaziinKholbolt =
          await StorageService.getTukhainBaaziinKholbolt();
      final userId = await StorageService.getUserId();

      // Fetch profile and settings for a complete payload that matches EzenUrisanMashin schema
      final profile = await getUserProfile();
      final userData = profile['result'] ?? {};

      final quota = await fetchZochinQuotaStatus();
      Map<String, dynamic> quotaData;
      if (quota['total'] != null) {
        quotaData = quota;
      } else if (quota['data'] != null && quota['data'] is Map) {
        quotaData = Map<String, dynamic>.from(quota['data']);
      } else {
        quotaData = quota;
      }

      final requestBody = {
        'baiguullagiinId': baiguullagiinId,
        'barilgiinId': barilgiinId,
        'ezemshigchiinId': userId ?? "",
        'ezemshigchiinNer': "${userData['ovog'] ?? ''} ${userData['ner'] ?? ''}"
            .trim(),
        'ezemshigchiinRegister':
            userData['registerNo'] ?? userData['register'] ?? "",
        'ezemshigchiinUtas': ezemshigchiinUtas,
        'urisanMashiniiDugaar': mashiniiDugaar, // Key field requested by user
        'davtamjiinTurul': quotaData['period'] ?? "saraar",
        'zochinErkhiinToo':
            quotaData['total'] ?? quotaData['zochinErkhiinToo'] ?? 0,
        'tusBurUneguiMinut':
            quotaData['freeMinutesPerGuest'] ??
            quotaData['zochinTusBurUneguiMinut'] ??
            0,
        'tuluv': 0,
        'tukhainBaaziinKholbolt': tukhainBaaziinKholbolt ?? "amarSukh",

        // Keep legacy fields for backward compatibility if needed by some older backend logic
        'mashiniiDugaar': mashiniiDugaar,
        'dugaar': mashiniiDugaar,
        'mashinuud': [mashiniiDugaar],
        if (orshinSuugchMedeelel != null)
          'orshinSuugchMedeelel': orshinSuugchMedeelel,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/ezenUrisanMashin'),
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = response.body.trim();
        if (responseBody == 'Amjilttai') {
          return {'success': true, 'message': 'Amjilttai'};
        }

        try {
          return json.decode(responseBody);
        } catch (e) {
          if (responseBody.isNotEmpty) {
            return {'success': true, 'message': responseBody};
          }
          return {'success': true};
        }
      } else {
        String message = 'Зочин хадгалахад алдаа гарлаа';
        try {
          final errorBody = json.decode(response.body);
          message = errorBody['message'] ?? errorBody['aldaa'] ?? message;
        } catch (_) {
          if (response.statusCode == 403) {
            message = 'Зочин урих эрх дууссан байна';
          } else {
            message = '$message: ${response.statusCode}';
          }
        }
        throw Exception(message);
      }
    } catch (e) {
      print('Error saving guest: $e');
      throw Exception('Зочин хадгалахад алдаа гарлаа: $e');
    }
  }

  /// Unified Guest Invitation method using the correct EzenUrisanMashin schema
  static Future<Map<String, dynamic>> inviteGuest({
    required String urisanMashiniiDugaar,
    required String baiguullagiinId,
    String? barilgiinId,
    required String ezenId,
  }) async {
    try {
      final headers = await getAuthHeaders();
      final tukhainBaaziinKholbolt =
          await StorageService.getTukhainBaaziinKholbolt();

      // Fetch profile to get inviter details
      final profile = await getUserProfile();
      final userData = profile['result'] ?? {};

      // Fetch quota to get current settings
      final quota = await fetchZochinQuotaStatus();
      Map<String, dynamic> quotaData;
      if (quota['total'] != null) {
        quotaData = quota;
      } else if (quota['data'] != null && quota['data'] is Map) {
        quotaData = Map<String, dynamic>.from(quota['data']);
      } else if (quota['result'] != null && quota['result'] is Map) {
        quotaData = Map<String, dynamic>.from(quota['result']);
      } else {
        quotaData = quota;
      }

      final requestBody = {
        "baiguullagiinId": baiguullagiinId,
        "barilgiinId": barilgiinId,
        "ezemshigchiinId": ezenId,
        "ezemshigchiinNer": "${userData['ovog'] ?? ''} ${userData['ner'] ?? ''}"
            .trim(),
        "ezemshigchiinRegister":
            userData['registerNo'] ?? userData['register'] ?? "",
        "ezemshigchiinUtas": userData['utas']?.toString() ?? "",
        "urisanMashiniiDugaar": urisanMashiniiDugaar,
        "davtamjiinTurul":
            quotaData['period'] ?? quotaData['davtamjiinTurul'] ?? "saraar",
        "zochinErkhiinToo":
            quotaData['total'] ?? quotaData['zochinErkhiinToo'] ?? 0,
        "tusBurUneguiMinut":
            quotaData['freeMinutesPerGuest'] ??
            quotaData['zochinTusBurUneguiMinut'] ??
            0,
        "tuluv": 0,
        "tukhainBaaziinKholbolt": tukhainBaaziinKholbolt ?? "amarSukh",
      };

      print('🚗 [INVITE] Pattern implementation: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl/ezenUrisanMashin'),
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = response.body.trim();
        if (responseBody == 'Amjilttai' || responseBody == 'Success') {
          return {'success': true, 'message': 'Amjilttai'};
        }

        try {
          final decoded = json.decode(responseBody);
          if (decoded is Map<String, dynamic>) {
            return decoded;
          }
          return {'success': true, 'data': decoded};
        } catch (e) {
          if (responseBody.isNotEmpty) {
            return {'success': true, 'message': responseBody};
          }
          return {'success': true};
        }
      } else {
        String message = 'Зочин урихад алдаа гарлаа';
        try {
          final errorBody = json.decode(response.body);
          message =
              errorBody['message'] ??
              errorBody['aldaa'] ??
              errorBody['error'] ??
              message;
        } catch (_) {
          if (response.statusCode == 403) {
            message = 'Зочин урих эрх дууссан байна';
          } else {
            message = '$message: ${response.statusCode}';
          }
        }
        throw Exception(message);
      }
    } catch (e) {
      print('Error inviting guest: $e');
      rethrow;
    }
  }

  /// Fetch invited guests history
  static Future<Map<String, dynamic>> fetchZochinTuukh({
    required String baiguullagiinId,
    required String ezenId,
  }) async {
    try {
      final headers = await getAuthHeaders();
      final tukhainBaaziinKholbolt =
          await StorageService.getTukhainBaaziinKholbolt();

      final requestBody = {
        'baiguullagiinId': baiguullagiinId,
        'ezenId': ezenId,
        'tukhainBaaziinKholbolt': tukhainBaaziinKholbolt,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/ezenUrisanTuukh'),
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Зочны түүх татахад алдаа гарлаа: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching guest history: $e');
      throw Exception('Зочны түүх татахад алдаа гарлаа: $e');
    }
  }

  /// Delete/Cancel guest invitation
  static Future<Map<String, dynamic>> deleteZochinInvitation({
    required String id,
    required String baiguullagiinId,
  }) async {
    try {
      final headers = await getAuthHeaders();
      final tukhainBaaziinKholbolt =
          await StorageService.getTukhainBaaziinKholbolt();

      final response = await http.delete(
        Uri.parse('$baseUrl/ezenUrisanMashin/$id'),
        headers: headers,
        body: json.encode({
          'baiguullagiinId': baiguullagiinId,
          'tukhainBaaziinKholbolt': tukhainBaaziinKholbolt,
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = response.body.trim();
        if (responseBody == 'Amjilttai') {
          return {'success': true, 'message': 'Amjilttai'};
        }

        try {
          return json.decode(responseBody);
        } catch (e) {
          if (responseBody.isNotEmpty) {
            return {'success': true, 'message': responseBody};
          }
          return {'success': true};
        }
      } else {
        String message = 'Урилга цуцлахад алдаа гарлаа';
        try {
          final errorBody = json.decode(response.body);
          message = errorBody['message'] ?? errorBody['aldaa'] ?? message;
        } catch (_) {}
        throw Exception(message);
      }
    } catch (e) {
      print('Error deleting guest invitation: $e');
      throw Exception('Урилга цуцлахад алдаа гарлаа: $e');
    }
  }

  /// GET Resident Settings
  static Future<Map<String, dynamic>> fetchZochinSettings() async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/zochinSettings'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Тохиргоо авахад алдаа гарлаа: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Тохиргоо авахад алдаа гарлаа: $e');
    }
  }

  /// GET Quota Status
  static Future<Map<String, dynamic>> fetchZochinQuotaStatus() async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/zochinQuotaStatus'),
        headers: headers,
      );

      final responseBody = response.body.trim();
      if (response.statusCode == 200) {
        try {
          return json.decode(responseBody);
        } catch (e) {
          // If not JSON but 200, it's likely a plain text message
          return {'success': true, 'message': responseBody};
        }
      } else {
        throw Exception('Квот шалгахад алдаа гарлаа: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching quota status: $e');
      throw Exception('Квот шалгахад алдаа гарлаа: $e');
    }
  }
}
