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

  // Check if response is successful (200, 201, 202)
  static bool _isSuccess(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    
    final data = jsonDecode(response.body);
    if (!_isSuccess(response.statusCode)) {
      throw Exception(data['message'] ?? data['error'] ?? 'Login failed');
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
    if (!_isSuccess(response.statusCode)) {
      throw Exception(data['message'] ?? data['error'] ?? 'Registration failed');
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
    if (!_isSuccess(response.statusCode)) {
      throw Exception(data['message'] ?? data['error'] ?? 'Failed to get profile');
    }
    return data;
  }

  static Future<List<dynamic>> getGenerations({String? type, int limit = 50}) async {
    final headers = await _getHeaders();
    var url = '$baseUrl/generations?limit=$limit';
    if (type != null) url += '&type=$type';
    
    final response = await http.get(Uri.parse(url), headers: headers);
    final data = jsonDecode(response.body);
    
    if (!_isSuccess(response.statusCode)) {
      throw Exception(data['message'] ?? data['error'] ?? 'Failed to get generations');
    }
    return data['generations'] ?? [];
  }

  // Generate Music
  static Future<Map<String, dynamic>> generateMusic({
    required String title,
    required String prompt,
    required String lyrics,
    String? style,
    String model = 'music-2.0',
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
        'model': model,
      }),
    );
    
    final data = jsonDecode(response.body);
    // 202 Accepted = generation started (success!)
    if (!_isSuccess(response.statusCode)) {
      throw Exception(data['message'] ?? data['error'] ?? 'Failed to generate music');
    }
    return data;
  }

  // Generate Voice/TTS
  static Future<Map<String, dynamic>> generateVoice({
    required String text,
    required String title,
    String voiceId = 'male-qn-qingse',
    double speed = 1.0,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/voice/generate'),
      headers: headers,
      body: jsonEncode({
        'text': text,
        'title': title,
        'voice_id': voiceId,
        'speed': speed,
      }),
    );
    
    final data = jsonDecode(response.body);
    if (!_isSuccess(response.statusCode)) {
      throw Exception(data['message'] ?? data['error'] ?? 'Failed to generate voice');
    }
    return data;
  }

  // Generate Video
  static Future<Map<String, dynamic>> generateVideo({
    required String prompt,
    required String title,
    int duration = 5,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/video/generate'),
      headers: headers,
      body: jsonEncode({
        'prompt': prompt,
        'title': title,
        'duration': duration,
      }),
    );
    
    final data = jsonDecode(response.body);
    if (!_isSuccess(response.statusCode)) {
      throw Exception(data['message'] ?? data['error'] ?? 'Failed to generate video');
    }
    return data;
  }

  // Generate Image (Album Art)
  static Future<Map<String, dynamic>> generateImage({
    required String prompt,
    required String title,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/image/generate'),
      headers: headers,
      body: jsonEncode({
        'prompt': prompt,
        'title': title,
      }),
    );
    
    final data = jsonDecode(response.body);
    if (!_isSuccess(response.statusCode)) {
      throw Exception(data['message'] ?? data['error'] ?? 'Failed to generate image');
    }
    return data;
  }

  // Toggle Favorite
  static Future<void> toggleFavorite(int id) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/generations/$id/favorite'),
      headers: headers,
    );
    
    if (!_isSuccess(response.statusCode)) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to toggle favorite');
    }
  }

  // Delete Generation
  static Future<void> deleteGeneration(int id) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/generations/$id'),
      headers: headers,
    );
    
    if (!_isSuccess(response.statusCode)) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to delete');
    }
  }

  // Get Single Generation
  static Future<Map<String, dynamic>> getGeneration(int id) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/generations/$id'),
      headers: headers,
    );
    
    final data = jsonDecode(response.body);
    if (!_isSuccess(response.statusCode)) {
      throw Exception(data['message'] ?? 'Failed to get generation');
    }
    return data;
  }

  // Update Profile
  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? avatar,
  }) async {
    final headers = await _getHeaders();
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (avatar != null) body['avatar'] = avatar;
    
    final response = await http.put(
      Uri.parse('$baseUrl/profile'),
      headers: headers,
      body: jsonEncode(body),
    );
    
    final data = jsonDecode(response.body);
    if (!_isSuccess(response.statusCode)) {
      throw Exception(data['message'] ?? 'Failed to update profile');
    }
    return data;
  }

  // Change Password
  static Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/auth/change-password'),
      headers: headers,
      body: jsonEncode({
        'old_password': oldPassword,
        'new_password': newPassword,
      }),
    );
    
    if (!_isSuccess(response.statusCode)) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to change password');
    }
  }

  // Toggle Public/Private
  static Future<Map<String, dynamic>> togglePublic(int id) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/generations/$id/public'),
      headers: headers,
    );
    
    final data = jsonDecode(response.body);
    if (!_isSuccess(response.statusCode)) {
      throw Exception(data['message'] ?? 'Failed to toggle public');
    }
    return data;
  }

  // Get Public/Explore Generations (no auth required)
  static Future<List<dynamic>> getExplore({String? type, int limit = 50, int page = 1}) async {
    var url = '$baseUrl/explore?limit=$limit&page=$page';
    if (type != null) url += '&type=$type';
    
    final response = await http.get(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );
    
    final data = jsonDecode(response.body);
    if (!_isSuccess(response.statusCode)) {
      throw Exception(data['message'] ?? 'Failed to get explore');
    }
    return data['generations'] ?? [];
  }
}
