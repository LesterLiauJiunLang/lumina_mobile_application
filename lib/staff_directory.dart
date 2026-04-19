import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lumina_mobile_application/staff_distribution_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_add_staff.dart';
import 'view_staff.dart';

class StaffDirectoryPage extends StatefulWidget {
  const StaffDirectoryPage({super.key});

  @override
  State<StaffDirectoryPage> createState() => _StaffDirectoryPageState();
}

class _StaffDirectoryPageState extends State<StaffDirectoryPage> {
  final supabase = Supabase.instance.client;
  int _staffCount = 0;
  int _facultyCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRealStats();
  }

  /// Fetches real-time statistics from Supabase
  Future<void> _fetchRealStats() async {
    setState(() => _isLoading = true);
    try {
      // 1. Get Total Staff Count using the modern .count() method
      // This solves the 'count isn't defined for PostgrestList' error
      final staffRes = await supabase
          .from('Staff')
          .select('*')
          .count(CountOption.exact);

      // 2. Get Unique Faculty Count
      final List<dynamic> facultyData = await supabase
          .from('Staff')
          .select('Faculty');

      // Filter unique values using a Set
      final uniqueFaculties = facultyData
          .map((item) => item['Faculty']?.toString())
          .where((f) => f != null && f.isNotEmpty)
          .toSet();

      if (mounted) {
        setState(() {
          _staffCount = staffRes.count; // Correctly accessing the response count
          _facultyCount = uniqueFaculties.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching stats: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentDate = DateFormat('EEEE, d MMM yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: const Text("Management Hub",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF005A9C),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchRealStats,
        child: Stack(
          children: [
            // Top Blue Banner
            Container(
              height: MediaQuery.of(context).size.height * 0.18,
              decoration: const BoxDecoration(
                color: Color(0xFF005A9C),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
            ),

            SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      "Welcome Back, Admin",
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      currentDate,
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                    ),

                    const SizedBox(height: 30),

                    // Statistics Section
                    Row(
                      children: [
                        _buildStatCard(
                            "Total Staff",
                            _isLoading ? "..." : _staffCount.toString(),
                            Icons.people_alt,
                            Colors.orange
                        ),
                        const SizedBox(width: 15),
                        _buildStatCard(
                            "Active Faculties",
                            _isLoading ? "..." : _facultyCount.toString(),
                            Icons.account_balance,
                            Colors.purple
                        ),
                      ],
                    ),

                    const SizedBox(height: 35),
                    const Text(
                      "Quick Operations",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 15),

                    // Navigation Cards
                    _buildMenuCard(
                      context,
                      title: "View Staff Directory",
                      subtitle: "Manage, search, and edit existing records",
                      icon: Icons.badge_outlined,
                      color: const Color(0xFF005A9C),
                      onTap: () async {
                        final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ViewStaffPage())
                        );
                        if (result == true) _fetchRealStats(); // Refresh if data changed
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildMenuCard(
                      context,
                      title: "Register New Staff",
                      subtitle: "Onboard new faculty or office members",
                      icon: Icons.person_add_alt_1_outlined,
                      color: Colors.green[700]!,
                      onTap: () async {
                        final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AdminAddStaffPage())
                        );
                        if (result == true) _fetchRealStats(); // Refresh if new staff added
                      },
                    ),

                    const SizedBox(height: 15),

                    // --- ADDED ANALYTICS CARD ---
                    _buildMenuCard(
                      context,
                      title: "Staff Analytics",
                      subtitle: "View Management vs Academic distribution",
                      icon: Icons.pie_chart_outline,
                      color: Colors.orange[800]!,
                      onTap: () async {
                        // Show a loading indicator while fetching data for the chart
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(child: CircularProgressIndicator()),
                        );

                        try {
                          // Fetch the staff data to pass to the chart
                          final List<dynamic> data = await supabase.from('Staff').select('JobTitle');

                          if (mounted) {
                            Navigator.pop(context); // Close loading indicator
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Scaffold(
                                  appBar: AppBar(
                                    title: const Text(
                                        "Staff Distribution",
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                                    ),
                                    backgroundColor: const Color(0xFF005A9C),
                                    iconTheme: const IconThemeData(color: Colors.white),
                                  ),
                                  // CHANGE THIS LINE BELOW:
                                  body: StaffDistributionChart(staffList: data),
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error loading analytics: $e")),
                            );
                          }
                        }
                      },
                    ),

                    const SizedBox(height: 30),

                    // Footer Info
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 15),
                          const Expanded(
                            child: Text(
                              "Data is synced with Supabase. Pull down to manually refresh statistics.",
                              style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper: Build small stat cards
  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4)
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(count, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
          ],
        ),
      ),
    );
  }

  // Helper: Build large action cards
  Widget _buildMenuCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 4)
            )
          ],
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
          ],
        ),
      ),
    );
  }
}