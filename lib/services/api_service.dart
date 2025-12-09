import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://luminaai.zesbe.my.id/api/v1';
  
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<void> setTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    
    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Login failed');
    }
    return data;
  }

  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    
    final data = jsonDecode(response.body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(data['message'] ?? 'Registration failed');
    }
    return data;
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: headers,
    );
    
    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to get profile');
    }
    return data;
  }

  static Future<List<dynamic>> getGenerations({String? type, int limit = 50}) async {
    final headers = await _getHeaders();
    var url = '$baseUrl/generations?limit=$limit';
    if (type != null) url += '&type=$type';
    
    final response = await http.get(Uri.parse(url), headers: headers);
    final data = jsonDecode(response.body);
    
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to get generations');
    }
    return data['generations'] ?? [];
  }

  static Future<Map<String, dynamic>> generateMusic({
    required String title,
    required String prompt,
    required String lyrics,
    String? style,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/music/generate'),
      headers: headers,
      body: jsonEncode({
        'title': title,
        'prompt': prompt,
        'lyrics': lyrics,
        'style': style,
      }),
    );
    
    final data = jsonDecode(response.body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(data['message'] ?? 'Failed to generate music');
    }
    return data;
  }

  static Future<void> toggleFavorite(int id) async {
    final headers = await _getHeaders();
    await http.post(
      Uri.parse('$baseUrl/generations/$id/favorite'),
      headers: headers,
    );
  }

  static Future<void> deleteGeneration(int id) async {
    final headers = await _getHeaders();
    await http.delete(
      Uri.parse('$baseUrl/generations/$id'),
      headers: headers,
    );
  }
}
