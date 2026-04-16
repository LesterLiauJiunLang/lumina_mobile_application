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
  final bool sendToEmail;

  const QRCodeDisplay({
    super.key,
    required this.courseName,
    required this.courseId,
    required this.staffId,
    required this.section,
    required this.sendToEmail,
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

  @override
  void initState() {
    super.initState();
    _checkScheduleAndGenerate();
  }

  DateTime _parseTime(String timeStr) {
    final now = DateTime.now();
    final parts = timeStr.split(':');
    return DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
  }

  Future<void> _checkScheduleAndGenerate() async {
    try {
      final now = DateTime.now();
      final dayName = DateFormat('EEEE').format(now);
      final todayDate = DateFormat('yyyy-MM-dd').format(now);

      final scheduleData = await supabase.from('Schedule').select().eq('Course_ID', widget.courseId).eq('DayOfWeek', dayName);

      final currentSlot = (scheduleData as List).firstWhere(
            (slot) {
          final startTime = _parseTime(slot['StartTime']);
          final endTime = _parseTime(slot['EndTime']);
          final allowFrom = startTime.subtract(const Duration(minutes: 30));
          return now.isAfter(allowFrom) && now.isBefore(endTime);
        },
        orElse: () => null,
      );

      if (currentSlot == null) {
        setState(() { _error = "Access Denied: You can only generate a QR code 30 minutes before or during the scheduled class time."; _isGenerating = false; });
        return;
      }

      _currentSchedule = currentSlot;

      final existingSession = await supabase.from('AttendanceSession').select().eq('Course_ID', widget.courseId).eq('Date', todayDate).eq('Schedule_ID', currentSlot['ID']).maybeSingle();

      if (existingSession != null) {
        setState(() { _qrToken = existingSession['QR_Token']; _isGenerating = false; });
        return;
      }

      final random = Random();
      final token = List.generate(6, (index) => random.nextInt(10)).join();

      await supabase.from('AttendanceSession').insert({
        'Course_ID': widget.courseId, 'QR_Token': token, 'CreatedBy': widget.staffId, 'Date': todayDate, 'Schedule_ID': currentSlot['ID'],
      });

      setState(() { _qrToken = token; _isGenerating = false; });
    } catch (e) { setState(() { _error = "Error: $e"; _isGenerating = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.sendToEmail ? 'Email QR' : 'Display QR'), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isGenerating
              ? const CircularProgressIndicator()
              : _error != null
              ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.lock_clock, size: 80, color: Colors.redAccent), const SizedBox(height: 16), const Text('Invalid Time', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 12), Text(_error!, textAlign: TextAlign.center), const SizedBox(height: 32), ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back'))])
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(widget.courseName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text('Class Time: ${_currentSchedule!['StartTime']} - ${_currentSchedule!['EndTime']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            if (!widget.sendToEmail) ...[
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.indigo, width: 3), borderRadius: BorderRadius.circular(20)), child: QrImageView(data: _qrToken!, version: QrVersions.auto, size: 250.0, foregroundColor: Colors.indigo.shade900)),
              const SizedBox(height: 20),
              Text('TOKEN: $_qrToken', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 4, fontSize: 18)),
            ] else ...[
              const Icon(Icons.mark_email_read, size: 80, color: Colors.green), const SizedBox(height: 24), const Text('QR Code Sent!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 40), ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Back'))
            ],
          ]),
        ),
      ),
    );
  }
}
