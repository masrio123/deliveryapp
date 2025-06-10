import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constant/constant.dart';
import '../models/order.dart';

class OrderService {
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<String?> getPorterId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('porter_id');
  }

  static Future<List<Order>> fetchActiveOrder() async {
    try {
      final token = await getToken();
      final porterId = await getPorterId();

      final response = await http.post(
        Uri.parse('$baseURL/porters/$porterId/accepted-orders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print('📨 [DEBUG] Response body: ${response.body}');
        try {
          final Map<String, dynamic> responseData = jsonDecode(response.body);

          if (responseData['success'] != true) {
            throw Exception('Status success bernilai false');
          }

          if (responseData['data'] == null || responseData['data'] is! List) {
            throw Exception('Data tidak ditemukan atau bukan List');
          }

          final List<dynamic> data = responseData['data'];

          return data.map((json) => Order.fromJson(json)).toList();
        } catch (e) {
          print('❌ [DEBUG] Gagal parsing JSON: $e');
          throw Exception('Gagal memproses data dari server');
        }
      } else {
        print('❌ [DEBUG] Status bukan 200: ${response.statusCode}');
        print('📨 [DEBUG] Response body: ${response.body}');
        throw Exception('Gagal mengambil data: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [ERROR] fetchActiveOrder exception: $e');
      throw Exception('Terjadi kesalahan saat mengambil data: $e');
    }
  }
}
