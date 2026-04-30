import 'package:flutter/material.dart';
import 'api_service.dart';
import 'dart:async';

void main() {
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
      setState(() => _isLoading = false);
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
              const Icon(Icons.lock_clock_outlined,
                  size: 80, color: Colors.blue),
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
                      child: const Text('Anmelden',
                          style: TextStyle(fontSize: 16)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- HOME SCREEN (DASHBOARD) ---
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black54,
        elevation: 0.5,
        centerTitle: false,
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
            const Text(
              'SignSync Dashboard: Fritzler eCommerce',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Willkommen zurück, Test Angestellter. Hier können Sie Ihre Arbeitszeiten erfassen und einsehen.',
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
                      subtitle:
                          'Erfasse Zeiten für deine zugewiesenen Schüler. Diese Zeiten erscheinen auf dem Leistungsnachweis für das Amt.',
                      icon: Icons.groups,
                      buttonText: 'Zeit für Schüler erfassen',
                      buttonColor: const Color(0xFF4466F2),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                CreateEntryPage()), // KEIN const hier
                      ),
                    ),
                  ),
                  SizedBox(width: isWide ? 20 : 0, height: isWide ? 0 : 20),
                  Expanded(
                    flex: isWide ? 1 : 0,
                    child: _buildActionCard(
                      title: 'Interne Arbeitszeit',
                      subtitle:
                          'Erfasse Büroarbeit, Team-Meetings, Fortbildungen oder Fahrtzeiten. Diese Zeiten sind nur für deine interne Abrechnung.',
                      icon: Icons.work,
                      buttonText: 'Arbeitszeit erfassen',
                      buttonColor: const Color(0xFF67C6E3),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const InternalWorkPage()),
                        );
                      },
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 32),
            _buildStatsCard(),
            const SizedBox(height: 24),
            _buildArchiveBar(),
            const SizedBox(height: 40),
            const Center(
              child: Text(
                '🛡️ Ihre Daten werden sicher und DSGVO-konform für die Abrechnung verarbeitet.',
                style: TextStyle(color: Colors.black45, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String buttonText,
    required Color buttonColor,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: buttonColor, width: 4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: buttonColor),
          const SizedBox(height: 16),
          Text(title,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, height: 1.4)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.add_circle_outline),
            label: Text(buttonText),
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(45),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(color: Colors.green, width: 4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          const Text('📅 ARBEITSSTUNDEN IM APRIL',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black45)),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('19,73',
                  style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748))),
              SizedBox(width: 8),
              Text('Std.',
                  style: TextStyle(fontSize: 24, color: Colors.black54)),
            ],
          ),
          const Text('Gesamtzeit aller Einsätze und Bürozeiten diesen Monat.',
              style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.list),
            label: const Text('Alle Einträge anzeigen'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green,
              side: const BorderSide(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchiveBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.amber.shade50, shape: BoxShape.circle),
            child: const Icon(Icons.lock_outline, color: Colors.amber),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dokumente & Archiv',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                    'Alle signierten Leistungs- und Arbeitsnachweise einsehen.',
                    style: TextStyle(color: Colors.black54, fontSize: 14)),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {},
            label: const Text('Zum Archiv'),
            icon: const Icon(Icons.arrow_forward),
            style: OutlinedButton.styleFrom(
                foregroundColor: Colors.amber,
                side: const BorderSide(color: Colors.amber)),
          ),
        ],
      ),
    );
  }
}

// --- NEU: LEISTUNG ERSTELLEN SCREEN ---
class CreateEntryPage extends StatefulWidget {
  const CreateEntryPage({super.key});

  @override
  State<CreateEntryPage> createState() => _CreateEntryPageState();
}

class _CreateEntryPageState extends State<CreateEntryPage> {
  final _remarkController = TextEditingController();

  // Datums-Variablen
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(hours: 1));

  bool _isSaving = false;

  // Hilfsfunktion zum Formatieren des Datums (DD.MM.YYYY HH:mm)
  String _formatDateTime(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  // Funktion zum Öffnen des Date/Time Pickers
  Future<void> _pickDateTime(bool isStart) async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date == null || !mounted) return;

    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isStart ? _startDate : _endDate),
    );

    if (time == null) return;

    setState(() {
      final newDt =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
      if (isStart) {
        _startDate = newDt;
      } else {
        _endDate = newDt;
      }
    });
  }

  void _saveEntry() async {
    setState(() => _isSaving = true);

    // Dauer berechnen für die API (in Minuten oder Stunden)
    final duration = _endDate.difference(_startDate).inMinutes.toString();

    bool success = await ApiService().createEntry(
      studentId: "1", // Max Mustermann ID
      type: "Leistung",
      duration: duration,
      description: _remarkController.text,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Zeitraum erfolgreich gespeichert!'),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.access_time, size: 20, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Neuen Zeiteintrag erstellen',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- SCHÜLER SEKTION ---
              const Text('Schüler / Klient',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black12),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.school, color: Colors.green, size: 20),
                    SizedBox(width: 12),
                    Text('Max Mustermann',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Text('Eintrag erfolgt für: Max Mustermann',
                  style: TextStyle(fontSize: 12, color: Colors.black54)),

              const SizedBox(height: 24),

              // --- DATUM / UHRZEIT ZEILE ---
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('START (DATUM/UHRZEIT)',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                        const SizedBox(height: 8),
                        _buildDateTimePickerBox(
                            _startDate, () => _pickDateTime(true)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ENDE (DATUM/UHRZEIT)',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                        const SizedBox(height: 8),
                        _buildDateTimePickerBox(
                            _endDate, () => _pickDateTime(false)),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // --- BEMERKUNG ---
              const Text('BEMERKUNG (OPTIONAL)',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              const SizedBox(height: 8),
              TextField(
                controller: _remarkController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Besonderheiten während des Einsatzes...',
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.black12)),
                ),
              ),

              const SizedBox(height: 32),

              // --- SPEICHERN BUTTON ---
              _isSaving
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _saveEntry,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Zeitraum speichern',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                            0xFF427D5D), // Dunkelgrün wie im Screenshot
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(55),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // Hilfs-Widget für die Zeit-Auswahl-Boxen
  Widget _buildDateTimePickerBox(DateTime dateTime, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.between,
          children: [
            Text(_formatDateTime(dateTime),
                style: const TextStyle(fontSize: 15)),
            const Icon(Icons.calendar_today_outlined,
                size: 18, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}

class InternalWorkPage extends StatefulWidget {
  const InternalWorkPage({super.key});

  @override
  State<InternalWorkPage> createState() => _InternalWorkPageState();
}

class _InternalWorkPageState extends State<InternalWorkPage> {
  final _descriptionController = TextEditingController();
  
  // Stoppuhr-Logik
  Timer? _timer;
  Duration _duration = Duration.zero;
  bool _isRunning = false;
  DateTime? _startTime;
  DateTime? _endTime;

  void _toggleTimer() {
    setState(() {
      if (_isRunning) {
        // Stop
        _timer?.cancel();
        _isRunning = false;
        _endTime = DateTime.now();
      } else {
        // Start
        _isRunning = true;
        _startTime ??= DateTime.now();
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _duration = DateTime.now().difference(_startTime!);
          });
        });
      }
    });
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Neuen Zeiteintrag erstellen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Art der Erfassung', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                
                // INFO-BOX
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: Color(0xFF67C6E3)),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Büro / Organisation / Fortbildung', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
                            Text('Diese Stunden werden für den internen Arbeitsnachweis (Büro) erfasst und erfordern keine Schülerzuordnung.', 
                              style: TextStyle(fontSize: 12, color: Colors.black54)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                const Center(child: Text('ZEITERFASSUNG', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black45))),
                const SizedBox(height: 16),

                // START/PAUSE/STOP BUTTONS
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTimerButton(
                      label: 'Start', 
                      icon: Icons.play_arrow, 
                      color: const Color(0xFF427D5D), 
                      onTap: _isRunning ? null : _toggleTimer
                    ),
                    const SizedBox(width: 12),
                    _buildTimerButton(
                      label: 'Pause', 
                      icon: Icons.pause, 
                      color: const Color(0xFFF6D55C), 
                      onTap: () {} // Logik für Pause hier
                    ),
                    const SizedBox(width: 12),
                    _buildTimerButton(
                      label: 'Stop', 
                      icon: Icons.stop, 
                      color: const Color(0xFFD9534F), 
                      onTap: _isRunning ? _toggleTimer : null
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // STATUS KACHELN
                Row(
                  children: [
                    _buildStatusTile(
                      icon: Icons.play_circle_outline, 
                      label: 'GESTARTET', 
                      value: _startTime == null ? 'Noch nicht gestartet' : "${_startTime!.hour}:${_startTime!.minute}"
                    ),
                    const SizedBox(width: 12),
                    _buildStatusTile(
                      icon: Icons.stop_circle_outlined, 
                      label: 'BEENDET', 
                      value: _endTime == null ? 'Noch nicht gestoppt' : "${_endTime!.hour}:${_endTime!.minute}"
                    ),
                    const SizedBox(width: 12),
                    _buildStatusTile(
                      icon: Icons.pause_circle_outline, 
                      label: 'PAUSE', 
                      value: '0 Min'
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // BLAUE ZEITANZEIGE
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4466F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.access_time, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('GESAMTLAUFZEIT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDuration(_duration),
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                const Text('TÄTIGKEITSBESCHREIBUNG', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black45)),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'z.B. Dokumentation, Team-Meeting, Fahrtzeit...',
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black12)),
                  ),
                ),

                const SizedBox(height: 24),

                ElevatedButton.icon(
                  onPressed: () {}, // Speichern Logik
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Arbeitszeit speichern'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9AD9F1), // Hellblau wie im Screenshot
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimerButton({required String label, required IconData icon, required Color color, VoidCallback? onTap}) {
    return Opacity(
      opacity: onTap == null ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 80,
          height: 100,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTile({required IconData icon, required String label, required String value}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black12)),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: Colors.orangeAccent),
                const SizedBox(width: 4),
                Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black45)),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
