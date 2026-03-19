import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/services/socket_service.dart';
import 'package:sukh_app/models/geree_model.dart';
import 'package:sukh_app/utils/nekhemjlekh_merge_util.dart';
import 'package:sukh_app/models/medegdel_model.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';

class HomeDataLoader {
  static Future<List<Map<String, dynamic>>> loadBillers() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/billers'),
        headers: await ApiService.getWalletApiHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(
            data['data']?.map((item) => Map<String, dynamic>.from(item)) ?? [],
          );
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> loadBillingInfo() async {
    try {
      final bairId = await StorageService.getWalletBairId();
      final doorNo = await StorageService.getWalletDoorNo();

      if (bairId != null && doorNo != null) {
        final response = await http.get(
          Uri.parse('${ApiService.baseUrl}/wallet/billing/$bairId/$doorNo'),
          headers: await ApiService.getWalletApiHeaders(),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            return data['data'];
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> loadBillingPayments() async {
    try {
      final userData = await StorageService.getUserData();
      final billingList = await StorageService.getBillingList();

      double total = 0.0;
      double totalAldangi = 0.0;
      final List<Map<String, dynamic>> updatedBillingList = [];

      for (var billing in billingList) {
        double itemTotal = 0.0;
        double itemAldandi = 0.0;

        try {
          final response = await http.get(
            Uri.parse(
              '${ApiService.baseUrl}/wallet/billing/bills/${billing['billingId']}',
            ),
            headers: await ApiService.getWalletApiHeaders(),
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['success'] == true && data['data'] != null) {
              final bills = data['data']['bills'] ?? [];
              for (var bill in bills) {
                itemTotal += _parseNum(bill['billTotalAmount']);
                itemAldandi += _parseNum(bill['billAldangi']);
              }
            }
          }
        } catch (e) {
          // Handle error silently
        }

        item['perItemTotal'] = itemTotal;
        item['perItemAldangi'] = itemAldandi;
        updatedBillingList.add(item);

        total += itemTotal;
        totalAldangi += itemAldandi;
      }

      return updatedBillingList;
    } catch (e) {
      return [];
    }
  }

  static Future<GereeResponse?> loadGereeData() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/wallet/geree'),
        headers: await ApiService.getWalletApiHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return GereeResponse.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<int> loadNotificationCount() async {
    try {
      final userData = await StorageService.getUserData();
      final customerId = userData['walletCustomerId']?.toString();

      if (customerId != null) {
        final response = await http.get(
          Uri.parse(
            '${ApiService.baseUrl}/wallet/notifications/count/$customerId',
          ),
          headers: await ApiService.getWalletApiHeaders(),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true && data['data'] != null) {
            return data['data']['count'] ?? 0;
          }
        }
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  static double _parseNum(dynamic val) {
    if (val == null) return 0.0;
    if (val is int) return val.toDouble();
    if (val is double) return val;
    if (val is String) {
      final str = val.toString().replaceAll(',', '').trim();
      if (str.isEmpty) return 0.0;
      return double.tryParse(str) ?? 0.0;
    }
    return 0.0;
  }
}
