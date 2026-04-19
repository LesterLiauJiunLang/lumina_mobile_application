import 'package:flutter/material.dart';
import 'model/staff.dart';


class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  int _selectedIndex = 2;

  @override
  Widget build(BuildContext context) {
    _selectedIndex = 2;
    final staff = ModalRoute.of(context)!.settings.arguments as Staff;

    bool isSuperAdmin = staff.jobTitle?.toLowerCase() == 'superadmin';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F9),
      bottomNavigationBar: _buildBottomNav(), // include bottom nav
      body: Column(
        children: [
          _buildHeader(
            staff,
            isSuperAdmin
                ? const Color(0xFF1A237E)
                : const Color(0xFF005A9C),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              children: [

                // ================= ADMIN SECTION =================
                if (isSuperAdmin) ...[
                  const Row(
                    children: [
                      Icon(Icons.admin_panel_settings,
                          color: Colors.redAccent, size: 18),
                      SizedBox(width: 8),
                      Text(
                        "ADMINISTRATIVE CONTROL",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _buildMenuButton(context, "Student Directory",
                      Icons.people_alt_outlined, '/student_directory'),

                  _buildMenuButton(context, "Staff Directory",
                      Icons.badge_outlined, '/staff_directory'),

                  const SizedBox(height: 25),
                  const Divider(),
                  const SizedBox(height: 15),
                ],

                // ================= ACADEMIC TOOLS =================
                const Text(
                  "ACADEMIC TOOLS",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      fontSize: 13),
                ),
                const SizedBox(height: 12),

                _buildMenuButton(context, "Quiz Management",
                    Icons.quiz_outlined, '/staff_dashboard_quiz'),


                _buildMenuButton(context, "My Teaching Classes",
                    Icons.menu_book_outlined, '/staff_timetable', args: staff),

                _buildMenuButton(context, "Student Attendance",
                    Icons.fact_check_outlined, '/attendance', args: staff),

                _buildMenuButton(context, "Announcements",
                    Icons.campaign_outlined, '/announcements', args: staff),

                const SizedBox(height: 25),

                // ================= SETTINGS =================
                const Text(
                  "SETTINGS",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      fontSize: 13),
                ),
                const SizedBox(height: 12),

                _buildMenuButton(context, "My Profile",
                    Icons.account_circle_outlined, '/staff_profile',
                    args: staff),

                const SizedBox(height: 30),

                // ================= LOGOUT =================
                _buildLogoutButton(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader(Staff staff, Color bgColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(25, 60, 25, 30),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
                color: Colors.white24, shape: BoxShape.circle),
            child: const CircleAvatar(
              radius: 35,
              backgroundColor: Colors.white,
              child: Icon(Icons.person,
                  size: 40, color: Color(0xFF005A9C)),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  staff.name ?? "Staff Member",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    staff.jobTitle?.toUpperCase() ?? "STAFF",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= MENU BUTTON =================
  Widget _buildMenuButton(BuildContext context, String label,
      IconData icon, String route,
      {dynamic args}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF005A9C),
          elevation: 0,
          minimumSize: const Size(double.infinity, 65),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15)),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        onPressed: () =>
            Navigator.pushNamed(context, route, arguments: args),
        icon: Icon(icon, size: 26),
        label: Text(
          label,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87),
        ),
      ),
    );
  }

  // ================= LOGOUT =================
  Widget _buildLogoutButton(BuildContext context) {
    return Center(
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          padding:
          const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30)),
        ),
        onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context, '/', (route) => false),
        icon: const Icon(Icons.logout, color: Colors.red, size: 20),
        label: const Text("Sign Out",
            style: TextStyle(
                color: Colors.red, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ================= BOTTOM NAV =================
  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      selectedItemColor: const Color(0xFF005A9C),
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      onTap: (i) {
        if (i == _selectedIndex) return;

        if (i == 1) {
          // 1. If "Student" is clicked, send them to login to switch roles
          Navigator.pushNamed(context, '/login', arguments: 'Student');
        } if (i == 0) {
          // If you want Home (index 0) to be accessible
          Navigator.pushNamed(context, '/');
        }else if (i == 3) {
          _showComingSoonSnackBar("Alumni");
        }
        else {
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