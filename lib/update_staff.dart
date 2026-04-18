import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'model/staff.dart'; // Ensure this path is correct
import 'dart:math';

// Reusing your Phone Formatter for consistency
class StaffPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll('-', '');
    if (text.length > 11) return oldValue;
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 2 && text.length > 3) buffer.write('-');
    }
    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class UpdateStaffPage extends StatefulWidget {
  final Staff staff;
  const UpdateStaffPage({super.key, required this.staff});

  @override
  State<UpdateStaffPage> createState() => _UpdateStaffPageState();
}

class _UpdateStaffPageState extends State<UpdateStaffPage> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _officeRoomController;
  late TextEditingController _phoneController;

  // Dropdown states
  String? _selectedJobTitle;
  String? _selectedFaculty;
  String? _selectedCampus;

  final List<String> jobTitles = [
    'Full-time Lecturer',
    'Part-time Tutor',
    'Tutor',
    'Senior Lecturer',
    'Professor',
    'Superadmin',
  ];

  final List<String> faculties = [
    'FOCS - Computing & Information Technology',
    'FAFB - Accountancy, Finance & Business',
    'FCCI - Communication & Creative Industries',
    'FOET - Engineering and Technology',
    'FOSC - Applied Sciences',
    'Management'
  ];

  final List<String> campuses = [
    "Kuala Lumpur Campus",
    "Penang",
    "Johor"
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.staff.name);
    _emailController = TextEditingController(text: widget.staff.email);
    _officeRoomController = TextEditingController(text: widget.staff.officeRoom);
    _phoneController = TextEditingController(text: widget.staff.phoneNumber);

    _selectedJobTitle = widget.staff.jobTitle;
    _selectedFaculty = widget.staff.faculty;
    _selectedCampus = widget.staff.campus;

    // Listeners for auto-email generation if name changes
    _nameController.addListener(_generateEmail);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _officeRoomController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _generateEmail() {
    String name = _nameController.text.trim().toLowerCase().replaceAll(' ', '');
    if (name.isNotEmpty) {
      setState(() {
        if (_selectedJobTitle == 'Part-time Tutor') {
          // Keeps 'p' logic for tutors
          if (!_emailController.text.startsWith('p')) {
            int randomNum = Random().nextInt(9000) + 1000;
            _emailController.text = "p$randomNum@lumina.edu.my";
          }
        } else {
          // Unique 2-digit suffix for academic staff
          String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
          String uniqueSuffix = timestamp.substring(timestamp.length - 2);

          _emailController.text = "$name$uniqueSuffix@lumina.edu.my";
        }
      });
    }
  }

  Future<void> _updateData() async {
    if (_formKey.currentState!.validate()) {
      try {
        final String staffId = widget.staff.id;
        final String staffName = _nameController.text.trim();
        final mobileRaw = _phoneController.text.replaceAll('-', '');

        await supabase.from('Staff').update({
          'Name': staffName,
          'Email': _emailController.text,
          'JobTitle': _selectedJobTitle,
          'Faculty': _selectedFaculty,
          'Campus': _selectedCampus,
          'OfficeRoom': _officeRoomController.text.trim(),
          'PhoneNumber': _phoneController.text,
          'Password': mobileRaw,
        }).eq('ID', staffId);

        if (mounted) {
          // Show the beautiful success snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.white),
                        children: [
                          const TextSpan(text: "Update Successful! \n"),
                          TextSpan(
                            text: "$staffId - $staffName",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 3),
            ),
          );

          // Wait a small moment so they can see the message before closing the page
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) Navigator.pop(context, true);
          });
        }
      } catch (e) {
        _showErrorSnackbar(e.toString());
      }
    }
  }

// Helper for clean error reporting
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error: $message"),
        backgroundColor: Colors.red[800],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    DateTime joinedDateTime;

    try {
      // If your model has it as a String:
      joinedDateTime = DateTime.parse(widget.staff.joinedDate.toString());
    } catch (e) {
      // Fallback if parsing fails
      joinedDateTime = DateTime.now();
    }

    // 2. Now format the DateTime object
    String formattedDate = DateFormat('dd MMM yyyy HH:mm:ss').format(joinedDateTime);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF005A9C),
        title: const Text("Update Staff Info", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // --- LOGO STYLE INFO AT TOP ---


              _buildReadOnlyInfo("Staff ID", widget.staff.id, icon: Icons.badge_outlined),
              _buildReadOnlyInfo("Joined Date", formattedDate ?? "N/A", icon: Icons.calendar_today_outlined),

              const SizedBox(height: 10),

              _buildTextField("Full Name", _nameController, icon: Icons.person_outline),

              // --- Job Title Dropdown ---
              _buildDropdown("Job Title", jobTitles, _selectedJobTitle, (val) {
                setState(() {
                  _selectedJobTitle = val;

                  if (_selectedJobTitle == 'Superadmin') {
                    _selectedFaculty = 'Management'; // Forces change
                  } else {
                    // Optional: clear faculty so they can pick a new one
                    // if they switch AWAY from Superadmin
                    _selectedFaculty = null;
                  }
                });
                _generateEmail();
              }, icon: Icons.work_outline),

              // --- Faculty Dropdown ---
              _buildDropdown(
                  "Faculty",
                  faculties,
                  _selectedFaculty,
                  // Disable manual selection if job title is Superadmin
                  _selectedJobTitle == 'Superadmin' ? null : (val) => setState(() => _selectedFaculty = val),
                  icon: Icons.account_balance
              ),

              _buildDropdown("Campus", campuses, _selectedCampus, (val) {
                setState(() => _selectedCampus = val);
              }, icon: Icons.location_on_outlined),

              _buildTextField("Office Room", _officeRoomController, icon: Icons.meeting_room_outlined),

              _buildTextField(
                  "Phone Number",
                  _phoneController,
                  hint: "01X-XXXXXXX",
                  keyboard: TextInputType.number,
                  icon: Icons.phone_android,
                  formatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    StaffPhoneFormatter(),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Required";
                    if (value.replaceAll('-', '').length < 10) return "Too short";
                    return null;
                  }
              ),

              _buildTextField("Official Email (Auto)", _emailController, readOnly: true, icon: Icons.alternate_email),

              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005A9C),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _updateData,
                child: const Text("SAVE CHANGES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildTextField(String label, TextEditingController controller,
      {bool readOnly = false, String? hint, IconData? icon, List<TextInputFormatter>? formatters, TextInputType? keyboard, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        validator: validator ?? (value) => (value == null || value.isEmpty) ? "Required" : null,
        inputFormatters: formatters,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF005A9C)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: readOnly,
          fillColor: readOnly ? Colors.grey[100] : Colors.white,
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? currentVal, Function(dynamic)? onChange, {IconData? icon}) {
    bool isDisabled = onChange == null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        isExpanded: true, // Prevents the yellow/black overflow error
        value: currentVal,
        onChanged: onChange,
        decoration: InputDecoration(
            prefixIcon: Icon(icon, color: isDisabled ? Colors.grey : const Color(0xFF005A9C)),
            labelText: label,
            filled: isDisabled,
            fillColor: isDisabled ? Colors.grey[100] : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
        ),
        items: items.map((item) => DropdownMenuItem(
            value: item,
            child: Text(item, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDisabled ? Colors.grey[600] : Colors.black))
        )).toList(),
        validator: (value) => value == null ? "Select $label" : null,
      ),
    );
  }

  Widget _buildReadOnlyInfo(String label, String value, {IconData? icon}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.blueGrey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.blueGrey, size: 22),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF005A9C))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}