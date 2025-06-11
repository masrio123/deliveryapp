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

      final response = await http.get(
        Uri.parse('$baseURL/api/porters/profile/$porterId'),
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
}
