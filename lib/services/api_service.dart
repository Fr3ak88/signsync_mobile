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
  Future<bool> createEntry({
  required String studentId,
  required String type,
  required String duration,
  String? description,
  DateTime? startTime,
  DateTime? endTime,
}) async {
  try {
    final finalEnd = endTime ?? DateTime.now();
    final finalStart = startTime ?? finalEnd.subtract(Duration(minutes: int.tryParse(duration) ?? 1));

    String formatDate(DateTime dt) => 
        "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}";

    final options = await _getAuthOptions();
    final bool isInternal = (studentId == "0" || studentId == "");
    
    // NEU: User-ID aus dem Speicher holen (wurde beim Login in user_data abgelegt)
    String? userDataString = await _storage.read(key: 'user_data');
    String? userId;
    if (userDataString != null) {
      userId = jsonDecode(userDataString)['id'].toString();
    }

    final Map<String, dynamic> requestData = {
      "typ": type.toLowerCase(),
      "is_internal": isInternal ? "1" : "0",
      "schueler_id": isInternal ? "" : int.tryParse(studentId),
      "start_zeit": formatDate(finalStart),
      "ende_zeit": formatDate(finalEnd),
      "notiz": description ?? "",
    };

    if (pausedMinutes > 0) {
      requestData["pause_minuten"] = pausedMinutes;
    }

    final response = await _dio.post(
      '/timesheet/store', 
      options: options,
      data: requestData,
    );

    return response.statusCode == 200 || response.statusCode == 201;
  } catch (e) {
    if (e is DioException) {
       // SCHAU HIER IN DIE KONSOLE: Laravel sagt dir hier exakt, welches Feld fehlt!
       print("VALIDIERUNGSFEHLER: ${e.response?.data}");
    }
    return false;
  }
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