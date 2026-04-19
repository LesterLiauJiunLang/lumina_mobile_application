import 'package:flutter/material.dart';
import 'model/student.dart'; // Ensure your Student model is imported
import 'package:supabase_flutter/supabase_flutter.dart';
class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    _selectedIndex = 1;
    // 1. CATCH THE STUDENT DATA FROM LOGIN PAGE
    final student = ModalRoute.of(context)!.settings.arguments as Student;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F9),
      body: Column(
        children: [
          // Inside StudentDashboard Column:
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: Supabase.instance.client
                .from('Student')
                .stream(primaryKey: ['ID'])
                .eq('ID', student.id),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                // Get the live URL from the database
                final liveImageUrl = snapshot.data!.first['profile_image'];
                student.profileImage = liveImageUrl; // Sync the object
              }
              return _buildHeader(student);
            },
          ),

          /// TOP CARDS
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                _buildStatusCard(
                  context,
                  "Attendance",
                  Icons.check_box_outlined,
                  '/attendance_history',
                  student,
                ),
                const SizedBox(width: 15),
                _buildStatusCard(
                  context,
                  "Billing",
                  Icons.attach_money,
                  '/billing',
                  student,
                ),
              ],
            ),
          ),

          /// GRID MENU
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 0.95,
                children: [
                  _buildMenuCard(context, "My Profile", Icons.person,
                      const Color(0xFFE3F2FD), Colors.blue, '/profile', student),

                  _buildMenuCard(context, "Timetable", Icons.calendar_today,
                      const Color(0xFFFFF3E0), Colors.orange, '/timetable', student),

                  _buildMenuCard(context, "Examination",
                      Icons.assignment_outlined,
                      const Color(0xFFF3E5F5), Colors.purple, '/examination', student),

                  /// ✅ IMPORTANT: PASS STUDENT HERE
                  _buildMenuCard(context, "My Quizzes",
                      Icons.help_center_outlined,
                      const Color(0xFFFFF8E1),
                      Colors.amber[800]!,
                      '/student_dashboard_quiz',
                      student),

                  _buildMenuCard(context, "Results", Icons.star_border,
                      const Color(0xFFE0F2F1), Colors.teal, '/results', student),

                  _buildMenuCard(context, "Helpline",
                      Icons.face_retouching_natural,
                      const Color(0xFFE0F7FA), Colors.cyan, '/helpline', student),
                ],
              ),
            ),
          ),
        ],
      ),

      /// BOTTOM NAV
      bottomNavigationBar: _buildBottomNav(),

      /// FLOATING BUTTON
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/attendance_scanner',
            arguments: student,
          );
        },
        backgroundColor: const Color(0xFF005A9C),
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader(Student student) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(25, 50, 25, 25),
      decoration: const BoxDecoration(
        color: Color(0xFF005A9C),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: CircleAvatar(
                  radius: 38,
                  backgroundColor: const Color(0xFFF3F6F9),
                  // Logic: If profileImage URL exists, show it. Otherwise show default icon.
                  backgroundImage: student.profileImage != null
                      ? NetworkImage(student.profileImage!)
                      : null,
                  child: student.profileImage == null
                      ? const Icon(Icons.person, size: 45, color: Color(0xFFBDBDBD))
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    // Navigate to profile to change photo
                    Navigator.pushNamed(context, '/profile', arguments: student);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name ?? "N/A",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  "ID: ${student.id}",
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  student.programme ?? "Programme not set",
                  style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= STATUS CARD =================
  Widget _buildStatusCard(BuildContext context, String title,
      IconData icon, String route, Student student) {
    return Expanded(
      child: GestureDetector(
        onTap: () =>
            Navigator.pushNamed(context, route, arguments: student),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8)
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: const Color(0xFF005A9C)),
                  const SizedBox(width: 6),
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              const Text("View Summary",
                  style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  // ================= MENU CARD =================
  Widget _buildMenuCard(BuildContext context, String title, IconData icon,
      Color bgColor, Color iconColor, String route, Student student) {
    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, route, arguments: student),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03), blurRadius: 10)
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration:
              BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 38),
            ),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      selectedItemColor: const Color(0xFF005A9C),
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      elevation: 20,

      onTap: (i) {
        if (i == _selectedIndex) return;

        if (i == 2) {
          // 1. If "Staff" is clicked, send them to login to switch roles
          Navigator.pushNamed(context, '/login', arguments: 'Staff');
        } if (i == 0) {
          // If you want Home (index 0) to be accessible
          Navigator.pushNamed(context, '/');
        }else if (i == 3) {
          _showComingSoonSnackBar("Alumni");
        }
        else {
          // 3. Logic for Alumni (3) if you have those pages
          setState(() => _selectedIndex = i);
        }
      },
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined), label: "Home"),
        BottomNavigationBarItem(
            icon: Icon(Icons.person), label: "Student"),
        BottomNavigationBarItem(
            icon: Icon(Icons.badge_outlined), label: "Staff"),
        BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined), label: "Alumni"),
      ],
    );
  }

  void _showComingSoonSnackBar(String portalName) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF005A9C), // Primary Blue
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.orangeAccent, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$portalName Portal",
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                    const Text(
                      "This feature is currently in progress!",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

}