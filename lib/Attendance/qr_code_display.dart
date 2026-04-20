import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:math';
import 'package:intl/intl.dart';

class QRCodeDisplay extends StatefulWidget {
  final String courseName;
  final String courseId;
  final String? staffId;
  final String section;
  final String? scheduleId; 

  const QRCodeDisplay({
    super.key,
    required this.courseName,
    required this.courseId,
    required this.staffId,
    required this.section,
    this.scheduleId,
  });

  @override
  State<QRCodeDisplay> createState() => _QRCodeDisplayState();
}

class _QRCodeDisplayState extends State<QRCodeDisplay> {
  final supabase = Supabase.instance.client;
  bool _isGenerating = true;
  String? _qrToken;
  String? _error;
  Map<String, dynamic>? _currentSchedule;
  final Color _mainBlue = const Color(0xFF005A9C);

  @override
  void initState() {
    super.initState();
    _checkScheduleAndGenerate();
  }

  DateTime _parseTime(String timeStr) {
    final now = DateTime.now();
    final parts = timeStr.split(':');
    return DateTime(
      now.year, 
      now.month, 
      now.day, 
      int.parse(parts[0]), 
      int.parse(parts[1]), 
      parts.length > 2 ? int.parse(parts[2]) : 0
    );
  }

  Future<void> _checkScheduleAndGenerate() async {
    try {
      final now = DateTime.now();
      final todayDate = DateFormat('yyyy-MM-dd').format(now);
      Map<String, dynamic>? targetSlot;

      if (widget.scheduleId != null) {
        final data = await supabase.from('Schedule').select().eq('ID', widget.scheduleId!).single();
        targetSlot = Map<String, dynamic>.from(data);
      } else {
        final dayName = DateFormat('EEEE', 'en_US').format(now).toUpperCase();
        final List<dynamic> scheduleData = await supabase.from('Schedule').select().eq('Course_ID', widget.courseId).eq('DayOfWeek', dayName);

        for (var slot in scheduleData) {
          final startTime = _parseTime(slot['StartTime']);
          final endTime = _parseTime(slot['EndTime']);
          final allowFrom = startTime.subtract(const Duration(minutes: 30));
          if (!now.isBefore(allowFrom) && !now.isAfter(endTime)) {
            targetSlot = Map<String, dynamic>.from(slot);
            break;
          }
        }
      }

      if (targetSlot == null) {
        setState(() { 
          _error = "No active session found for this course at this time."; 
          _isGenerating = false; 
        });
        return;
      }

      // Time Validation Logic
      final startTime = _parseTime(targetSlot['StartTime']);
      final endTime = _parseTime(targetSlot['EndTime']);
      final allowFrom = startTime.subtract(const Duration(minutes: 30));

      if (now.isBefore(allowFrom)) {
        setState(() {
          _error = "Class hasn't started yet.\n\n"
                  "Scheduled: ${targetSlot!['StartTime']} - ${targetSlot['EndTime']}\n"
                  "QR generation will be available at ${DateFormat('HH:mm').format(allowFrom)} (30 mins before).";
          _isGenerating = false;
        });
        return;
      }

      if (now.isAfter(endTime)) {
        setState(() {
          _error = "Class duration has already ended.\n\n"
                  "Scheduled: ${targetSlot!['StartTime']} - ${targetSlot['EndTime']}";
          _isGenerating = false;
        });
        return;
      }

      _currentSchedule = targetSlot;

      final existingSessions = await supabase
          .from('AttendanceSession')
          .select()
          .eq('Course_ID', widget.courseId)
          .eq('Date', todayDate)
          .eq('Schedule_ID', targetSlot['ID'])
          .limit(1);

      if ((existingSessions as List).isNotEmpty) {
        _qrToken = existingSessions[0]['QR_Token'];
        setState(() { _isGenerating = false; });
        return;
      }

      final random = Random();
      final token = List.generate(6, (index) => random.nextInt(10)).join();

      await supabase.from('AttendanceSession').insert({
        'Course_ID': widget.courseId, 
        'QR_Token': token, 
        'CreatedBy': widget.staffId, 
        'Date': todayDate, 
        'Schedule_ID': targetSlot['ID'],
      });

      _qrToken = token;
      setState(() { _isGenerating = false; });
    } catch (e) { 
      debugPrint('Generation Error: $e');
      setState(() { _error = "System Error: $e"; _isGenerating = false; }); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Class QR Code'), backgroundColor: _mainBlue, foregroundColor: Colors.white),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: _isGenerating
              ? const CircularProgressIndicator()
              : _error != null
              ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.timer_off_outlined, size: 80, color: Colors.orange),
                  const SizedBox(height: 24),
                  const Text('Outside Class Hours', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.black54, height: 1.5)),
                  const SizedBox(height: 40),
                  ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _mainBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)), onPressed: () => Navigator.pop(context), child: const Text('Go Back'))
                ])
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(widget.courseName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _mainBlue), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Scheduled: ${_currentSchedule!['StartTime']} - ${_currentSchedule!['EndTime']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _mainBlue, width: 4), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15)]), child: QrImageView(data: _qrToken!, version: QrVersions.auto, size: 240.0, foregroundColor: const Color(0xFF003366))),
            const SizedBox(height: 30),
            const Text('STUDENT TOKEN', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 2)),
            const SizedBox(height: 8),
            Text(_qrToken!, style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 8, fontSize: 32, color: _mainBlue)),
          ]),
        ),
      ),
    );
  }
}
