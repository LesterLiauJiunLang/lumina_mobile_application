import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // Home is index 0

  void _onItemTapped(int index) {
    // Navigation Logic
    switch (index) {
      case 0:
      // Stay on Home
        setState(() => _selectedIndex = 0);
        break;

      case 1: // Student Tab
      case 2: // Staff Tab
      // Do NOT call setState here. Keep highlight on Home (0).
        Navigator.pushNamed(context, '/login');
        break;

      case 3: // Alumni Tab
        _showBeautifulComingSoon();
        break;
    }
  }

  // Gets the current year for the Term (e.g., 2026)
  String get _currentYear => DateTime.now().year.toString();

// Gets a formatted date (e.g., Apr 17, 2026)
  String get _formattedDate {
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${months[now.month - 1]} ${now.day}, ${now.year}";
  }

  @override
  Widget build(BuildContext context) {
    _selectedIndex = 0;
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F9),
      // Use a Custom AppBar for a professional look
      appBar: AppBar(
        backgroundColor: const Color(0xFF005A9C),
        elevation: 0,
        title: const Text("Lumina Portal",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Portal Overview",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF263238),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Visual Row 1: Status Tiles
                  Row(
                    children: [
                      // Tile 1: Campus Status
                      _buildInfoTile(
                          "Campus Status",
                          "Active",
                          Icons.sensors,
                          Colors.green
                      ),

                      const SizedBox(width: 15),

                      // Tile 2: System Date
                      _buildInfoTile(
                          "System Date",
                          _formattedDate,
                          Icons.calendar_today_rounded,
                          Colors.orangeAccent
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // Visual Row 2: Academic Year (New Row for better spacing)
                  Row(
                    children: [
                      _buildInfoTile(
                          "Academic Year",
                          "Term $_currentYear",
                          Icons.event_note_rounded,
                          const Color(0xFF005A9C)
                      ),
                      // This empty Expanded keeps the Tile on the left side half-width
                      const SizedBox(width: 15), // Keep the spacing consistent

                      // Right Tile (Added)
                      _buildInfoTile(
                          "Portal Status",
                          "Online",
                          Icons.cloud_done_rounded,
                          Colors.teal
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // Visual Row 2: Information Tile
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFF005A9C)),
                        SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            "Welcome to the Lumina Hub. Please use the navigation bar below to access your specific portal.",
                            style: TextStyle(color: Colors.black54, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // A Professional Hero Header
  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF005A9C),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: const Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white24,
            child: Icon(Icons.school, size: 60, color: Colors.white),
          ),
          SizedBox(height: 15),
          Text("Welcome to Lumina Hub",
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          Text("Select a portal below to begin",
              style: TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildQuickAccessCard(BuildContext context, String title, IconData icon, String route, Color color) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
            const SizedBox(width: 20),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF005A9C),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: "Student"),
          BottomNavigationBarItem(icon: Icon(Icons.badge_outlined), activeIcon: Icon(Icons.badge), label: "Staff"),
          BottomNavigationBarItem(icon: Icon(Icons.school_outlined), activeIcon: Icon(Icons.school), label: "Alumni"),
        ],
      ),
    );
  }

  void _showBeautifulComingSoon() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF005A9C), // Your Primary Blue
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.orangeAccent, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Alumni Portal",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                    Text(
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

  Widget _buildInfoTile(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon in a soft-colored circle
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500)
            ),
            const SizedBox(height: 2),
            Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF263238))
            ),
          ],
        ),
      ),
    );
  }

}