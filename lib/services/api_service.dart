import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://signsync.de/api', 
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  ));

  final _storage = const FlutterSecureStorage();

  // --- VARIABLEN FÜR TIMER ---
  DateTime? externalStartTime;
  bool isTimerRunning = false;

  // Hilfsmethode für das Token
  Future<Options> _getAuthOptions() async {
    String? token = await _storage.read(key: 'auth_token');
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  // Hilfsmethode für die User-ID
  Future<String> _getUserId() async {
    String? userDataString = await _storage.read(key: 'user_data');
    if (userDataString != null) {
      try {
        final Map<String, dynamic> userData = jsonDecode(userDataString);
        if (userData['id'] != null) {
          return userData['id'].toString();
        }
      } catch (e) {
        print("Fehler beim Lesen der User-ID: $e");
      }
    }
    return ""; // Fallback
  }

  // Hilfsmethode für das Laravel Datums-Format
  String _formatDate(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
           "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}";
  }

  // Holt die Liste aller zugewiesenen Schüler für das Dropdown
  Future<List<Map<String, dynamic>>> getAssignedStudents() async {
    String? userDataString = await _storage.read(key: 'user_data');
    if (userDataString != null) {
      try {
        final Map<String, dynamic> userData = jsonDecode(userDataString);
        if (userData['kinder'] != null) {
          return List<Map<String, dynamic>>.from(userData['kinder']);
        }
      } catch (e) {
        print("Fehler beim Parsen der Schülerliste: $e");
      }
    }
    return [];
  }

  // Beibehalten für Kompatibilität
  Future<String?> getMyStudentId() async {
    final students = await getAssignedStudents();
    if (students.isNotEmpty) {
      return students.first['id'].toString();
    }
    return null;
  }

  // Beibehalten für Kompatibilität
  Future<String> getMyStudentName() async {
    final students = await getAssignedStudents();
    if (students.isNotEmpty) {
      return students.first['name'] ?? 'Unbekannter Schüler';
    }
    return 'Kein Schüler zugewiesen';
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
        final userData = response.data['user'];

        // Token speichern
        await _storage.write(key: 'auth_token', value: response.data['token']);
        
        // Firma speichern
        await _storage.write(key: 'company_name', value: userData['company_name'] ?? 'Meine Firma');
        
        // Speichert das komplette User-Objekt als JSON
        await _storage.write(key: 'user_data', value: jsonEncode(userData));
        
        return true;
      }
      return false;
    } catch (e) {
      print("Login Fehler: $e");
      return false;
    }
  }

  Future<String> getCompanyName() async {
    String? userDataString = await _storage.read(key: 'user_data');
    if (userDataString != null) {
      try {
        final Map<String, dynamic> userData = jsonDecode(userDataString);
        if (userData['company_name'] != null) {
          return userData['company_name'].toString();
        }
      } catch (e) {
        print("Fehler beim Lesen des Firmennamens: $e");
      }
    }
    return await _storage.read(key: 'company_name') ?? "SignSync";
  }

  // --- API SPEICHER METHODEN ---

  Future<bool> _sendToBackend(Map<String, dynamic> data) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.post('/timesheet/store', options: options, data: data);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (e is DioException) print("LARA-ERROR (422): ${e.response?.data}");
      return false;
    }
  }

  // Spezifisch für interne Arbeit
  Future<bool> createInternalWork({
    required DateTime startTime,
    required DateTime endTime,
    String? description,
  }) async {
    return await _sendToBackend({
      "typ": "arbeit",
      "is_internal": "1",
      "schueler_id": "", 
      "start_zeit": _formatDate(startTime),
      "ende_zeit": _formatDate(endTime),
      "notiz": description ?? "",
      "user_id": await _getUserId(),
    });
  }

  // Spezifisch für Leistungen am Schüler
  Future<bool> createStudentLeistung({
    required String studentId,
    required DateTime startTime,
    required DateTime endTime,
    String? description,
  }) async {
    return await _sendToBackend({
      "typ": "leistung",
      "is_internal": "0",
      "schueler_id": studentId,
      "start_zeit": _formatDate(startTime),
      "ende_zeit": _formatDate(endTime),
      "notiz": description ?? "",
      "user_id": await _getUserId(),
    });
  }

  // --- TIMER BACKGROUND LOGIK ---
  // Wird genutzt, damit der Timer weiterläuft, auch wenn der User die Page verlässt.

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
    await _storage.write(key: 'timer_start_time', value: externalStartTime!.toIso8601String());
  }

  Future<void> stopGlobalTimer() async {
    isTimerRunning = false;
    externalStartTime = null;
    await _storage.delete(key: 'timer_start_time');
  }

  Duration get currentDuration {
    if (externalStartTime == null) return Duration.zero;
    return DateTime.now().difference(externalStartTime!);
  }
}