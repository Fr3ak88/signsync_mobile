import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';

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
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Beim Öffnen prüfen, ob der Timer bereits im Hintergrund läuft
    if (ApiService().isTimerRunning) {
      _startDisplayRefresh();
    }
  }

  // UI-Update-Timer starten
  void _startDisplayRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _duration = ApiService().currentDuration;
        });
      }
    });
  }

  void _handleStart() {
    ApiService().startGlobalTimer();
    _startDisplayRefresh();
    setState(() {}); // UI aktualisieren, um Buttons zu spiegeln
  }

  void _handleStop() {
    _refreshTimer?.cancel();
    _duration = ApiService().currentDuration;
    ApiService().stopGlobalTimer();
    setState(() {}); // UI aktualisieren
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isRunning = ApiService().isTimerRunning;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Interne Arbeitszeit'),
        backgroundColor: const Color(0xFF427D5D),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Büro / Organisation / Fortbildung',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 30),
            
            // Start- und Stop-Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildControlBtn(
                  'Start', 
                  Icons.play_arrow, 
                  const Color(0xFF427D5D), 
                  isRunning ? null : _handleStart
                ),
                const SizedBox(width: 20),
                _buildControlBtn(
                  'Stop', 
                  Icons.stop, 
                  Colors.redAccent, 
                  isRunning ? _handleStop : null
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            
            // Die Zeitanzeige (Digital-Uhr-Look)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isRunning ? const Color(0xFF427D5D) : Colors.grey.shade700, 
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Text(
                _duration.toString().split('.').first.padLeft(8, "0"),
                style: const TextStyle(
                  color: Colors.white, 
                  fontSize: 48, 
                  fontFamily: 'Courier', // Monospace für stabilere Anzeige
                  fontWeight: FontWeight.bold
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 40),
            const Text('TÄTIGKEITSBESCHREIBUNG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController, 
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Was haben Sie erledigt?',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder()
              )
            ),
            const SizedBox(height: 30),
            
            _isSaving
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF427D5D)))
              : ElevatedButton(
                  onPressed: isRunning ? null : _saveInternalWork,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF427D5D), 
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    minimumSize: const Size.fromHeight(55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                  ),
                  child: const Text('Arbeitszeit speichern', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
            
            if (isRunning)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  '* Bitte stoppen Sie den Timer, bevor Sie speichern.',
                  style: TextStyle(color: Colors.orange, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveInternalWork() async {
    if (_duration.inMinutes < 1 && _duration.inSeconds > 0) {
      // Optional: Warnung bei sehr kurzen Zeiten oder einfach als 1 Min werten
    }

    setState(() => _isSaving = true);

    // 1. Netto-Minuten berechnen
    final netMinutes = ApiService().calculateNetMinutes();
    
    // 2. Den ApiService aufrufen
    // studentId: "0" signalisiert im ApiService 'null' für interne Arbeit
    bool success = await ApiService().createEntry(
      studentId: "0", 
      type: "arbeit", // In Laravel als Typ für interne Arbeit hinterlegt
      duration: netMinutes.toString(), 
      description: _descriptionController.text,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    // 3. Ergebnis verarbeiten
    if (success) {
      ApiService().pausedMinutes = 0;
      // Timer ist bereits durch _handleStop() gestoppt, 
      // aber wir stellen sicher, dass alles sauber ist.

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Interne Arbeitszeit erfolgreich gespeichert!'), 
          backgroundColor: Colors.green
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fehler beim Speichern!'), 
          backgroundColor: Colors.red
        ),
      );
    }
  }

  Widget _buildControlBtn(String label, IconData icon, Color color, VoidCallback? onTap) {
    return ElevatedButton.icon(
      onPressed: onTap, 
      icon: Icon(icon), 
      label: Text(label), 
      style: ElevatedButton.styleFrom(
        backgroundColor: color, 
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
      )
    );
  }
}