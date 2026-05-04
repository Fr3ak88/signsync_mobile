import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import 'api_service.dart';

void main() async {
  // Stellt sicher, dass die Flutter-Engine bereit ist, bevor wir den Speicher auslesen
  WidgetsFlutterBinding.ensureInitialized();
  
  // Versucht, einen laufenden Timer aus dem Speicher zu laden
  await ApiService().recoverTimer(); 
  
  runApp(const SignSyncApp());
}

class SignSyncApp extends StatelessWidget {
  const SignSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SignSync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

// --- LOGIN SCREEN ---
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _doLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final success = await ApiService().login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false,
          );
        });
      } else {
        _showError('Login fehlgeschlagen. Daten prüfen.');
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showError('Verbindungsfehler zum Server.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SignSync Login')),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_clock_outlined, size: 80, color: Colors.blue),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-Mail',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Passwort',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _doLogin,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Anmelden', style: TextStyle(fontSize: 16)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- HOME SCREEN (DASHBOARD) ---
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _companyName = "Lade...";
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadCompanyName();
  }

  Future<void> _loadCompanyName() async {
    String? name = await _storage.read(key: 'company_name');
    if (mounted) {
      setState(() {
        _companyName = name ?? "SignSync";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black54,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginPage()),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SignSync Dashboard: $_companyName',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Willkommen zurück! Hier können Sie Ihre Arbeitszeiten erfassen und einsehen.',
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
            const SizedBox(height: 32),
            LayoutBuilder(builder: (context, constraints) {
              bool isWide = constraints.maxWidth > 700;
              return Flex(
                direction: isWide ? Axis.horizontal : Axis.vertical,
                children: [
                  Expanded(
                    flex: isWide ? 1 : 0,
                    child: _buildActionCard(
                      title: 'Schülerbegleitung',
                      subtitle: 'Erfasse Zeiten für deine zugewiesenen Schüler.',
                      icon: Icons.groups,
                      buttonText: 'Zeit für Schüler erfassen',
                      buttonColor: const Color(0xFF4466F2),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateEntryPage())),
                    ),
                  ),
                  SizedBox(width: isWide ? 20 : 0, height: isWide ? 0 : 20),
                  Expanded(
                    flex: isWide ? 1 : 0,
                    child: _buildActionCard(
                      title: 'Interne Arbeitszeit',
                      subtitle: 'Erfasse Büroarbeit, Meetings oder Fahrtzeiten.',
                      icon: Icons.work,
                      buttonText: 'Arbeitszeit erfassen',
                      buttonColor: const Color(0xFF67C6E3),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InternalWorkPage())),
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 32),
            _buildStatsCard(),
            const SizedBox(height: 24),
            _buildArchiveBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({required String title, required String subtitle, required IconData icon, required String buttonText, required Color buttonColor, required VoidCallback onTap}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: buttonColor, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: buttonColor),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(backgroundColor: buttonColor, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(45)),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: const Border(left: BorderSide(color: Colors.green, width: 4))),
      child: const Column(
        children: [
          Text('📅 ARBEITSSTUNDEN IM APRIL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black45)),
          SizedBox(height: 12),
          Text('19,73 Std.', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildArchiveBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: const Row(
        children: [
          Icon(Icons.archive, color: Colors.amber),
          SizedBox(width: 16),
          Text('Dokumente & Archiv', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// --- LEISTUNG ERSTELLEN (SCHÜLER) ---
class CreateEntryPage extends StatefulWidget {
  final String? studentId; // Hier die Variable definieren

  // Den Konstruktor anpassen
  const CreateEntryPage({super.key, this.studentId});

  @override
  State<CreateEntryPage> createState() => _CreateEntryPageState();
}

class _CreateEntryPageState extends State<CreateEntryPage> {
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(hours: 1));
  bool _isSaving = false;

  String _formatDateTime(DateTime dt) {
  // padLeft(2, '0') sorgt dafür, dass führende Nullen angezeigt werden (z.B. 09:05 statt 9:5)
  String day = dt.day.toString().padLeft(2, '0');
  String month = dt.month.toString().padLeft(2, '0');
  String year = dt.year.toString();
  String hour = dt.hour.toString().padLeft(2, '0'); // dt.hour liefert automatisch 0-23
  String minute = dt.minute.toString().padLeft(2, '0');

  return "$day.$month.$year $hour:$minute";
  }

  Future<void> _pickDateTime(bool isStart) async {
    DateTime? date = await showDatePicker(context: context, initialDate: isStart ? _startDate : _endDate, firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (date == null) return;
    if (!mounted) return;

    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isStart ? _startDate : _endDate),
      builder: (BuildContext context, Widget? child) {
        // Erzwingt das 24h-Layout im Auswahl-Dialog
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (time == null) return;
    setState(() {
      final newDt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      isStart ? _startDate = newDt : _endDate = newDt;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(title: const Text('Neuen Zeiteintrag erstellen')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Schüler / Klient', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF1F3F5), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black12)),
              child: const Row(children: [Icon(Icons.school, color: Colors.green), SizedBox(width: 12), Text('Max Mustermann', style: TextStyle(fontWeight: FontWeight.bold))]),
            ),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: _buildPickerBox('START', _startDate, () => _pickDateTime(true))),
              const SizedBox(width: 16),
              Expanded(child: _buildPickerBox('ENDE', _endDate, () => _pickDateTime(false))),
            ]),
            const SizedBox(height: 24),
            const Text('BEMERKUNG (OPTIONAL)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(controller: _descriptionController, maxLines: 4, decoration: const InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder())),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                // 1. Lade die dem Mitarbeiter zugeordnete Schüler-ID aus dem Speicher
                final assignedStudentId = await ApiService().getMyStudentId();
                
                // 2. Berechne die Netto-Minuten aus dem Timer
                final netMinutes = ApiService().calculateNetMinutes();
                
                // Validierung: Wenn keine ID gefunden wurde, Fehlermeldung zeigen
                if (assignedStudentId == null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fehler: Keine Schüler-Zuordnung gefunden! Bitte neu einloggen.'), 
                        backgroundColor: Colors.orange
                      ),
                    );
                  }
                  return;
                }

                // 3. Sende die Daten an das Laravel-Backend
                // Wir nutzen hier 'assignedStudentId', die wir oben geladen haben
                bool success = await ApiService().createEntry(
                  studentId: assignedStudentId,
                  type: "leistung",
                  duration: netMinutes.toString(), 
                  description: _descriptionController.text,
                );

                // 4. Ergebnis verarbeiten
                if (success) {
                  ApiService().stopGlobalTimer();
                  ApiService().pausedMinutes = 0;

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Leistung erfolgreich gespeichert!'), 
                        backgroundColor: Colors.green
                      ),
                    );
                    Navigator.pop(context); // Seite schließen
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fehler beim Speichern der Leistung!'), 
                        backgroundColor: Colors.red
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF427D5D), 
                foregroundColor: Colors.white, 
                minimumSize: const Size.fromHeight(55)
              ),
              child: const Text('Zeitraum speichern'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerBox(String label, DateTime dt, VoidCallback onTap) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black12)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_formatDateTime(dt)), const Icon(Icons.calendar_today, size: 16)]),
        ),
      )
    ]);
  }
}

// --- TIMER ERFASSUNG (INTERN) ---
class InternalWorkPage extends StatefulWidget {
  const InternalWorkPage({super.key});

  @override
  State<InternalWorkPage> createState() => _InternalWorkPageState();
}

class _InternalWorkPageState extends State<InternalWorkPage> {
  final _descriptionController = TextEditingController();
  Timer? _refreshTimer;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    // 1. Beim Öffnen prüfen: Läuft der Timer im ApiService bereits?
    if (ApiService().isTimerRunning) {
      _startDisplayRefresh();
    }
  }

  // 2. Diese Funktion aktualisiert nur die Anzeige auf dem Bildschirm
  void _startDisplayRefresh() {
    _refreshTimer?.cancel(); // Alten Refresh-Timer stoppen, falls vorhanden
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // Wir holen uns die echte verstrichene Zeit direkt aus dem Service
          _duration = ApiService().currentDuration;
        });
      }
    });
  }

  void _handleStart() {
    setState(() {
      ApiService().startGlobalTimer(); // Logik im Hintergrund starten
      _startDisplayRefresh();         // UI-Update starten
    });
  }

  void _handleStop() {
    setState(() {
      _refreshTimer?.cancel();
      _duration = ApiService().currentDuration;
      ApiService().stopGlobalTimer();
    });
  }

  @override
  void dispose() {
    // WICHTIG: Hier stoppen wir NUR das UI-Update. 
    // Der Timer im ApiService läuft im Hintergrund weiter!
    _refreshTimer?.cancel();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wir fragen den ApiService, ob er gerade aktiv ist
    final bool isRunning = ApiService().isTimerRunning;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(title: const Text('Arbeitszeit')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text('Büro / Organisation / Fortbildung', 
              style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            
            // Start- und Stop-Buttons nutzen jetzt die neuen Handler
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _buildControlBtn('Start', Icons.play_arrow, Colors.green, 
                  isRunning ? null : _handleStart),
              const SizedBox(width: 20),
              _buildControlBtn('Stop', Icons.stop, Colors.red, 
                  isRunning ? _handleStop : null),
            ]),
            
            const SizedBox(height: 40),
            
            // Die Zeitanzeige
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF4466F2), 
                borderRadius: BorderRadius.circular(12)
              ),
              child: Text(
                _duration.toString().split('.').first.padLeft(8, "0"),
                style: const TextStyle(
                  color: Colors.white, 
                  fontSize: 48, 
                  fontWeight: FontWeight.bold
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 30),
            TextField(
              controller: _descriptionController, 
              decoration: const InputDecoration(
                labelText: 'Tätigkeitsbeschreibung', 
                border: OutlineInputBorder()
              )
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // 1. Netto-Minuten berechnen
                final netMinutes = ApiService().calculateNetMinutes();
                
                // 2. Den ApiService aufrufen
                bool success = await ApiService().createEntry(
                  studentId: "0", 
                  type: "arbeit",
                  duration: netMinutes.toString(), 
                  description: _descriptionController.text,
                );

                // 3. Ergebnis verarbeiten
                if (success) {
                  ApiService().stopGlobalTimer();
                  ApiService().pausedMinutes = 0;

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Arbeitszeit erfolgreich gespeichert!'), 
                        backgroundColor: Colors.green
                      ),
                    );
                    Navigator.pop(context); // Erst jetzt die Seite schließen
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fehler beim Speichern! Bitte prüfen Sie die Internetverbindung.'), 
                        backgroundColor: Colors.red
                      ),
                    );
                  }
                }
              },
              child: const Text('Arbeitszeit speichern'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlBtn(String label, IconData icon, Color color, VoidCallback? onTap) {
    return ElevatedButton.icon(
      onPressed: onTap, 
      icon: Icon(icon), 
      label: Text(label), 
      style: ElevatedButton.styleFrom(
        backgroundColor: color, 
        foregroundColor: Colors.white
      )
    );
  }
}