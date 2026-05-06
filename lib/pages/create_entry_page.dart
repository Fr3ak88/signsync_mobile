import 'package:flutter/material.dart';
import '../services/api_service.dart';

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
  
  List<Map<String, dynamic>> _assignedStudents = [];
  String? _selectedStudentId;
  bool _isLoadingStudents = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAllStudents();
  }

  Future<void> _loadAllStudents() async {
    final students = await ApiService().getAssignedStudents(); 
    
    if (mounted) {
      setState(() {
        _assignedStudents = students;
        _isLoadingStudents = false;
        
        if (widget.studentId != null) {
          _selectedStudentId = widget.studentId;
        } else if (_assignedStudents.isNotEmpty) {
          _selectedStudentId = _assignedStudents.first['id'].toString();
        }
      });
    }
  }

  String _formatDateTime(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _pickDateTime(bool isStart) async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isStart ? _startDate : _endDate),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
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
        backgroundColor: const Color(0xFF4466F2),
        foregroundColor: Colors.white,
      ),
      body: _isLoadingStudents 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Schüler / Klient auswählen',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedStudentId,
                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF4466F2)),
                      items: _assignedStudents.map((student) {
                        return DropdownMenuItem<String>(
                          value: student['id'].toString(),
                          child: Row(
                            children: [
                              const Icon(Icons.school, size: 20, color: Color(0xFF4466F2)),
                              const SizedBox(width: 12),
                              Text(student['name'].toString(), 
                                   style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedStudentId = value);
                      },
                    ),
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
                const Text('BEMERKUNG (OPTIONAL)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF4466F2)))
                    : ElevatedButton(
                        onPressed: _saveEntry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4466F2),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(55),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Leistung speichern',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
              ],
            ),
          ),
    );
  }

  Future<void> _saveEntry() async {
    if (_selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte einen Schüler auswählen!'), backgroundColor: Colors.orange),
      );
      return;
    }

    // SICHERHEITS-CHECK: Verhindert den Laravel 422 Fehler direkt in der App
    if (!_endDate.isAfter(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Die Endzeit muss nach der Startzeit liegen!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    bool success = await ApiService().createStudentLeistung(
      studentId: _selectedStudentId!,
      startTime: _startDate, 
      endTime: _endDate,
      description: _descriptionController.text, // WICHTIG: Die Notiz wird jetzt mitgesendet!
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      // Falls ein Timer lief, wird dieser als "erledigt" zurückgesetzt
      ApiService().stopGlobalTimer();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Leistung erfolgreich gespeichert!'), backgroundColor: Color(0xFF4466F2)),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fehler beim Speichern! Bitte überprüfe deine Daten.'), backgroundColor: Colors.red),
      );
    }
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