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

  // --- VARIABLEN FÜR TIMER & PAUSE ---
  int pausedMinutes = 0; 
  DateTime? externalStartTime;
  bool isTimerRunning = false;

  // Hilfsmethode für das Token
  Future<Options> _getAuthOptions() async {
    String? token = await _storage.read(key: 'auth_token');
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  // NEU: Holt die Liste aller zugewiesenen Schüler für das Dropdown
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

  // Beibehalten für Kompatibilität (gibt ID des ersten Kindes zurück)
  Future<String?> getMyStudentId() async {
    final students = await getAssignedStudents();
    if (students.isNotEmpty) {
      return students.first['id'].toString();
    }
    return null;
  }

  // Beibehalten für Kompatibilität (gibt Name des ersten Kindes zurück)
  Future<String> getMyStudentName() async {
    final students = await getAssignedStudents();
    if (students.isNotEmpty) {
      return students.first['name'] ?? 'Unbekannter Schüler';
    }
    return 'Kein Schüler zugewiesen';
  }

  // Login - ANGEPASST auf das neue Listen-Format
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
        
        // --- ANPASSUNG: Speichert das komplette User-Objekt inkl. 'kinder' Liste als JSON ---
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
    // Wir schauen erst in 'user_data', da dort alle User-Infos liegen
    String? userDataString = await _storage.read(key: 'user_data');
    if (userDataString != null) {
      try {
        final Map<String, dynamic> userData = jsonDecode(userDataString);
        // Prüfe ob 'company_name' im User-Objekt steckt
        if (userData['company_name'] != null) {
          return userData['company_name'].toString();
        }
      } catch (e) {
        print("Fehler beim Lesen des Firmennamens: $e");
      }
    }
    // Fallback auf den alten Key oder Standardnamen
    return await _storage.read(key: 'company_name') ?? "SignSync";
  }

  // Zeiteintrag erstellen
 // Die private Basis-Methode (intern)
Future<bool> _sendToBackend(Map<String, dynamic> data) async {
  try {
    final options = await _getAuthOptions();
    final response = await _dio.post('/timesheet/store', options: options, data: data);
    return response.statusCode == 200 || response.statusCode == 201;
  } catch (e) {
    if (e is DioException) print("Fehler: ${e.response?.data}");
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
    "schueler_id": "", // Wie gefordert als leerer String
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
  // --- TIMER LOGIK ---

  int calculateNetMinutes() {
    if (externalStartTime == null) return 0;
    int totalMinutes = DateTime.now().difference(externalStartTime!).inMinutes;
    int net = totalMinutes - pausedMinutes;
    return net > 0 ? net : 0;
  }

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
    pausedMinutes = 0;
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