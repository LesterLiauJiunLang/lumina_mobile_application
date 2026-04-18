import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QuizQRGeneratorScreen extends StatelessWidget {
  final String quizId;
  final String quizTitle;

  const QuizQRGeneratorScreen({
    super.key,
    required this.quizId,
    required this.quizTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F9),
      appBar: AppBar(
        title: const Text("Quiz QR Code"),
        backgroundColor: const Color(0xFF005A9C),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                quizTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              // 🔥 QR CODE
              QrImageView(
                data: quizId, // ✅ IMPORTANT
                size: 220,
              ),

              const SizedBox(height: 20),

              Text(
                "Quiz ID: $quizId",
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}