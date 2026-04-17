import 'package:flutter/material.dart';

class AnnouncementScreen extends StatelessWidget {
  const AnnouncementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable Announcements'),
        backgroundColor: Color(0xFF005A9C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: ListTile(
              title: Text('New Timetable for Next Semester'),
              subtitle: Text('Posted on March 1, 2026'),
            ),
          ),
          Card(
            child: ListTile(
              title: Text('Exam Schedule Updated'),
              subtitle: Text('Please check your emails.'),
            ),
          ),
        ],
      ),
    );
  }
}