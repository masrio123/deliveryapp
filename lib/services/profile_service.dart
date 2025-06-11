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
        throw Exception(
          'Token atau Porter ID tidak ditemukan. Harap login kembali.',
        );
      }

      final response = await http.post(
        Uri.parse('$baseURL/porters/profile/$porterId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print(
          '📨 [DEBUG] Response body for fetchPorterProfile: ${response.body}',
        );
        final Map<String, dynamic> data = jsonDecode(response.body);
        return PorterProfile.fromJson(data);
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
