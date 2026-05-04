import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';

// Imports der ausgelagerten Dateien
import 'services/api_service.dart';
import 'pages/login_page.dart';
import 'pages/create_entry_page.dart';        // Deine Seite für Schüler
import 'pages/internal_work_page.dart';      // Deine Seite für Intern (vorher: create_entry_page_intern)

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
        title: const Text('Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF427D5D),
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
              'Willkommen zurück! Erfassen Sie hier Ihre Leistungen oder interne Arbeitszeiten.',
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
                      title: 'Interne Arbeit',
                      subtitle: 'Büro, Meetings oder Fortbildungen erfassen.',
                      icon: Icons.assignment_ind,
                      buttonText: 'Arbeitszeit starten',
                      buttonColor: const Color(0xFF67C6E3), // Etwas helleres Grün zur Unterscheidung
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(12), 
        border: const Border(left: BorderSide(color: Color(0xFF427D5D), width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
      ),
      child: const Column(
        children: [
          Text('📅 ARBEITSSTUNDEN DIESER MONAT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black45)),
          SizedBox(height: 12),
          Text('cooming soon...', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
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
            Text('Dokumente & Archiv (cooming soon...)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            Spacer(),
            Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}