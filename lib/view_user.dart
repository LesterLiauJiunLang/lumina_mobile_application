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

  // --- Search Logic State ---
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // Logic: Fetch students from your real Supabase table
  Future<List<Student>> _fetchStudents() async {
    final response = await supabase
        .from('Student')
        .select()
        .order('Name', ascending: true);

    final List students = response as List;
    return students.map((json) => Student.fromJson(json)).toList();
  }

  // Logic: Show Confirmation Dialog before actual deletion
  Future<void> _deleteStudent(Student student) async {
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
              Text(student.name ?? "N/A",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF005A9C))),
              Text("ID: ${student.id}",
                  style: const TextStyle(color: Colors.grey, fontSize: 14)),
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
      try {
        // AttendanceRecord, Student_ID
        // Enrollment Student_ID
        // attempts, student_id
        // personal_events, student_id
        // 1. Delete from all tables where Student_ID is a Foreign Key
        // Order usually doesn't matter among these, as long as they all happen before Step 2.
        await supabase.from('AttendanceRecord').delete().eq('Student_ID', student.id);
        await supabase.from('Enrollment').delete().eq('Student_ID', student.id);
        await supabase.from('attempts').delete().eq('student_id', student.id);
        await supabase.from('personal_events').delete().eq('student_id', student.id);
        await supabase.from('Student').delete().eq('ID', student.id);

        setState(() {}); // Refresh list

        if (mounted) {
          // --- BEAUTIFUL DELETE SNACKBAR ---
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Student Removed",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          "${student.name} (ID: ${student.id}) has been deleted.",
                          style: const TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red[800], // Deep red for deletion
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(15),
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: "DISMISS",
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        }
      } catch (e) {
        // Error Handling SnackBar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Delete Failed: $e"),
              backgroundColor: Colors.black87,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

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
      body: Column(
        children: [
          // --- Search Bar ---
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Search Student Name or ID",
                prefixIcon: const Icon(Icons.search, color: Color(0xFF005A9C)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 15),
              ),
            ),
          ),

          // --- Table Section ---
          Expanded(
            child: FutureBuilder<List<Student>>(
              future: _fetchStudents(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                final allStudents = snapshot.data ?? [];

                // Filter Logic
                final filteredStudents = allStudents.where((s) {
                  final name = s.name?.toLowerCase() ?? "";
                  final id = s.id.toLowerCase();
                  return name.contains(_searchQuery) || id.startsWith(_searchQuery);
                }).toList();

                if (filteredStudents.isEmpty) {
                  return _buildEmptyState();
                }

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
                      child: DataTable(
                        columnSpacing: 70,
                        headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
                        columns: [
                          const DataColumn(label: Text('Student Info', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                            label: Padding(
                              padding: const EdgeInsets.only(left: 60.0), // Margin left for Actions label
                              child: const Text('Action', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                        rows: filteredStudents.map((s) {
                          return DataRow(cells: [
                            DataCell(
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(s.name ?? "N/A",
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    Text(s.id, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                                  ],
                                ),
                              ),
                            ),
                            DataCell(
                              Padding(
                                padding: const EdgeInsets.only(left: 20.0), // Align icons with the label margin
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.visibility, color: Colors.green, size: 20),
                                      onPressed: () => _showDetails(context, s),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                      onPressed: () async {
                                        bool? updated = await Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => UpdateStudentPage(student: s)),
                                        );
                                        if (updated == true) setState(() {});
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                      onPressed: () => _deleteStudent(s),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 10),
          const Text(
            "No students found",
            style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context, Student student) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(student.name ?? "Student Details",
              style: const TextStyle(color: Color(0xFF005A9C), fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoText("Student ID", student.id),
                _infoText("Gender", (student.gender == null || student.gender!.isEmpty) ? "N/A" : student.gender!),
                _infoText("MyKad No", (student.ic == null || student.ic!.isEmpty) ? "N/A" : student.ic!),
                _infoText("DOB", (student.dob == null || student.dob!.isEmpty) ? "N/A" : student.dob!),
                _infoText("Mobile", (student.phoneNumber == null || student.phoneNumber!.isEmpty) ? "N/A" : student.phoneNumber!),
                _infoText("Address", (student.address == null || student.address!.isEmpty) ? "N/A" : student.address!),
                _infoText("Email", (student.email == null || student.email!.isEmpty) ? "N/A" : student.email!),
                _infoText("Faculty", (student.faculty == null || student.faculty!.isEmpty) ? "N/A" : student.faculty!),
                _infoText("Programme", (student.programme == null || student.programme!.isEmpty) ? "N/A" : student.programme!),
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

  Widget _infoText(String label, String? value) {
    // Check if value is null, empty, or just whitespace
    final String displayValue = (value == null || value.trim().isEmpty) ? "N/A" : value;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text("$label:", style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              child: Text(
                  displayValue,
                  style: TextStyle(
                    color: displayValue == "N/A" ? Colors.grey : Colors.black87, // Subtle grey if N/A
                  ),
                  softWrap: true
              )
          ),
        ],
      ),
    );
  }
}