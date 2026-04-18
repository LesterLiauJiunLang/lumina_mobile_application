import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'db/supabase_service.dart';
import 'student_attempt_quiz.dart';

class StudentQRScannerScreen extends StatefulWidget {
  final String studentId;

  const StudentQRScannerScreen({super.key, required this.studentId});

  @override
  State<StudentQRScannerScreen> createState() =>
      _StudentQRScannerScreenState();
}

class _StudentQRScannerScreenState extends State<StudentQRScannerScreen>
    with SingleTickerProviderStateMixin {

  final MobileScannerController _controller = MobileScannerController();

  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3), // smoother
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.linear),
    );
  }

  void _showStatusSnackbar(String title, String message, bool isSuccess) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final color = isSuccess ? Colors.green : Colors.red;
    final icon =
    isSuccess ? Icons.check_circle_rounded : Icons.error_rounded;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "$title\n$message",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scanController.dispose();
    super.dispose();
  }

  // ✅ QR detection
  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    if (capture.barcodes.isEmpty) return;

    final raw = capture.barcodes.first.rawValue;
    if (raw == null) return;

    _controller.stop();
    setState(() => _isProcessing = true);

    final quiz = await SupabaseService.getQuizById(raw);

    if (!mounted) return;

    if (quiz == null) {
      _showStatusSnackbar("Not Found", "Invalid QR Code", false);
      _controller.start();
      setState(() => _isProcessing = false);
      return;
    }

    final title = quiz['title'] ?? "Untitled";
    final topic = quiz['topic'] ?? "General";
    final duration = quiz['duration'] ?? 0;

    final confirm = await _showQuizDialog(title, topic, duration);

    if (!mounted) return;

    if (confirm == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StudentAttemptQuizScreen(
            quizId: raw,
            quizTitle: title,
            studentId: widget.studentId,
          ),
        ),
      );
    } else {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _controller.start();
          setState(() => _isProcessing = false);
        }
      });
    }
  }

  // ✅ Dialog
  Future<bool?> _showQuizDialog(
      String title, String topic, int duration) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text("Start Quiz"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(Icons.category, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(topic)),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(Icons.timer, size: 18),
                const SizedBox(width: 8),
                Text("$duration minutes"),
              ],
            ),

            const SizedBox(height: 14),

            const Text(
              "Do you want to start this quiz?",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF005A9C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Start",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ✅ Overlay with green scanning line
  Widget _buildScannerOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxSize = constraints.maxWidth * 0.7;

        return Stack(
          children: [
            Container(color: Colors.black.withOpacity(0.5)),

            Center(
              child: SizedBox(
                width: boxSize,
                height: boxSize,
                child: Stack(
                  children: [
                    // Border
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),

                    // 🟢 Animated scan line
                    AnimatedBuilder(
                      animation: _scanAnimation,
                      builder: (context, child) {
                        return Positioned(
                          top: _scanAnimation.value * (boxSize - 4),
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.7),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // Corners
                    CustomPaint(
                      size: Size(boxSize, boxSize),
                      painter: _CornerPainter(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Quiz QR"),
        backgroundColor: const Color(0xFF005A9C),
        foregroundColor: Colors.white,
      ),

      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          _buildScannerOverlay(),

          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Align QR code within frame",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ Corner painter
class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const length = 25.0;
    const stroke = 4.0;

    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke;

    // corners
    canvas.drawLine(Offset(0, 0), Offset(length, 0), paint);
    canvas.drawLine(Offset(0, 0), Offset(0, length), paint);

    canvas.drawLine(
        Offset(size.width, 0),
        Offset(size.width - length, 0),
        paint);
    canvas.drawLine(
        Offset(size.width, 0),
        Offset(size.width, length),
        paint);

    canvas.drawLine(
        Offset(0, size.height),
        Offset(0, size.height - length),
        paint);
    canvas.drawLine(
        Offset(0, size.height),
        Offset(length, size.height),
        paint);

    canvas.drawLine(
        Offset(size.width, size.height),
        Offset(size.width - length, size.height),
        paint);
    canvas.drawLine(
        Offset(size.width, size.height),
        Offset(size.width, size.height - length),
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}