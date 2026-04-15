import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'model/student.dart'; // Import the blueprint
import 'update_student.dart';

class ViewUserPage extends StatefulWidget {
  const ViewUserPage({super.key, required this.title});
  final String title;

  @override
  State<ViewUserPage> createState() => _ViewUserPageState();
}

class _ViewUserPageState extends State<ViewUserPage> {
  final supabase = Supabase.instance.client;

  // Logic: Fetch students from your real Supabase table
  Future<List<Student>> _fetchStudents() async {
    final response = await supabase
        .from('Student')
        .select()
        .order('Name', ascending: true);

    final List students = response as List;
    return students.map((json) => Student.fromJson(json)).toList();
  }

  // Logic: Real deletion from Supabase
  // Logic: Show Confirmation Dialog before actual deletion
  Future<void> _deleteStudent(Student student) async {
    // Logic: Show Confirmation Dialog
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Row(
            children: [
              Icon(Icons.delete_forever, color: Colors.red),
              SizedBox(width: 10),
              Text("Confirm Deletion"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Are you sure you want to delete this student?"),
              const SizedBox(height: 15),

              // 1. Name and ID
              Text(student.name ?? "N/A",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF005A9C))),
              Text("ID: ${student.id}",
                  style: const TextStyle(color: Colors.grey, fontSize: 14)),

              const Divider(height: 25),

              // 2. Faculty (Short name only), Programme, and Group
              _confirmInfoRow(Icons.account_balance, "Faculty", student.faculty ?? "N/A"),
              _confirmInfoRow(Icons.school, "Programme", student.programme ?? "N/A"),
              _confirmInfoRow(Icons.groups, "Group", "Group ${student.tutorialGroup?.toInt() ?? 'N/A'}"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Confirm Delete", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirmDelete) {
      await supabase.from('Student').delete().eq('ID', student.id);
      setState(() {}); // Refresh list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${student.name} deleted"), backgroundColor: Colors.red),
      );
    }
  }

// Helper Widget for the rows inside the confirmation box
  Widget _confirmInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "$label: $value",
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF005A9C),
        title: const Text('Student Management', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<Student>>(
        future: _fetchStudents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final students = snapshot.data ?? [];

          // --- NEW LOGIC: SHOW TEXT IF NOT FOUND ---
          if (students.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 10),
                  const Text(
                    "No students found",
                    style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SizedBox(
              width: double.infinity,
              child: DataTable(
                columnSpacing: 20,
                columns: const [
                  DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: students.map((s) {
                  return DataRow(cells: [
                    DataCell(
                      Container(
                        width: 140,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          s.name ?? "N/A",
                          softWrap: true,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility, color: Colors.green),
                            onPressed: () => _showDetails(context, s),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () async {
                              // Navigate to Edit Page
                              bool? updated = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UpdateStudentPage(student: s),
                                ),
                              );

                              // If the edit page returns 'true', refresh the list
                              if (updated == true) {
                                setState(() {});
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteStudent(s),
                          ),
                        ],
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper for Details Popup
  void _showDetails(BuildContext context, Student student) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
              student.name ?? "Student Details",
              style: const TextStyle(color: Color(0xFF005A9C), fontWeight: FontWeight.bold)
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoText("Student ID", student.id),
                _infoText("Gender", student.gender ?? "N/A"),
                _infoText("MyKad No", student.ic ?? "N/A"),
                _infoText("DOB", student.dob ?? "N/A"),
                _infoText("Mobile", student.phoneNumber ?? "N/A"),
                _infoText("Address", student.address ?? "N/A"),
                _infoText("Email", student.email ?? "N/A"),
                _infoText("Faculty", student.faculty ?? "N/A"),
                _infoText("Programme", student.programme ?? "N/A"),

              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
          ],
        );
      },
    );
  }


  // Updated helper to handle "too long" text wrapping to next line
  Widget _infoText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Label stays at top
        children: [
          SizedBox(
            width: 90, // Fixed width for labels keeps them aligned
            child: Text(
                "$label:", style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded( // This forces the "value" to wrap if it's too long
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}