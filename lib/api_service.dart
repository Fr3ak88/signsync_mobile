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
        
        // NEU: Firmennamen aus der API-Antwort speichern
        // Ich nehme an, Laravel sendet { "token": "...", "user": { "company_name": "Firma XY" } }
        final companyName = response.data['user']['company_name'] ?? 'Meine Firma';
        await _storage.write(key: 'company_name', value: companyName);
        
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
  // --- TIMER LOGIK ---
  DateTime? externalStartTime;
  bool isTimerRunning = false;

  // Diese Methode beim App-Start aufrufen, um laufende Timer wiederherzustellen
  Future<void> recoverTimer() async {
    String? storedStart = await _storage.read(key: 'timer_start_time');
    if (storedStart != null) {
      externalStartTime = DateTime.parse(storedStart);
      isTimerRunning = true;
    }
  }

  Future<void> startGlobalTimer() async {
    externalStartTime = DateTime.now();
    isTimerRunning = true;
    // Zeitstempel dauerhaft speichern
    await _storage.write(key: 'timer_start_time', value: externalStartTime!.toIso8601String());
  }

  Future<void> stopGlobalTimer() async {
    isTimerRunning = false;
    externalStartTime = null;
    // Speicher löschen
    await _storage.delete(key: 'timer_start_time');
  }

  Duration get currentDuration {
    if (externalStartTime == null) return Duration.zero;
    return DateTime.now().difference(externalStartTime!);
  }
}
