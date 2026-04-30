import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://signsync.de/api', // Deine Laravel-URL
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  ));

  final _storage = const FlutterSecureStorage();

  // Hilfsmethode für das Token
  Future<Options> _getAuthOptions() async {
    String? token = await _storage.read(key: 'auth_token');
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  // Login
  Future<bool> login(String email, String password) async {
    try {
      final response = await _dio.post('/login', data: {
        'email': email,
        'password': password,
        'device_name': 'mobile_app',
      });
      if (response.statusCode == 200) {
        await _storage.write(key: 'auth_token', value: response.data['token']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // NEU: Zeiteintrag für Leistung erstellen
  Future<bool> createEntry({
    required String studentId,
    required String type,
    required String duration,
    required String description,
  }) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.post(
        '/timesheets', 
        data: {
          'student_id': studentId,
          'type': type,
          'duration': duration,
          'description': description,
        },
        options: options,
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("Fehler beim Speichern: $e");
      return false;
    }
  }
}