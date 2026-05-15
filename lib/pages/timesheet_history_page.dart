import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TimesheetHistoryPage extends StatefulWidget {
  const TimesheetHistoryPage({super.key});

  @override
  State<TimesheetHistoryPage> createState() => _TimesheetHistoryPageState();
}

class _TimesheetHistoryPageState extends State<TimesheetHistoryPage> {
  // Filter-Zustände
  String _selectedMonth = 'Alle Monate';
  String _selectedType = 'Alle Einträge';
  List<String> _availableMonths = ['Alle Monate']; 

  // Daten-Listen
  List<Map<String, dynamic>> _allEntries = [];      
  List<Map<String, dynamic>> _filteredEntries = []; 
  
  bool _isLoading = true;
  double _totalNetHours = 0.0;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    
    final data = await ApiService().getTimesheets();
    
    Set<String> monthsSet = {};
    for (var entry in data) {
      if (entry['start_zeit'] != null) {
        try {
          DateTime dt = DateTime.parse(entry['start_zeit']);
          monthsSet.add("${dt.month.toString().padLeft(2, '0')}.${dt.year}");
        } catch (_) {}
      }
    }
    
    List<String> sortedMonths = monthsSet.toList()..sort((a, b) {
      var partsA = a.split('.');
      var partsB = b.split('.');
      return "${partsB[1]}${partsB[0]}".compareTo("${partsA[1]}${partsA[0]}");
    });

    if (mounted) {
      setState(() {
        _allEntries = data;
        _filteredEntries = List.from(_allEntries); 
        _availableMonths = ['Alle Monate', ...sortedMonths];
        _isLoading = false;
        _recalculateTotal(); 
      });
    }
  }

  // --- FILTER LOGIK ---

  void _applyFilter() {
    setState(() {
      _filteredEntries = _allEntries.where((entry) {
        // ROBUSTER CHECK: Prüft auf 1, "1", true, oder typ == "arbeit"
        bool isIntern = entry['is_internal'] == 1 || 
                        entry['is_internal'] == '1' || 
                        entry['is_internal'] == true || 
                        entry['typ'] == 'arbeit';
                        
        bool matchType = true;
        if (_selectedType == 'Intern' && !isIntern) matchType = false;
        if (_selectedType == 'Schüler' && isIntern) matchType = false;

        bool matchMonth = true;
        if (_selectedMonth != 'Alle Monate' && entry['start_zeit'] != null) {
          try {
            DateTime dt = DateTime.parse(entry['start_zeit']);
            String entryMonth = "${dt.month.toString().padLeft(2, '0')}.${dt.year}";
            if (entryMonth != _selectedMonth) matchMonth = false;
          } catch (_) {
            matchMonth = false;
          }
        }

        return matchType && matchMonth;
      }).toList();
      
      _recalculateTotal(); 
    });
  }

  void _resetFilter() {
    setState(() {
      _selectedMonth = 'Alle Monate';
      _selectedType = 'Alle Einträge';
      _filteredEntries = List.from(_allEntries); 
      _recalculateTotal();
    });
  }

  void _recalculateTotal() {
    double sumHours = 0.0;
    for (var entry in _filteredEntries) {
      if (entry['start_zeit'] != null && entry['ende_zeit'] != null) {
        try {
          DateTime start = DateTime.parse(entry['start_zeit']);
          DateTime end = DateTime.parse(entry['ende_zeit']);
          sumHours += end.difference(start).inMinutes / 60.0;
        } catch (_) {}
      }
    }
    _totalNetHours = sumHours;
  }

  // --- HILFSMETHODEN FÜR DIE UI ---

  String _formatTime(String? dateString) {
    if (dateString == null) return "--:--";
    try {
      DateTime dt = DateTime.parse(dateString);
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return "--:--";
    }
  }

  String _formatDateOnly(String? dateString) {
    if (dateString == null) return "--.--.----";
    try {
      DateTime dt = DateTime.parse(dateString);
      return "${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}";
    } catch (_) {
      return "--.--.----";
    }
  }

  String _calculateNet(String? start, String? end) {
    if (start == null || end == null) return "0,00 h";
    try {
      DateTime dtStart = DateTime.parse(start);
      DateTime dtEnd = DateTime.parse(end);
      double hours = dtEnd.difference(dtStart).inMinutes / 60.0;
      return "${hours.toStringAsFixed(2).replaceAll('.', ',')} h";
    } catch (_) {
      return "0,00 h";
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color brandGreen = Color(0xFF328554);
    const Color brandBlue = Color(0xFF4466F2);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Meine Zeiteinträge'),
        backgroundColor: Colors.white,
        foregroundColor: brandGreen,
        elevation: 1,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: brandGreen))
        : ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const Text(
                'Historie deiner erfassten Einsätze.',
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
              const SizedBox(height: 24),

              _buildFilterSection(brandBlue),
              const SizedBox(height: 16),
              _buildSumBox(brandBlue, _totalNetHours),
              const SizedBox(height: 24),

              _buildInfoBox(
                title: 'Externer Abschluss noch gesperrt',
                subtitle: 'Nachweis der Begleitstunden für die Abrechnung mit dem Kostenträger.',
                icon: Icons.lock_outline,
                borderColor: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              _buildInfoBox(
                title: 'Interner Abschluss noch gesperrt',
                subtitle: 'Bestätigung Ihrer bürointernen Zeiten und Fahrtzeiten für die Lohnabrechnung.',
                icon: Icons.lock_outline,
                borderColor: Colors.lightBlue.shade300,
                titleColor: Colors.lightBlue.shade600,
              ),
              const SizedBox(height: 32),

              Text('ERFASSTE ZEITEN (${_filteredEntries.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 12),
              
              if (_filteredEntries.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: Text("Keine Einträge für diesen Filter gefunden.", style: TextStyle(color: Colors.black54))),
                )
              else
                ..._filteredEntries.map((entry) => _buildEntryCard(entry)).toList(),
            ],
          ),
    );
  }

  Widget _buildFilterSection(Color brandBlue) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ZEITRAUM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 4),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(6)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedMonth,
                items: _availableMonths.map((String month) {
                  return DropdownMenuItem<String>(value: month, child: Text(month));
                }).toList(),
                onChanged: (newValue) {
                  setState(() => _selectedMonth = newValue!);
                },
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          const Text('TYP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 4),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(6)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedType,
                items: ['Alle Einträge', 'Intern', 'Schüler'].map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (newValue) {
                  setState(() => _selectedType = newValue!);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _applyFilter, 
                  icon: const Icon(Icons.filter_list, size: 18),
                  label: const Text('Filtern'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _resetFilter, 
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black54,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text('Reset'),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSumBox(Color brandBlue, double totalHours) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: brandBlue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Text('NETTO-SUMME (FILTER)', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('${totalHours.toStringAsFixed(2).replaceAll('.', ',')} h', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInfoBox({required String title, required String subtitle, required IconData icon, required Color borderColor, Color? titleColor}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(border: Border(left: BorderSide(color: borderColor, width: 4))),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: titleColor ?? Colors.black87),
                  const SizedBox(width: 8),
                  Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: titleColor ?? Colors.black87))),
                ],
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEntryCard(Map<String, dynamic> entry) {
    // 1. TYP ERMITTELN (Robuste Überprüfung)
    bool isIntern = entry['is_internal'] == 1 || 
                    entry['is_internal'] == '1' || 
                    entry['is_internal'] == true || 
                    entry['typ'] == 'arbeit';
    String typLabel = isIntern ? 'Intern' : 'Schüler';
    
    // 2. DETAILS ERMITTELN (Robuste Überprüfung für Notiz und Schüler)
    String notiz = entry['notiz']?.toString() ?? entry['description']?.toString() ?? '';
    String details = notiz;

    if (!isIntern) {
      // Wenn es ein Schüler ist, versuche den Namen aus der API zu holen
      String studentName = "";
      if (entry['schueler'] != null && entry['schueler']['name'] != null) {
        studentName = entry['schueler']['name'].toString();
      } else if (entry['student'] != null && entry['student']['name'] != null) {
        studentName = entry['student']['name'].toString();
      } else if (entry['schueler_name'] != null) {
        studentName = entry['schueler_name'].toString();
      }
      
      // Den Schülernamen und die Notiz kombinieren
      if (studentName.isNotEmpty) {
        details = notiz.isNotEmpty ? "$studentName\n$notiz" : studentName;
      } else if (notiz.isEmpty) {
        details = "Schüler-Leistung"; // Fallback, falls die API gar nichts sendet
      }
    }

    // Status
    String status = entry['status'] ?? 'Offen'; 
    bool isLocked = status.toLowerCase() == 'gesperrt' || status.toLowerCase() == 'abgeschlossen';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDateOnly(entry['start_zeit']), style: const TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Icon(isLocked ? Icons.lock : Icons.lock_open, size: 14, color: isLocked ? Colors.grey : Colors.green),
                    const SizedBox(width: 4),
                    Text(status, style: TextStyle(color: isLocked ? Colors.grey : Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start, // Wichtig falls die Notiz lang ist
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isIntern ? Colors.blue.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: isIntern ? Colors.blue.shade200 : Colors.green.shade200),
                  ),
                  child: Text(
                    typLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isIntern ? Colors.blue.shade700 : Colors.green.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (details.isNotEmpty)
                  Expanded(
                    child: Text(
                      details,
                      style: const TextStyle(fontSize: 14),
                      // overflow: TextOverflow.ellipsis, -> Entfernt, damit man die ganze Notiz lesen kann!
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text("${_formatTime(entry['start_zeit'])} - ${_formatTime(entry['ende_zeit'])}", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
                Text(
                  _calculateNet(entry['start_zeit'], entry['ende_zeit']),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}