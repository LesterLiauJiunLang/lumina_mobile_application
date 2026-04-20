import 'package:flutter/material.dart';
import 'package:lumina_mobile_application/update_staff.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_add_staff.dart';
import 'model/staff.dart';

class ViewStaffPage extends StatefulWidget {
  const ViewStaffPage({super.key});

  @override
  State<ViewStaffPage> createState() => _ViewStaffPageState();
}

class _ViewStaffPageState extends State<ViewStaffPage> {
  final supabase = Supabase.instance.client;

  // Logic for the Search Bar
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // Fetch logic for Staff
  Future<List<Map<String, dynamic>>> _fetchStaff() async {
    final response = await supabase
        .from('Staff')
        .select()
        .order('Name', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> _deleteStaff(Map<String, dynamic> staff) async {
    final String staffId = staff['ID']?.toString() ?? "N/A";
    final String staffName = staff['Name']?.toString() ?? "Unknown";

    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text("Confirm Delete"),
          ],
        ),
        content: Text("Are you sure you want to permanently remove $staffName ($staffId)?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (confirmDelete) {
      try {

        // Announcement Created_By
        // AttendanceSession CreatedBy
        // Course Staff_ID
        // Clean up tables that reference this Staff ID
        await supabase.from('Announcement').delete().eq('Created_By', staffId);
        await supabase.from('AttendanceSession').delete().eq('CreatedBy', staffId);
        await supabase.from('Course').delete().eq('Staff_ID', staffId);

        await supabase.from('Staff').delete().eq('ID', staffId);
        setState(() {});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Staff $staffName deleted"),
              backgroundColor: Colors.red[900],
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.orange[900]),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF005A9C),
        title: const Text("Staff Directory List", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // --- Search Bar Section ---
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
                hintText: "Search Name or ID (e.g., S001, SU001)",
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
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchStaff(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));

                final allStaff = snapshot.data ?? [];

                final staffList = allStaff.where((staff) {
                  final name = staff['Name'].toString().toLowerCase();
                  final id = staff['ID'].toString().toLowerCase();
                  return name.contains(_searchQuery) || id.startsWith(_searchQuery);
                }).toList();

                // Inside the FutureBuilder, replace the simple isEmpty check with this:
                if (staffList.isEmpty) return _buildEmptyState();

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
                      child:
                      DataTable(
                        columnSpacing: 10, // Adjust this to control overall gap
                        headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
                        columns: [
                          const DataColumn(
                            label: Text('Staff Info', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          DataColumn(
                            label: Padding(
                              padding: const EdgeInsets.only(left: 60.0), // Moves "Actions" text right
                              child: const Text('Actions', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                        rows: staffList.map((staffMap) => DataRow(cells: [
                          DataCell(
                            Container(
                              width: MediaQuery.of(context).size.width * 0.45, // Wide space for info
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    staffMap['Name'] ?? "N/A",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    staffMap['ID'] ?? "N/A",
                                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          DataCell(
                            Padding(
                              padding: const EdgeInsets.only(left: 20.0), // Moves the icons right to match the label
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    icon: const Icon(Icons.visibility, color: Colors.green, size: 20),
                                    onPressed: () => _showStaffDetails(staffMap),
                                  ),
                                  IconButton(
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    icon: const Icon(Icons.edit, color: Colors.orange, size: 20),
                                    onPressed: () async {
                                      final staffObj = Staff.fromJson(staffMap);
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => UpdateStaffPage(staff: staffObj)),
                                      );
                                      if (result == true) setState(() {});
                                    },
                                  ),
                                  IconButton(
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                    onPressed: () => _deleteStaff(staffMap),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ])).toList(),
                      )
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

  void _showStaffDetails(Map<String, dynamic> staff) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(staff['Name'], style: const TextStyle(color: Color(0xFF005A9C))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _infoRow("Staff ID", staff['ID']),
            _infoRow("Position", staff['JobTitle']),
            _infoRow("Faculty", staff['Faculty']),
            _infoRow("Office", staff['OfficeRoom']),
            _infoRow("Campus", staff['Campus']),
            _infoRow("Mobile", staff['PhoneNumber']),
            _infoRow("Email", staff['Email']),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value ?? "N/A", softWrap: true)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Using a subtle grey icon to keep it professional
          Icon(Icons.person_search_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No staff members found",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Try adjusting your search or add a new record.",
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
        ],
      ),
    );
  }
}