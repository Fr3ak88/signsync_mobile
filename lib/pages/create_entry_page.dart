import 'package:flutter/material.dart';
import '../services/api_service.dart';

// --- LEISTUNG ERSTELLEN (SCHÜLER) ---
class CreateEntryPage extends StatefulWidget {
  final String? studentId;

  const CreateEntryPage({super.key, this.studentId});

  @override
  State<CreateEntryPage> createState() => _CreateEntryPageState();
}

class _CreateEntryPageState extends State<CreateEntryPage> {
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(hours: 1));
  String _displayStudentName = "Lade..."; // Platzhalter für dynamischen Namen
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  // Lädt den echten Schülernamen aus dem ApiService
  Future<void> _loadStudentData() async {
    final name = await ApiService().getMyStudentName();
    if (mounted) {
      setState(() {
        _displayStudentName = name;
      });
    }
  }

  String _formatDateTime(DateTime dt) {
    String day = dt.day.toString().padLeft(2, '0');
    String month = dt.month.toString().padLeft(2, '0');
    String year = dt.year.toString();
    String hour = dt.hour.toString().padLeft(2, '0');
    String minute = dt.minute.toString().padLeft(2, '0');

    return "$day.$month.$year $hour:$minute";
  }

  Future<void> _pickDateTime(bool isStart) async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    if (!mounted) return;

    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isStart ? _startDate : _endDate),
      builder: (BuildContext context, Widget? child) {
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
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Leistung dokumentieren'),
        backgroundColor: const Color(0xFF427D5D),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Schüler / Klient', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.school, color: Color(0xFF427D5D)),
                  const SizedBox(width: 12),
                  Text(
                    _displayStudentName, // Dynamischer Name
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildPickerBox('START', _startDate, () => _pickDateTime(true))),
                const SizedBox(width: 16),
                Expanded(child: _buildPickerBox('ENDE', _endDate, () => _pickDateTime(false))),
              ],
            ),
            const SizedBox(height: 24),
            const Text('BEMERKUNG (OPTIONAL)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
                hintText: 'Was wurde gemacht?',
              ),
            ),
            const SizedBox(height: 32),
            _isSaving
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF427D5D)))
                : ElevatedButton(
                    onPressed: () async {
                      setState(() => _isSaving = true);

                      // 1. Hole ID aus dem ApiService (falls nicht über Konstruktor gekommen)
                      final assignedStudentId = widget.studentId ?? await ApiService().getMyStudentId();
                      
                      // 2. Berechne die Netto-Minuten
                      final netMinutes = ApiService().calculateNetMinutes();
                      
                      if (assignedStudentId == null) {
                        setState(() => _isSaving = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Fehler: Kein Schüler zugeordnet!'), 
                              backgroundColor: Colors.orange
                            ),
                          );
                        }
                        return;
                      }

                      // 3. Sende Daten an Laravel
                      bool success = await ApiService().createEntry(
                        studentId: assignedStudentId,
                        type: "leistung",
                        duration: netMinutes.toString(), 
                        description: _descriptionController.text,
                      );

                      if (!mounted) return;
                      setState(() => _isSaving = false);

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
                          Navigator.pop(context);
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Fehler beim Speichern!'), 
                              backgroundColor: Colors.red
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF427D5D), 
                      foregroundColor: Colors.white, 
                      minimumSize: const Size.fromHeight(55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Leistung speichern', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerBox(String label, DateTime dt, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDateTime(dt), style: const TextStyle(fontSize: 13)),
                const Icon(Icons.calendar_today, size: 16, color: Colors.black54),
              ],
            ),
          ),
        )
      ],
    );
  }
}