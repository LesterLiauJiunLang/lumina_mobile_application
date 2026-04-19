import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final Color _mainBlue = const Color(0xFF005A9C);

  @override
  void initState() {
    super.initState();
    _checkScheduleAndGenerate();
  }

  DateTime _parseTime(String timeStr) {
    final now = DateTime.now();
    final parts = timeStr.split(':');
    return DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]), parts.length > 2 ? int.parse(parts[2]) : 0);
  }

  Future<void> _checkScheduleAndGenerate() async {
    try {
      final now = DateTime.now();
      final dayName = DateFormat('EEEE').format(now).toUpperCase();
      final todayDate = DateFormat('yyyy-MM-dd').format(now);

      final List<dynamic> scheduleData = await supabase.from('Schedule').select().eq('Course_ID', widget.courseId).eq('DayOfWeek', dayName);

      Map<String, dynamic>? currentSlot;
      
      for (var slot in scheduleData) {
        final startTime = _parseTime(slot['StartTime']);
        final endTime = _parseTime(slot['EndTime']);
        // Allow generation 30 mins before class starts until it ends
        final allowFrom = startTime.subtract(const Duration(minutes: 30));
        
        if (now.isAfter(allowFrom) && now.isBefore(endTime)) {
          currentSlot = Map<String, dynamic>.from(slot);
          break;
        }
      }

      if (currentSlot == null) {
        setState(() { 
          _error = "Access Denied: No active session found. You can only generate a QR code during scheduled class time."; 
          _isGenerating = false; 
        });
        return;
      }

      _currentSchedule = currentSlot;

      final existingSession = await supabase
          .from('AttendanceSession')
          .select()
          .eq('Course_ID', widget.courseId)
          .eq('Date', todayDate)
          .eq('Schedule_ID', currentSlot['ID'])
          .maybeSingle();

      if (existingSession != null) {
        _qrToken = existingSession['QR_Token'];
        if (widget.sendToEmail) {
          await _launchEmail(_qrToken!);
        }
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
        'Schedule_ID': currentSlot['ID'],
      });

      _qrToken = token;
      if (widget.sendToEmail) {
        await _launchEmail(_qrToken!);
      }
      setState(() { _isGenerating = false; });
    } catch (e) { 
      debugPrint('Generation Error: $e');
      setState(() { _error = "System Error: $e"; _isGenerating = false; }); 
    }
  }

  Future<void> _launchEmail(String token) async {
    try {
      final enrollmentData = await supabase.from('Enrollment').select('Student(Email)').eq('Course_ID', widget.courseId);
      final emails = (enrollmentData as List).map((e) => e['Student']?['Email']?.toString()).where((email) => email != null && email.isNotEmpty).join(',');

      if (emails.isEmpty) return;

      final String subject = Uri.encodeComponent('Attendance Token: ${widget.courseName}');
      final String body = Uri.encodeComponent('Token for today: $token');
      final Uri emailUri = Uri.parse('mailto:$emails?subject=$subject&body=$body');

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      }
    } catch (e) { debugPrint('Email error: $e'); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.sendToEmail ? 'Email Attendance' : 'Class QR Code'), backgroundColor: _mainBlue, foregroundColor: Colors.white),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isGenerating
              ? const CircularProgressIndicator()
              : _error != null
              ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.lock_clock, size: 80, color: Colors.redAccent), const SizedBox(height: 16), const Text('Time Restriction', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 12), Text(_error!, textAlign: TextAlign.center), const SizedBox(height: 32), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _mainBlue, foregroundColor: Colors.white), onPressed: () => Navigator.pop(context), child: const Text('Go Back'))])
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(widget.courseName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _mainBlue), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Scheduled: ${_currentSchedule!['StartTime']} - ${_currentSchedule!['EndTime']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            if (!widget.sendToEmail) ...[
              Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _mainBlue, width: 4), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15)]), child: QrImageView(data: _qrToken!, version: QrVersions.auto, size: 240.0, foregroundColor: const Color(0xFF003366))),
              const SizedBox(height: 30),
              const Text('STUDENT TOKEN', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 2)),
              const SizedBox(height: 8),
              Text(_qrToken!, style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 8, fontSize: 32, color: _mainBlue)),
            ] else ...[
              const Icon(Icons.mark_email_read, size: 100, color: Colors.green), 
              const SizedBox(height: 24), 
              const Text('Email Ready!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), 
              const SizedBox(height: 12),
              const Text('Opening email app...', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40), 
              ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _mainBlue, foregroundColor: Colors.white), onPressed: () => Navigator.pop(context), child: const Text('Back to Dashboard'))
            ],
          ]),
        ),
      ),
    );
  }
}
