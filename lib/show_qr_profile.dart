import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../model/student.dart';

class ShowQRPage extends StatelessWidget {
  const ShowQRPage({super.key});

  // Optimized build method for ShowQRPage
  @override
  Widget build(BuildContext context) {
    final student = ModalRoute.of(context)!.settings.arguments as Student;

    // Inside ShowQRPage build method
    final String studentData = jsonEncode({
      "id": student.id,
      "name": student.name,
      "programme": student.programme,
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F9), // Light grey background
      appBar: AppBar(
        title: const Text(
            "My Student QR",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        backgroundColor: const Color(0xFF005A9C),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Professional QR Card
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                children: [
                  Text(
                    student.name?.toUpperCase() ?? "STUDENT",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF005A9C)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "ID: ${student.id}",
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const Divider(height: 40),
                  QrImageView(
                    data: studentData,
                    version: QrVersions.auto,
                    size: 220.0,
                    gapless: false,
                    foregroundColor: const Color(0xFF263238), // Darker for better scan reliability
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.security, color: Colors.green, size: 18),
                SizedBox(width: 8),
                Text(
                  "SECURE VERIFICATION CODE",
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}