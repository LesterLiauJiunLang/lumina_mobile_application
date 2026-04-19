import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lumina_mobile_application/student_distribution_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'view_user.dart'; // Your existing ViewUserPage
import 'register_student.dart'; // Your existing RegisterStudentPage

class StudentDirectoryPage extends StatefulWidget {
  const StudentDirectoryPage({super.key});

  @override
  State<StudentDirectoryPage> createState() => _StudentDirectoryPageState();
}

class _StudentDirectoryPageState extends State<StudentDirectoryPage> {
  final supabase = Supabase.instance.client;
  int _studentCount = 0;
  int _facultyCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRealStats();
  }

  Future<void> _fetchRealStats() async {
    setState(() => _isLoading = true);
    try {
      // 1. Total Student Count
      final studentRes = await supabase
          .from('Student')
          .select('*')
          .count(CountOption.exact);

      // 2. Unique Faculty Count for Students
      final List<dynamic> facultyData = await supabase
          .from('Student')
          .select('Faculty');

      final uniqueFaculties = facultyData
          .map((item) => item['Faculty']?.toString())
          .where((f) => f != null && f.isNotEmpty)
          .toSet();

      if (mounted) {
        setState(() {
          _studentCount = studentRes.count ?? 0;
          _facultyCount = uniqueFaculties.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching student stats: $e");
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
        title: const Text("Student Hub",
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
                      "Student Management",
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
                            "Total Students",
                            _isLoading ? "..." : _studentCount.toString(),
                            Icons.school,
                            Colors.blueAccent
                        ),
                        const SizedBox(width: 15),
                        _buildStatCard(
                            "Faculties",
                            _isLoading ? "..." : _facultyCount.toString(),
                            Icons.account_balance,
                            Colors.teal
                        ),
                      ],
                    ),

                    const SizedBox(height: 35),
                    const Text(
                      "Administration",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 15),

                    // Navigation Cards
                    _buildMenuCard(
                      context,
                      title: "View Student Directory",
                      subtitle: "Search, edit, and delete student records",
                      icon: Icons.supervised_user_circle_outlined,
                      color: const Color(0xFF005A9C),
                      onTap: () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ViewUserPage(title: "Student Management"))
                        );
                        _fetchRealStats();
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildMenuCard(
                      context,
                      title: "Register New Student",
                      subtitle: "Create a new profile for an intake",
                      icon: Icons.person_add_alt_outlined,
                      color: Colors.green[700]!,
                      onTap: () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterStudentPage())
                        );
                        _fetchRealStats();
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildMenuCard(
                      context,
                      title: "Student Analytics",
                      subtitle: "View Faculty enrollment report",
                      icon: Icons.analytics_outlined,
                      color: Colors.orange[800]!,
                      onTap: () async {
                        // Show loading
                        showDialog(context: context, builder: (context) => const Center(child: CircularProgressIndicator()));

                        try {
                          // Correctly fetch data from Student table
                          final List<dynamic> data = await supabase.from('Student').select('Faculty');

                          if (mounted) {
                            Navigator.pop(context); // Close loading
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Scaffold(
                                  backgroundColor: Colors.grey[50],
                                  appBar: AppBar(
                                    elevation: 0,
                                    title: const Text("Student Analytics", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    backgroundColor: const Color(0xFF005A9C),
                                    iconTheme: const IconThemeData(color: Colors.white),
                                  ),
                                  body: StudentDistributionChart(studentList: data),
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          debugPrint("Error loading analytics: $e");
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
                              "Real-time database connection active. Student data is encrypted and secure.",
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

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
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

  Widget _buildMenuCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))],
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
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