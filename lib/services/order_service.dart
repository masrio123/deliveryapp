import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constant/constant.dart';
import '../models/order.dart'; // Pastikan model Order sudah didefinisikan dengan benar

class OrderService {
  // Mengambil token dari SharedPreferences
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Mengambil porter ID dari SharedPreferences
  static Future<String?> getPorterId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('porter_id');
  }

  // Fungsi untuk mengambil daftar pesanan aktif
  static Future<List<Order>> fetchActiveOrder() async {
    try {
      final token = await getToken();
      final porterId = await getPorterId();

      if (token == null || porterId == null) {
        throw Exception(
          'Token atau Porter ID tidak ditemukan. Harap login kembali.',
        );
      }

      final response = await http.post(
        Uri.parse('$baseURL/porters/$porterId/accepted-orders'),
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

  // Fungsi untuk menerima pesanan
  static Future<String> acceptOrder(int orderId) async {
    print("orderid: $orderId");

    try {
      final token = await getToken();
      final porterId = await getPorterId();

      if (token == null || porterId == null) {
        throw Exception(
          'Token atau Porter ID tidak ditemukan. Harap login kembali.',
        );
      }

      final uri = Uri.parse('$baseURL/porters/$orderId/accept');
      print('🌐 [DEBUG] Mengirim permintaan ke: $uri');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type':
              'application/json', // Penting untuk mengirim body JSON
        },
        body: jsonEncode({
          'order_id': orderId, // Mengirim order_id di body permintaan
        }),
      );

      if (response.statusCode == 200) {
        print('📨 [DEBUG] Response body for acceptOrder: ${response.body}');
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          return responseData['message'] ?? 'Pesanan berhasil diterima.';
        } else {
          throw Exception(responseData['message'] ?? 'Gagal menerima pesanan.');
        }
      } else {
        print(
          '❌ [DEBUG] Status bukan 200 di acceptOrder: ${response.statusCode}',
        );
        print('📨 [DEBUG] Response body di acceptOrder: ${response.body}');
        throw Exception(
          'Gagal menerima pesanan: ${response.statusCode}. ${response.body}',
        );
      }
    } catch (e) {
      print('❌ [ERROR] acceptOrder exception: $e');
      rethrow;
    }
  }

  // --- Fungsi baru untuk menolak pesanan ---
  static Future<String> rejectOrder(int orderId) async {
    try {
      final token = await getToken();
      final porterId = await getPorterId();

      if (token == null || porterId == null) {
        throw Exception(
          'Token atau Porter ID tidak ditemukan. Harap login kembali.',
        );
      }

      final uri = Uri.parse('$baseURL/porters/$orderId/reject');
      print('🌐 [DEBUG] Mengirim permintaan ke: $uri');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type':
              'application/json', // Penting untuk mengirim body JSON
        },
        body: jsonEncode({
          'order_id': orderId, // Mengirim order_id di body permintaan
        }),
      );

      if (response.statusCode == 200) {
        print('📨 [DEBUG] Response body for rejectOrder: ${response.body}');
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          // Mengembalikan pesan dari API, termasuk peringatan jika ada
          String message =
              responseData['message'] ?? 'Pesanan berhasil ditolak.';
          if (responseData['peringatan'] != null) {
            message += ' ' + responseData['peringatan'];
          }
          return message;
        } else {
          // Jika success bernilai false, kembalikan pesan error dari API
          throw Exception(responseData['message'] ?? 'Gagal menolak pesanan.');
        }
      } else {
        // Jika status code bukan 200, log error dan lemparkan exception
        print(
          '❌ [DEBUG] Status bukan 200 di rejectOrder: ${response.statusCode}',
        );
        print('📨 [DEBUG] Response body di rejectOrder: ${response.body}');
        throw Exception(
          'Gagal menolak pesanan: ${response.statusCode}. ${response.body}',
        );
      }
    } catch (e) {
      print('❌ [ERROR] rejectOrder exception: $e');
      rethrow; // Melemparkan kembali exception untuk penanganan lebih lanjut
    }
  }

  static Future<String> deliverOrder(int orderId) async {
    try {
      final token = await getToken();
      final porterId =
          await getPorterId(); // Bisa diabaikan jika tidak dipakai di backend

      if (token == null || porterId == null) {
        throw Exception(
          'Token atau Porter ID tidak ditemukan. Harap login kembali.',
        );
      }

      final uri = Uri.parse('$baseURL/porters/$orderId/deliver');
      print('🌐 [DEBUG] Mengirim permintaan DELIVER ke: $uri');

      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'order_id': orderId, // bisa dihapus jika tidak dibutuhkan oleh API
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return responseData['message'] ?? 'Pesanan sedang diantar.';
        } else {
          throw Exception(
            responseData['message'] ?? 'Gagal mengantar pesanan.',
          );
        }
      } else {
        print(
          '❌ [DEBUG] Status bukan 200 di deliverOrder: ${response.statusCode}',
        );
        print('📨 [DEBUG] Response body: ${response.body}');
        throw Exception('Gagal mengantar pesanan: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [ERROR] deliverOrder exception: $e');
      rethrow;
    }
  }

  static Future<String> finishOrder(int orderId) async {
    print("order id untuk di finish $orderId");
    try {
      final token = await getToken();
      final porterId =
          await getPorterId(); // Bisa diabaikan jika tidak dipakai di backend

      if (token == null || porterId == null) {
        throw Exception(
          'Token atau Porter ID tidak ditemukan. Harap login kembali.',
        );
      }

      final uri = Uri.parse('$baseURL/porters/$orderId/finish');
      print('🌐 [DEBUG] Mengirim permintaan FINISH ke: $uri');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'order_id': orderId, // Bisa dihapus jika backend tidak memerlukannya
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return responseData['message'] ?? 'Pesanan telah selesai.';
        } else {
          throw Exception(
            responseData['message'] ?? 'Gagal menyelesaikan pesanan.',
          );
        }
      } else {
        print(
          '❌ [DEBUG] Status bukan 200 di finishOrder: ${response.statusCode}',
        );
        print('📨 [DEBUG] Response body: ${response.body}');
        throw Exception('Gagal menyelesaikan pesanan: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [ERROR] finishOrder exception: $e');
      rethrow;
    }
  }

  static Future<WorkSummary> fetchWorkSummary() async {
    try {
      final token = await getToken();
      final porterId = await getPorterId();

      if (token == null || porterId == null) {
        throw Exception(
          'Token atau Porter ID tidak ditemukan. Harap login kembali.',
        );
      }

      final response = await http.post(
        Uri.parse('$baseURL/porters/$porterId/workSummary'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print(
          '📨 [DEBUG] Response body for fetchWorkSummary: ${response.body}',
        );
        try {
          final Map<String, dynamic> responseData = jsonDecode(response.body);

          if (responseData['success'] != true) {
            throw Exception(
              'Status success bernilai false: ${responseData['message'] ?? 'Pesan tidak diketahui'}',
            );
          }

          if (responseData['data'] == null || responseData['data'] is! Map) {
            throw Exception('Data tidak ditemukan atau bukan objek');
          }

          final Map<String, dynamic> data = responseData['data'];

          return WorkSummary.fromJson(data);
        } catch (e) {
          print('❌ [DEBUG] Gagal parsing JSON di fetchWorkSummary: $e');
          throw Exception('Gagal memproses data dari server');
        }
      } else {
        print(
          '❌ [DEBUG] Status bukan 200 di fetchWorkSummary: ${response.statusCode}',
        );
        print('📨 [DEBUG] Response body di fetchWorkSummary: ${response.body}');
        throw Exception('Gagal mengambil data: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [ERROR] fetchWorkSummary exception: $e');
      rethrow;
    }
  }
}
