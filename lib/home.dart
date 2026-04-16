import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF005A9C),
        title: const Text("Lumina Portal", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo or Icon
            const Icon(Icons.school, size: 100, color: Color(0xFF005A9C)),
            const SizedBox(height: 40),

            // Button 1: Login
            _buildMenuButton(
                context,
                "User Login",
                Icons.login,
                '/login'
            ),

            const SizedBox(height: 15),

            // Button 2: View Students
            _buildMenuButton(
                context,
                "Student Management",
                Icons.people,
                '/view_user'
            ),

            const SizedBox(height: 15),

            // Button 3: Add New Student
            _buildMenuButton(
                context,
                "Register Student",
                Icons.person_add,
                '/register_student'
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to create consistent buttons
  Widget _buildMenuButton(BuildContext context, String label, IconData icon, String route) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF005A9C),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () => Navigator.pushNamed(context, route),
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}