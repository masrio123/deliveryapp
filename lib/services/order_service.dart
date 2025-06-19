import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constant/constant.dart'; // Pastikan path ini benar
import '../models/order.dart'; // Pastikan path ini benar

class OrderService {
  // --- Fungsi Bantuan Internal ---
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<String?> getPorterId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('porter_id');
  }

  // --- Fungsi Utama untuk Mengambil Data ---

  // Mengambil daftar pesanan yang sedang aktif
  static Future<List<Order>> fetchActiveOrder() async {
    try {
      final token = await getToken();
      final porterId = await getPorterId();
      if (token == null || porterId == null) {
        throw Exception('Token atau Porter ID tidak ditemukan.');
      }

      // --- PERBAIKAN: Mengembalikan method ke POST ---
      final response = await http.post(
        Uri.parse('$baseURL/porters/$porterId/accepted-orders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] is List) {
          final List<dynamic> data = responseData['data'];
          return data.map((json) => Order.fromJson(json)).toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Gagal mengambil order aktif: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [ERROR] fetchActiveOrder exception: $e');
      rethrow;
    }
  }

  // Mengambil summary pekerjaan (total order & income)
  static Future<WorkSummary> fetchWorkSummary() async {
    try {
      final token = await getToken();
      final porterId = await getPorterId();
      if (token == null || porterId == null) {
        throw Exception('Token atau Porter ID tidak ditemukan.');
      }

      // --- PERBAIKAN: Mengembalikan method ke POST dan memperbaiki URL ---
      final response = await http.post(
        Uri.parse(
          '$baseURL/porters/$porterId/workSummary',
        ), // URL disesuaikan dengan kode lama Anda
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] is Map) {
          return WorkSummary.fromJson(responseData['data']);
        } else {
          return WorkSummary(total_orders_handled: 0, total_income: 0);
        }
      } else {
        throw Exception('Gagal mengambil summary: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [ERROR] fetchWorkSummary exception: $e');
      return WorkSummary(total_orders_handled: 0, total_income: 0);
    }
  }

  // --- Fungsi Aksi Order ---

  static Future<String> _postOrderAction(int orderId, String action) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Token tidak ditemukan.');

      final uri = Uri.parse('$baseURL/porters/$orderId/$action');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      if (response.statusCode == 200 && responseData['success'] == true) {
        return responseData['message'] ?? 'Aksi berhasil.';
      } else {
        throw Exception(responseData['message'] ?? 'Gagal melakukan aksi.');
      }
    } catch (e) {
      print('❌ [ERROR] _postOrderAction ($action) exception: $e');
      rethrow;
    }
  }

  static Future<String> acceptOrder(int orderId) async {
    return _postOrderAction(orderId, 'accept');
  }

  static Future<String> rejectOrder(int orderId) async {
    return _postOrderAction(orderId, 'reject');
  }

  static Future<List<Order>> fetchActivity() async {
    try {
      final token = await getToken();
      final porterId = await getPorterId();

      if (token == null || porterId == null) {
        throw Exception(
          'Token atau Porter ID tidak ditemukan. Harap login kembali.',
        );
      }

      final response = await http.post(
        Uri.parse('$baseURL/porters/$porterId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print(
          '📨 [DEBUG] Response body for fetchActiveOrder: ${response.body}',
        );
        try {
          final Map<String, dynamic> responseData = jsonDecode(response.body);

          if (responseData['success'] != true) {
            throw Exception(
              'Status success bernilai false: ${responseData['message'] ?? 'Pesan tidak diketahui'}',
            );
          }

          if (responseData['data'] == null || responseData['data'] is! List) {
            throw Exception('Data tidak ditemukan atau bukan List');
          }

          final List<dynamic> data = responseData['data'];

          return data.map((json) => Order.fromJson(json)).toList();
        } catch (e) {
          print('❌ [DEBUG] Gagal parsing JSON di fetchActiveOrder: $e');
          throw Exception('Gagal memproses data dari server');
        }
      } else {
        print(
          '❌ [DEBUG] Status bukan 200 di fetchActiveOrder: ${response.statusCode}',
        );
        print('📨 [DEBUG] Response body di fetchActiveOrder: ${response.body}');
        throw Exception('Gagal mengambil data: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [ERROR] fetchActiveOrder exception: $e');
      rethrow; // Melemparkan kembali exception agar bisa ditangkap di UI/caller
    }
  }

  static Future<String> deliverOrder(int orderId) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Token tidak ditemukan.');

      final uri = Uri.parse('$baseURL/porters/$orderId/deliver');
      final response = await http.put(
        // Menggunakan PUT
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      if (response.statusCode == 200 && responseData['success'] == true) {
        return responseData['message'] ?? 'Aksi berhasil.';
      } else {
        throw Exception(responseData['message'] ?? 'Gagal melakukan aksi.');
      }
    } catch (e) {
      print('❌ [ERROR] deliverOrder exception: $e');
      rethrow;
    }
  }

  static Future<String> finishOrder(int orderId) async {
    return _postOrderAction(orderId, 'finish');
  }
}
