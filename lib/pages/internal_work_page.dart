import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';

class InternalWorkPage extends StatefulWidget {
  const InternalWorkPage({super.key});

  @override
  State<InternalWorkPage> createState() => _InternalWorkPageState();
}

class _InternalWorkPageState extends State<InternalWorkPage> {
  final _descriptionController = TextEditingController();
  Timer? _refreshTimer;
  bool _isSaving = false;

  // --- Timer State ---
  DateTime? _savedStartTime;
  DateTime? _savedEndTime;
  bool _isPaused = false;
  DateTime? _pauseStartTime;
  int _totalPausedSeconds = 0;

  @override
  void initState() {
    super.initState();
    // Falls der Timer im Hintergrund lief, Werte aus dem Service holen
    if (ApiService().isTimerRunning) {
      _savedStartTime = ApiService().externalStartTime ?? DateTime.now();
      _startDisplayRefresh();
    }
  }

  void _startDisplayRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  // --- Aktionen ---

  void _handleStart() {
    ApiService().startGlobalTimer();
    _savedStartTime = DateTime.now();
    _savedEndTime = null;
    _isPaused = false;
    _totalPausedSeconds = 0;
    _startDisplayRefresh();
    setState(() {});
  }

  void _handlePause() {
    if (_savedStartTime == null || _savedEndTime != null) return; // Nur pausieren wenn aktiv

    setState(() {
      if (_isPaused) {
        // Pausierung beenden -> Pausenzeit addieren
        if (_pauseStartTime != null) {
          _totalPausedSeconds += DateTime.now().difference(_pauseStartTime!).inSeconds;
        }
        _isPaused = false;
        _pauseStartTime = null;
      } else {
        // Pausierung starten
        _isPaused = true;
        _pauseStartTime = DateTime.now();
      }
    });
  }

  void _handleStop() {
    if (_savedStartTime == null || _savedEndTime != null) return; // Bereits gestoppt

    _refreshTimer?.cancel();
    
    // Falls gerade pausiert war, die aktuelle Pausenzeit noch dazurechnen
    if (_isPaused && _pauseStartTime != null) {
      _totalPausedSeconds += DateTime.now().difference(_pauseStartTime!).inSeconds;
      _isPaused = false;
    }

    _savedEndTime = DateTime.now();
    ApiService().stopGlobalTimer(); // Stoppt den Hintergrund-Service
    
    setState(() {});
  }

  // --- Berechnungen für die UI ---

  Duration get _currentNetDuration {
    if (_savedStartTime == null) return Duration.zero;
    
    DateTime end = _savedEndTime ?? DateTime.now();
    Duration totalGross = end.difference(_savedStartTime!);
    
    int currentPauseSecs = _totalPausedSeconds;
    if (_isPaused && _pauseStartTime != null) {
      currentPauseSecs += DateTime.now().difference(_pauseStartTime!).inSeconds;
    }

    Duration net = totalGross - Duration(seconds: currentPauseSecs);
    return net.isNegative ? Duration.zero : net;
  }

  int get _displayPauseMinutes {
    int currentPauseSecs = _totalPausedSeconds;
    if (_isPaused && _pauseStartTime != null) {
      currentPauseSecs += DateTime.now().difference(_pauseStartTime!).inSeconds;
    }
    return (currentPauseSecs / 60).floor();
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return "Noch nicht...";
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} Uhr";
  }

  String get _statusText {
    if (_savedStartTime == null) return "Bereit zum Start";
    if (_savedEndTime != null) return "Beendet - Bereit zum Speichern";
    if (_isPaused) return "Pausiert";
    return "Zeiterfassung läuft";
  }

  Color get _statusColor {
    if (_savedStartTime == null) return Colors.grey.shade600;
    if (_savedEndTime != null) return Colors.blue.shade600;
    if (_isPaused) return Colors.amber.shade700;
    return Colors.green.shade600;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isRunning = _savedStartTime != null && _savedEndTime == null;
    final bool canSave = _savedStartTime != null && _savedEndTime != null; // Nur speichern wenn gestoppt

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Neuen Zeiteintrag erstellen'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Art der Erfassung', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            
            // Info-Box (Büro / Organisation)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100)
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info, color: Colors.blue.shade400),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Büro / Organisation / Fortbildung', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E5B76))),
                        SizedBox(height: 4),
                        Text('Diese Stunden werden für den internen Arbeitsnachweis (Büro) erfasst und erfordern keine Schülerzuordnung.',
                            style: TextStyle(fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            const Text('ZEITERFASSUNG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 16),
            
            // Status Badge
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(_statusText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Die 3 quadratischen Buttons (Start, Pause, Stop)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSquareBtn('Start', Icons.play_circle_fill, Colors.green.shade600, _savedStartTime == null ? _handleStart : null),
                const SizedBox(width: 16),
                _buildSquareBtn(_isPaused ? 'Weiter' : 'Pause', _isPaused ? Icons.play_arrow : Icons.pause_circle_filled, Colors.amber.shade500, isRunning ? _handlePause : null),
                const SizedBox(width: 16),
                _buildSquareBtn('Stop', Icons.stop_circle, Colors.red.shade400, isRunning ? _handleStop : null),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Die 3 Info-Karten (Gestartet, Beendet, Pause)
            Row(
              children: [
                Expanded(child: _buildInfoCard('GESTARTET', Icons.play_circle_outline, Colors.green, _formatTime(_savedStartTime))),
                const SizedBox(width: 12),
                Expanded(child: _buildInfoCard('BEENDET', Icons.stop_circle_outlined, Colors.red, _savedEndTime != null ? _formatTime(_savedEndTime) : "Noch nicht gestoppt")),
                const SizedBox(width: 12),
                Expanded(child: _buildInfoCard('PAUSE', Icons.pause_circle_outline, Colors.amber, '$_displayPauseMinutes Min')),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Großes Blaues Banner für Gesamtlaufzeit
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF4466F2), // Das typische Blau
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.access_time, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('GESAMTLAUFZEIT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _savedStartTime == null ? "-" : _currentNetDuration.toString().split('.').first.padLeft(8, "0"),
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'Courier'),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            const Text('TÄTIGKEITSBESCHREIBUNG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController, 
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'z.B. Dokumentation, Team-Meeting, Fahrtzeit...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
              )
            ),
            const SizedBox(height: 30),
            
            _isSaving
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF4466F2)))
              : ElevatedButton(
                  // Speichern ist nur möglich, wenn gestoppt wurde (canSave)
                  onPressed: canSave ? _saveInternalWork : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue.shade300, 
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    minimumSize: const Size.fromHeight(55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline),
                      SizedBox(width: 8),
                      Text('Arbeitszeit speichern', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }

  // --- Hilfs-Widgets ---

  Widget _buildSquareBtn(String label, IconData icon, Color color, VoidCallback? onTap) {
    bool isDisabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: isDisabled ? color.withOpacity(0.4) : color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, IconData icon, Color iconColor, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, 
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)
          ),
        ],
      ),
    );
  }

  // --- API Logik ---
  
  Future<void> _saveInternalWork() async {
    // Check, ob mindestens 1 Minute zusammengekommen ist
    if (_currentNetDuration.inMinutes < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Der Timer muss mindestens 1 Minute laufen.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSaving = true);

    bool success = await ApiService().createInternalWork(
      startTime: _savedStartTime!,
      endTime: _savedEndTime!,
      description: _descriptionController.text,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arbeitszeit erfolgreich gespeichert!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context); // Zurück zur Übersicht
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fehler beim Speichern!'), backgroundColor: Colors.red),
      );
    }
  }
}