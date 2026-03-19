import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sukh_app/models/blog_model.dart';
import 'package:sukh_app/services/api_service.dart';

class BlogService {
  static Future<List<BlogModel>> getBlogs(String baiguullagiinId) async {
    try {
      final headers = await ApiService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/blog?baiguullagiinId=$baiguullagiinId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final blogResponse = BlogResponse.fromJson(data);
        return blogResponse.data;
      } else {
        throw Exception('Мэдээлэл татахад алдаа гарлаа: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Мэдээлэл татахад алдаа гарлаа: $e');
    }
  }

  static Future<BlogModel> toggleReaction({
    required String blogId,
    required String baiguullagiinId,
    required String emoji,
    required String orshinSuugchId,
  }) async {
    try {
      final headers = await ApiService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/blog/$blogId/reaction'),
        headers: headers,
        body: json.encode({
          'baiguullagiinId': baiguullagiinId,
          'emoji': emoji,
          'userId': orshinSuugchId,
          'orshinSuugchId': orshinSuugchId,
          'orshinSuugchiinId': orshinSuugchId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true || data['responseCode'] == true) {
          final responseData = data['data'] ?? data['result'] ?? data['blog'];
          if (responseData != null) {
            return BlogModel.fromJson(responseData);
          } else {
            throw Exception('Өгөгдөл шинэчлэгдсэнгүй');
          }
        } else {
          throw Exception(data['message'] ?? 'Нөлөөлөл бүртгэхэд алдаа гарлаа');
        }
      } else {
        throw Exception('Нөлөөлөл бүртгэхэд алдаа гарлаа: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('Өгөгдөл шинэчлэгдсэнгүй')) {
        rethrow;
      }
      throw Exception('Нөлөөлөл бүртгэхэд алдаа гарлаа: $e');
    }
  }
}
