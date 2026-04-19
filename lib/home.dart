import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:mobile_scanner/mobile_scanner.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // Home is index 0

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
      // Stay on Home
        setState(() => _selectedIndex = 0);
        break;

      case 1: // Student Tab
      // Pass the 'Student' argument to enforce student-only login
        Navigator.pushNamed(context, '/login', arguments: 'Student');
        break;

      case 2: // Staff Tab
      // Pass the 'Staff' argument to enforce staff-only login
        Navigator.pushNamed(context, '/login', arguments: 'Staff');
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
        // Only shows the leading widget if there is a page to go back to
        leading: Navigator.canPop(context)
            ? IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 32),
          onPressed: () => Navigator.pop(context),
        )
            : null, // If it's the first page, leading is null (no arrow)
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
      // --- ADDED SCANNER BUTTON ---
      floatingActionButton: GestureDetector(
        onTap: _openBeautifulScanner, // Calls the beautiful version
        child: Container(
          height: 60,
          width: 140,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF005A9C), Color(0xFF00A2E8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF005A9C).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text(
                "SCAN ID",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
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

  void _openBeautifulScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Use a StateSetter for the sheet to trigger "Red" error state
        return StatefulBuilder(builder: (context, setSheetState) {
          bool isError = false;

          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Color(0xFF0D1117), // Deep space blue/black
              borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
            ),
            child: Stack(
              children: [
                // A: THE CUSTOM GRID DESIGN BACKGROUND
                Positioned.fill(
                  child: CustomPaint(painter: _ScannerBackgroundPainter()),
                ),

                Column(
                  children: [
                    const SizedBox(height: 15),
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
                    const SizedBox(height: 30),
                    Text(
                      isError ? "INVALID QR CODE" : "STUDENT ID VERIFICATION",
                      style: TextStyle(
                          color: isError ? Colors.redAccent : Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isError ? "Please try again with a valid student ID" : "Align the student QR code within the frame",
                      style: TextStyle(color: isError ? Colors.redAccent.withOpacity(0.7) : Colors.white54, fontSize: 12),
                    ),
                    const Spacer(),

                    // B: THE SCANNER BOX WITH VIBRATE EFFECT
                    Center(
                      child: TweenAnimationBuilder(
                        // If error, shake the box slightly
                        tween: Tween<double>(begin: 0, end: isError ? 10 : 0),
                        duration: const Duration(milliseconds: 300),
                        builder: (context, double offset, child) {
                          return Transform.translate(
                            offset: Offset(offset, 0),
                            child: child,
                          );
                        },
                        child: Container(
                          width: 260, height: 260,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                                color: isError ? Colors.redAccent : Colors.cyanAccent.withOpacity(0.5),
                                width: 2
                            ),
                            boxShadow: [
                              BoxShadow(
                                  color: isError ? Colors.redAccent.withOpacity(0.2) : Colors.cyanAccent.withOpacity(0.1),
                                  blurRadius: 20,
                                  spreadRadius: 5
                              )
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Stack(
                              children: [
                                MobileScanner(
                                  onDetect: (capture) {
                                    final List<Barcode> barcodes = capture.barcodes;
                                    if (barcodes.isNotEmpty) {
                                      final String? code = barcodes.first.rawValue;

                                      try {
                                        final decoded = jsonDecode(code!);

                                        // Check if the QR contains student data
                                        if (decoded.containsKey('id') && decoded.containsKey('name')) {
                                          Navigator.pop(context); // Close Scanner
                                          _showStudentDetailsPopup(decoded); // Show Profile
                                        } else {
                                          throw Exception("Not a Student QR");
                                        }
                                      } catch (e) {
                                        // --- SHOW ERROR POPUP IMMEDIATELY ---
                                        _showErrorPopup("Invalid QR Code", "This code does not contain valid student information.");
                                      }
                                    }
                                  },
                                ),
                                if (!isError) const _ScannerLine(),
                                if (isError) const Center(child: Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 60)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 40),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
      },
    );
  }

  // 1. Function to show the persistent detail popup
  void _showStudentDetailsPopup(Map<String, dynamic> data) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "StudentProfile",
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)],
            ),
            child: Material(
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Color(0xFFE3F2FD),
                    child: Icon(Icons.person, size: 50, color: Color(0xFF005A9C)),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    data['name']?.toUpperCase() ?? "UNKNOWN",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF005A9C)),
                  ),
                  const Text("VERIFIED STUDENT", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                  const Divider(height: 30),

                  // Only the necessary details
                  _infoRow(Icons.badge_outlined, "Student ID", data['id']),
                  const SizedBox(height: 10),
                  _infoRow(Icons.school_outlined, "Programme", data['programme']),

                  const SizedBox(height: 25),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF005A9C),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text("CLOSE PROFILE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(scale: anim1, child: child);
      },
    );
  }

  Widget _infoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                Text(value ?? "N/A", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
          )
        ],
      ),
    );
  }
  void _showErrorPopup(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.error_outline, color: Colors.red, size: 50),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("TRY AGAIN", style: TextStyle(color: Color(0xFF005A9C), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _ScannerLine extends StatefulWidget {
  const _ScannerLine();

  @override
  State<_ScannerLine> createState() => _ScannerLineState();
}

class _ScannerLineState extends State<_ScannerLine> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: _controller.value * 240, // Moves line up and down
              left: 10,
              right: 10,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.cyanAccent.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
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
}

class _ScannerBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Background Grid Lines
    final linePaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.08) // Increased visibility
      ..strokeWidth = 0.5;

    final thickLinePaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.12)
      ..strokeWidth = 1.2;

    const double step = 30;

    for (double i = 0; i < size.width; i += step) {
      // Every 3rd line is thicker for a "Graph Paper" look
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), (i / step) % 3 == 0 ? thickLinePaint : linePaint);
    }

    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), (i / step) % 3 == 0 ? thickLinePaint : linePaint);
    }

    // 2. Add Glowing Dots at intersections
    final dotPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += step * 3) {
      for (double y = 0; y < size.height; y += step * 3) {
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }

    // 3. Subtle Radial Gradient Overlay
    final gradientPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.8,
        colors: [
          Colors.transparent,
          const Color(0xFF0D1117).withOpacity(0.8), // Fades to the background color at edges
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), gradientPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}