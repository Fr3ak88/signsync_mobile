import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';

// Imports der ausgelagerten Dateien
import 'services/api_service.dart';
import 'pages/login_page.dart';
import 'pages/create_entry_page.dart';
import 'pages/internal_work_page.dart';
import 'pages/timesheet_history_page.dart'; 

void main() async {
  // Stellt sicher, dass die Flutter-Engine bereit ist
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
        // Einheitliches Farbschema basierend auf deinem Grün
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF427D5D)),
        useMaterial3: true,
      ),
      home: const LoginPage(),
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
  // Nutze den zentralen ApiService
  final name = await ApiService().getCompanyName();
  
  if (mounted) {
    setState(() {
      _companyName = name;
    });
  }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Signsync', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color.fromARGB(255, 0, 0, 0),
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false,
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
              _companyName,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF427D5D)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Willkommen zurück! Erfassen Sie hier Ihre Leistungen oder Arbeitszeiten.',
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
            const SizedBox(height: 32),
            
            // Grid-ähnliches Layout für die Hauptaktionen
            LayoutBuilder(builder: (context, constraints) {
              bool isWide = constraints.maxWidth > 700;
              return Flex(
                direction: isWide ? Axis.horizontal : Axis.vertical,
                children: [
                  Expanded(
                    flex: isWide ? 1 : 0,
                    child: _buildActionCard(
                      title: 'Schülerbegleitung',
                      subtitle: 'Leistungen für zugewiesene Schüler dokumentieren.',
                      icon: Icons.school,
                      buttonText: 'Leistung erfassen',
                      buttonColor: const Color(0xFF4466F2),
                      onTap: () => Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => const CreateEntryPage())
                      ),
                    ),
                  ),
                  SizedBox(width: isWide ? 20 : 0, height: isWide ? 0 : 20),
                  Expanded(
                    flex: isWide ? 1 : 0,
                    child: _buildActionCard(
                      title: 'Arbeitszeit',
                      subtitle: 'Allgemeine Arbeitszeiten erfassen.',
                      icon: Icons.assignment_ind,
                      buttonText: 'Arbeitszeit starten',
                      buttonColor: const Color(0xFF67C6E3),
                      onTap: () => Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => const InternalWorkPage())
                      ),
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

  Widget _buildActionCard({
    required String title, 
    required String subtitle, 
    required IconData icon, 
    required String buttonText, 
    required Color buttonColor, 
    required VoidCallback onTap
  }) {
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
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor, 
              foregroundColor: Colors.white, 
              minimumSize: const Size.fromHeight(45),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    // Hilfsmethode für den aktuellen Monat
    String getCurrentMonthName() {
      const months = [
        'JANUAR', 'FEBRUAR', 'MÄRZ', 'APRIL', 'MAI', 'JUNI', 
        'JULI', 'AUGUST', 'SEPTEMBER', 'OKTOBER', 'NOVEMBER', 'DEZEMBER'
      ];
      return months[DateTime.now().month - 1];
    }

    const Color brandColor = Color(0xFF427D5D); // Dein SignSync Grün

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: brandColor, width: 5.0),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'ARBEITSSTUNDEN IM ${getCurrentMonthName()}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text(
                    '0,00', // Hier setzen wir im nächsten Schritt die API-Daten ein
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: brandColor,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Std.',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Gesamtzeit aller Zeiten diesen Monat.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const TimesheetHistoryPage()));
                },
                icon: const Icon(Icons.format_list_bulleted, size: 18),
                label: const Text(
                  'Alle Einträge anzeigen',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: brandColor,
                  side: const BorderSide(color: brandColor, width: 1.2),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArchiveBar() {
    return InkWell(
      onTap: () {
        // Logik für Archiv
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
        ),
        child: const Row(
          children: [
            Icon(Icons.archive_outlined, color: Colors.grey),
            SizedBox(width: 16),
            Text('Dokumente & Archiv (coming soon...)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            Spacer(),
            Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}