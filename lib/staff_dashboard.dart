import 'package:flutter/material.dart';
import 'model/staff.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  // Staff is the 3rd item (Index 2) in your list
  int _selectedIndex = 2;

  @override
  Widget build(BuildContext context) {
    // 1. Catch the staff data passed from Login
    final staff = ModalRoute.of(context)!.settings.arguments as Staff;

    // 2. Identify Role: Is this person a Superadmin?
    bool isSuperAdmin = staff.jobTitle?.toLowerCase() == 'superadmin';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F9),
      body: Column(
        children: [
          // Header color changes: Dark Navy for Admin, Royal Blue for Staff
          _buildHeader(
              staff,
              isSuperAdmin ? const Color(0xFF1A237E) : const Color(0xFF005A9C)
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              children: [
                // --- SECTION A: ADMIN ONLY ---
                if (isSuperAdmin) ...[
                  const Row(
                    children: [
                      Icon(Icons.admin_panel_settings, color: Colors.redAccent, size: 18),
                      SizedBox(width: 8),
                      Text("ADMINISTRATIVE CONTROL",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, letterSpacing: 1.1)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildMenuButton(context, "Student Management", Icons.people_alt_outlined, '/view_user'),
                  _buildMenuButton(context, "Register New Student", Icons.person_add_alt_1_outlined, '/register_student'),
                  _buildMenuButton(context, "Staff Directory", Icons.badge_outlined, '/view_staff'),
                  const SizedBox(height: 25),
                  const Divider(),
                  const SizedBox(height: 15),
                ],

                // --- SECTION B: ACADEMIC TOOLS (Visible to All Staff) ---
                const Text("ACADEMIC TOOLS",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 12),
                _buildMenuButton(context, "Create Quiz / Assessment", Icons.quiz_outlined, '/create_quiz'),
                _buildMenuButton(context, "My Teaching Classes", Icons.menu_book_outlined, '/staff_classes'),
                _buildMenuButton(context, "Student Attendance", Icons.fact_check_outlined, '/attendance'),

                const SizedBox(height: 25),

                // --- SECTION C: SETTINGS ---
                const Text("SETTINGS",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 12),
                _buildMenuButton(context, "My Profile", Icons.account_circle_outlined, '/staff_profile', args: staff),

                const SizedBox(height: 30),

                // --- LOGOUT ---
                _buildLogoutButton(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- UI COMPONENTS ---

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
            decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
            child: const CircleAvatar(
              radius: 35,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Color(0xFF005A9C)),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  staff.name ?? "Staff Member",
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    staff.jobTitle?.toUpperCase() ?? "STAFF",
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String label, IconData icon, String route, {dynamic args}) {
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        onPressed: () => Navigator.pushNamed(context, route, arguments: args),
        icon: Icon(icon, size: 26),
        label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Center(
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false),
        icon: const Icon(Icons.logout, color: Colors.red, size: 20),
        label: const Text("Sign Out", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      ),
    );
  }



  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      selectedItemColor: const Color(0xFF005A9C),
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      onTap: (i) {
        setState(() {
          _selectedIndex = i;
        });

        // Navigation Logic
        if (i == 1) {
          // Switch to Student mode (Goes back to login)
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Student"),
        BottomNavigationBarItem(icon: Icon(Icons.badge_outlined), label: "Staff"),
        BottomNavigationBarItem(icon: Icon(Icons.school_outlined), label: "Alumni"),
      ],
    );
  }
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

                  _buildMenuButton(context, "Student Management",
                      Icons.people_alt_outlined, '/view_user'),

                  _buildMenuButton(context, "Register New Student",
                      Icons.person_add_alt_1_outlined, '/register_student'),

                  _buildMenuButton(context, "Staff Directory",
                      Icons.badge_outlined, '/view_staff'),

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
                    Icons.menu_book_outlined, '/staff_classes'),

                _buildMenuButton(context, "Student Attendance",
                    Icons.fact_check_outlined, '/attendance'),

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
            context, '/login', (route) => false),
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
        setState(() {
          _selectedIndex = i;
        });

        if (i == 1) {
          Navigator.pushNamedAndRemoveUntil(
              context, '/login', (route) => false);
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
}