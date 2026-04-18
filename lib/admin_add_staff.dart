import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Helper for Phone Formatting: 01X-XXXXXXX
class StaffPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll('-', '');
    if (text.length > 11) return oldValue;

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 2 && text.length > 3) {
        buffer.write('-');
      }
    }

    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class AdminAddStaffPage extends StatefulWidget {
  const AdminAddStaffPage({super.key});

  @override
  State<AdminAddStaffPage> createState() => _AdminAddStaffPageState();
}

class _AdminAddStaffPageState extends State<AdminAddStaffPage> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _officeRoomController = TextEditingController();
  final _mobileController = TextEditingController();

  String? _selectedJobTitle;
  String? _selectedFaculty;
  String? _selectedCampus = "Kuala Lumpur Campus";

  final List<String> jobTitles = ['Full-time Lecturer', 'Part-time Tutor', 'Tutor', 'Senior Lecturer', 'Professor', 'Superadmin'];
  final List<String> faculties = [
    'FOCS - Computing & Information Technology',
    'FAFB - Accountancy, Finance & Business',
    'FCCI - Communication & Creative Industries',
    'FOET - Engineering and Technology',
    'FOSC - Applied Sciences',
    'Management'
  ];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_generateEmail);
  }

  void _generateEmail() {
    // .replaceAll(' ', '') removes spaces for names like "Lin Mun Lok"
    String name = _nameController.text.trim().toLowerCase().replaceAll(' ', '');

    if (name.isNotEmpty) {
      setState(() {
        if (_selectedJobTitle == 'Part-time Tutor') {
          // Generate p + 4 random digits
          int randomNum = Random().nextInt(9000) + 1000;
          _emailController.text = "p$randomNum@lumina.edu.my";
        } else {
          // Generates a 2-digit suffix based on current milliseconds
          String uniqueSuffix = DateTime.now().millisecondsSinceEpoch.toString();
          uniqueSuffix = uniqueSuffix.substring(uniqueSuffix.length - 2);

          _emailController.text = "$name$uniqueSuffix@lumina.edu.my";
        }
      });
    }
  }

  Future<void> _registerStaff() async {
    if (!_formKey.currentState!.validate()) return;

    final String mobileRaw = _mobileController.text.replaceAll('-', '');

    if (!mobileRaw.startsWith("01")) {
      _showStatusSnackbar("Invalid Phone", "Must start with '01'.", false);
      return;
    }
    if (mobileRaw.length < 10 || mobileRaw.length > 11) {
      _showStatusSnackbar("Invalid Length", "Must be 10 or 11 digits.", false);
      return;
    }

    try {
      // 1. Determine the prefix based on Job Title
      final bool isSuperadmin = _selectedJobTitle == 'Superadmin';
      final String prefix = isSuperadmin ? "SU" : "S";

      // 2. Query the database for the last ID with the specific prefix
      final response = await supabase
          .from('Staff')
          .select('ID')
          .like('ID', '$prefix%') // Filters for SU% or S% (excluding SU if prefix is S)
          .not('ID', 'like', isSuperadmin ? '' : 'SU%') // If prefix is S, make sure we don't pick up SU
          .order('ID', ascending: false)
          .limit(1)
          .maybeSingle();

      int nextNumber = 1;

      if (response != null) {
        String lastId = response['ID'].toString();
        // Extract only the numbers after the prefix
        String digitsOnly = lastId.replaceFirst(prefix, '');
        if (digitsOnly.isNotEmpty) {
          nextNumber = int.parse(digitsOnly) + 1;
        }
      }

      // 3. Generate the final ID (e.g., SU001 or S001)
      String staffId = "$prefix${nextNumber.toString().padLeft(3, '0')}";

      // 4. Save to Database
      await supabase.from('Staff').insert({
        'ID': staffId,
        'Name': _nameController.text.trim(),
        'Password': mobileRaw,
        'Email': _emailController.text,
        'Faculty': _selectedFaculty,
        'JobTitle': _selectedJobTitle,
        'Campus': _selectedCampus,
        'OfficeRoom': _officeRoomController.text.trim(),
        'PhoneNumber': _mobileController.text,
        'JoinedDate': DateFormat('dd MMM yyyy HH:mm:ss').format(DateTime.now()), // Using your custom format
      });

      // 5. Beautiful Success Snackbar
      _showStatusSnackbar("Success", "Staff registered as $staffId", true);
      _resetForm();

    } catch (e) {
      _showStatusSnackbar("Error", e.toString(), false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register New Staff", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF005A9C),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField("Full Name", _nameController, icon: Icons.person_outline),

              // Updated Dropdown to trigger email regeneration on change
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
              _buildDropdown("Campus", ["Kuala Lumpur Campus", "Penang", "Johor"], _selectedCampus, (val) => setState(() => _selectedCampus = val), icon: Icons.location_on_outlined),
              _buildTextField("Office Room", _officeRoomController, icon: Icons.meeting_room_outlined),

              _buildTextField(
                  "Phone Number",
                  _mobileController,
                  hint: "01X-XXXXXXX",
                  keyboard: TextInputType.number,
                  icon: Icons.phone_android,
                  formatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    StaffPhoneFormatter(),
                  ]
              ),

              _buildTextField("Official Email (Auto)", _emailController, readOnly: true, icon: Icons.alternate_email),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _registerStaff,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005A9C),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Confirm Registration", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool readOnly = false, String? hint, TextInputType? keyboard, IconData? icon, List<TextInputFormatter>? formatters}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboard,
        inputFormatters: formatters,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF005A9C)),
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: readOnly,
          fillColor: readOnly ? Colors.grey[100] : Colors.white,
        ),
        validator: (value) => (value == null || value.isEmpty) ? "Required" : null,
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

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _emailController.clear();
    _officeRoomController.clear();
    _mobileController.clear();
    setState(() { _selectedFaculty = null; _selectedJobTitle = null; });
  }

  void _showStatusSnackbar(String title, String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: isSuccess ? Colors.green[800] : Colors.red[800],
            content: Text("$title: $message")
        )
    );
  }
}