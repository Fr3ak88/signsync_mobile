import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  // NEU: Hilfsmethode um die gespeicherte Schüler-ID des Mitarbeiters zu holen
  Future<String?> getMyStudentId() async {
    return await _storage.read(key: 'my_student_id');
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
        // Token speichern
        await _storage.write(key: 'auth_token', value: response.data['token']);
        
        // Firmennamen speichern
        final companyName = response.data['user']['company_name'] ?? 'Meine Firma';
        await _storage.write(key: 'company_name', value: companyName);
        
        // --- ANPASSUNG: Schüler-ID des Mitarbeiters speichern ---
        // Hier wird angenommen, dass Laravel 'schueler_id' im user-Objekt mitsendet
        final sId = response.data['user']['schueler_id']?.toString();
        if (sId != null) {
          await _storage.write(key: 'my_student_id', value: sId);
        }
        
        return true;
      }
      return false;
    } catch (e) {
      print("Login Fehler: $e");
      return false;
    }
  }

  // Zeiteintrag erstellen
  Future<bool> createEntry({
    String? studentId,
    required String type,
    required String duration,
    String? description,
  }) async {
    try {
      final now = DateTime.now();
      final minutes = int.tryParse(duration) ?? 0;
      
      final startTime = now.subtract(Duration(minutes: minutes > 0 ? minutes : 1));

      String formatDate(DateTime dt) => 
          "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
          "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}";

      final options = await _getAuthOptions();

      final Map<String, dynamic> requestData = {
        "typ": type.toLowerCase(),
        // Wenn studentId "0" ist, wird null gesendet (Interne Arbeit)
        "schueler_id": (studentId == "0" || studentId == null) ? null : int.tryParse(studentId),
        "start_zeit": formatDate(startTime),
        "ende_zeit": formatDate(now),
        "notiz": description ?? "",
      };

      if (pausedMinutes > 0) {
        requestData["pause_minuten"] = pausedMinutes;
      }

      print("Sende Daten an Server: $requestData");

      final response = await _dio.post(
        '/zeiteintraege', 
        options: options,
        data: requestData,
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (e is DioException) {
        print("SERVER FEHLER: ${e.response?.data}");
      } else {
        print("FEHLER: $e");
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