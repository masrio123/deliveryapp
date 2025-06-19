import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constant/constant.dart';
import '../models/profile.dart';

class PorterService {
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<String?> getPorterId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('porter_id');
  }

  static Future<PorterProfile> fetchPorterProfile() async {
    try {
      final token = await getToken();
      final porterId = await getPorterId();

      if (token == null || porterId == null) {
        throw Exception('Token atau Porter ID tidak ditemukan.');
      }

      // Pastikan URL Anda benar. Dari kode Laravel, seharusnya tidak ada 'profile' di URL.
      final response = await http.post(
        Uri.parse(
          '$baseURL/porters/profile/$porterId',
        ), // Sesuaikan jika URL berbeda
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print(
          '📨 [DEBUG] Response body for fetchPorterProfile: ${response.body}',
        );

        // --- PERBAIKAN UTAMA DI SINI ---
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Cek dulu apakah 'success' adalah true dan 'data' ada
        if (responseData['success'] == true && responseData['data'] != null) {
          // Kirim HANYA bagian 'data' ke FromJson
          return PorterProfile.fromJson(responseData['data']);
        } else {
          throw Exception(
            responseData['message'] ?? 'Gagal memuat data profil.',
          );
        }
      } else {
        print('❌ [DEBUG] Gagal fetchPorterProfile: ${response.statusCode}');
        throw Exception(
          'Gagal mengambil profil porter: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ [ERROR] fetchPorterProfile exception: $e');
      rethrow;
    }
  }

  /// GET: Mengambil status isOnline porter
  static Future<PorterStatus> getPorterOnlineStatus() async {
    try {
      final token = await getToken();
      final porterId = await getPorterId();

      if (token == null || porterId == null) {
        throw Exception('Token atau Porter ID tidak ditemukan.');
      }

      final response = await http.post(
        Uri.parse('$baseURL/porter/$porterId/toggle-is-open'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        return PorterStatus.fromJson(json['data']);
      } else {
        throw Exception('Gagal mengambil status online porter.');
      }
    } catch (e) {
      print('❌ [ERROR] getPorterOnlineStatus: $e');
      rethrow;
    }
  }

  /// PUT: Mengupdate status isOnline porter
  static Future<bool> updatePorterOnlineStatus(bool isOnline) async {
    try {
      final token = await getToken();
      final porterId = await getPorterId();

      if (token == null || porterId == null) {
        throw Exception('Token atau Porter ID tidak ditemukan.');
      }

      final response = await http.put(
        Uri.parse('$baseURL/porter/$porterId/toggle-is-open'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'porter_isOnline': isOnline}),
      );

      if (response.statusCode == 200) {
        print('✅ [DEBUG] Status porter diperbarui.');
        return true;
      } else {
        print('❌ [DEBUG] Gagal update status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ [ERROR] updatePorterOnlineStatus: $e');
      return false;
    }
  }
}
