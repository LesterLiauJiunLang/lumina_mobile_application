import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class StudentAttendanceScanner extends StatefulWidget {
  const StudentAttendanceScanner({super.key});

  @override
  State<StudentAttendanceScanner> createState() => _StudentAttendanceScannerState();
}

class _StudentAttendanceScannerState extends State<StudentAttendanceScanner> {
  final supabase = Supabase.instance.client;
  final TextEditingController _tokenController = TextEditingController();
  bool _isLoading = false;
  bool _isScannerOpen = false;
  final String studentId = '26WMR00009'; // Prototype student

  // Custom theme color
  final Color _mainBlue = const Color(0xFF005A9C);

  DateTime _parseTime(String timeStr) {
    final now = DateTime.now();
    final parts = timeStr.split(':');
    return DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
  }

  Future<void> _submitToken(String token) async {
    if (token.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      final sessionData = await supabase
          .from('AttendanceSession')
          .select('ID, Course_ID, Course(Name), Schedule:Schedule_ID(StartTime, EndTime)')
          .eq('QR_Token', token)
          .maybeSingle();

      if (sessionData == null) {
        throw 'Invalid QR Code or Token.';
      }

      final now = DateTime.now();
      final schedule = sessionData['Schedule'];

      if (schedule != null) {
        final startTime = _parseTime(schedule['StartTime']);
        final endTime = _parseTime(schedule['EndTime']);

        if (now.isBefore(startTime) || now.isAfter(endTime)) {
          throw 'Attendance for this session is only available during class time (${schedule['StartTime']} - ${schedule['EndTime']}). Please contact your lecturer for manual entry.';
        }
      }

      final sessionId = sessionData['ID'];
      final courseName = sessionData['Course']['Name'];

      await supabase.from('AttendanceRecord').upsert({
        'Session_ID': sessionId,
        'Student_ID': studentId,
        'Status': 'Present',
        'MarkedAt': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        _showSuccessDialog(context, courseName);
        _tokenController.clear();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isScannerOpen = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Scanner'),
        backgroundColor: _mainBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Attendance Window', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text('Mark attendance during scheduled class time.', textAlign: TextAlign.center, style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            Center(
              child: Container(
                width: 280, height: 280,
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20), border: Border.all(color: _mainBlue, width: 4)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_isScannerOpen)
                        MobileScanner(
                          onDetect: (capture) {
                            final List<Barcode> barcodes = capture.barcodes;
                            for (final barcode in barcodes) {
                              if (barcode.rawValue != null) {
                                _submitToken(barcode.rawValue!);
                                break;
                              }
                            }
                          },
                        )
                      else
                        const Opacity(opacity: 0.3, child: Icon(Icons.qr_code_scanner, size: 180, color: Colors.white)),
                      const _ScanningLine(),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() => _isScannerOpen = !_isScannerOpen),
              icon: Icon(_isScannerOpen ? Icons.stop : Icons.camera_alt),
              label: Text(_isScannerOpen ? 'Stop Scanner' : 'Open QR Scanner'),
              style: ElevatedButton.styleFrom(backgroundColor: _isScannerOpen ? Colors.red : _mainBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
            const SizedBox(height: 32),
            const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('OR ENTER TOKEN', style: TextStyle(color: Colors.grey, fontSize: 12))), Expanded(child: Divider())]),
            const SizedBox(height: 16),
            TextField(
              controller: _tokenController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 10,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 4),
              decoration: InputDecoration(
                hintText: 'e.g. 123456', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), counterText: "",
                suffixIcon: IconButton(icon: Icon(Icons.send, color: _mainBlue), onPressed: () => _submitToken(_tokenController.text)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Attendance Failed', style: TextStyle(color: Colors.red)), content: Text(message), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]));
  }

  void _showSuccessDialog(BuildContext context, String courseName) {
    showDialog(context: context, builder: (context) => AlertDialog(title: const Row(children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 10), Text('Success')]), content: Text('You have marked attendance for $courseName.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]));
  }
}

class _ScanningLine extends StatefulWidget {
  const _ScanningLine();
  @override
  State<_ScanningLine> createState() => _ScanningLineState();
}

class _ScanningLineState extends State<_ScanningLine> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(top: 40 + (_controller.value * 200), child: Container(width: 220, height: 2, decoration: BoxDecoration(color: Colors.greenAccent, boxShadow: [BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2)])));
      },
    );
  }
}