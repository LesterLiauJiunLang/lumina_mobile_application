import 'package:flutter/material.dart';
import 'model/student.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    final student = ModalRoute.of(context)!.settings.arguments as Student;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F9),
      body: Column(
        children: [
          _buildHeader(student),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                _buildStatusCard(context, "Attendance", Icons.check_box_outlined, '/attendance_history', arguments: student),
                const SizedBox(width: 15),
                _buildStatusCard(context, "Billing", Icons.attach_money, '/billing', arguments: student),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 0.95,
                children: [
                  _buildMenuCard(context, "My Profile", Icons.person, const Color(0xFFE3F2FD), Colors.blue, '/profile', arguments: student),
                  _buildMenuCard(context, "Timetable", Icons.calendar_today, const Color(0xFFFFF3E0), Colors.orange, '/timetable', arguments: student),
                  _buildMenuCard(context, "Examination", Icons.assignment_outlined, const Color(0xFFF3E5F5), Colors.purple, '/examination', arguments: student),
                  _buildMenuCard(context, "My Quizzes", Icons.help_center_outlined, const Color(0xFFFFF8E1), Colors.amber[800]!, '/student_dashboard_quiz', arguments: student),
                  _buildMenuCard(context, "Results", Icons.star_border, const Color(0xFFE0F2F1), Colors.teal, '/results', arguments: student),
                  _buildMenuCard(context, "Helpline", Icons.face_retouching_natural, const Color(0xFFE0F7FA), Colors.cyan, '/helpline', arguments: student),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/attendance_scanner', arguments: student);
        },
        backgroundColor: const Color(0xFF005A9C),
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
      ),
    );
  }

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
          const CircleAvatar(
            radius: 38,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 35,
              backgroundColor: Color(0xFFBDBDBD),
              child: Icon(Icons.person, size: 45, color: Colors.white),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(student.name ?? "N/A", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                Text("ID: ${student.id}", style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 4),
                Text(student.programme ?? "Programme not set", style: const TextStyle(color: Colors.white60, fontSize: 12, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, String title, IconData icon, String routeName, {dynamic arguments}) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, routeName, arguments: arguments);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: const Color(0xFF005A9C)),
                  const SizedBox(width: 6),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 4),
              const Text("View Summary", style: TextStyle(fontSize: 10, color: Colors.grey)),
              const Text("0", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, Color bgColor, Color iconColor, String routeName, {dynamic arguments}) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, routeName, arguments: arguments),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 38)),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
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
      onTap: (i) {
        if (i == 2) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        else setState(() => _selectedIndex = i);
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Student"),
        BottomNavigationBarItem(icon: Icon(Icons.badge_outlined), label: "Staff"),
        BottomNavigationBarItem(icon: Icon(Icons.school_outlined), label: "Alumni"),
      ],
    );
  }
}
