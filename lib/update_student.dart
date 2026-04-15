import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'model/student.dart';

class UpdateStudentPage extends StatefulWidget {
  final Student student;
  const UpdateStudentPage({super.key, required this.student});

  @override
  State<UpdateStudentPage> createState() => _UpdateStudentPageState();
}

class _UpdateStudentPageState extends State<UpdateStudentPage> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _icController;
  late TextEditingController _dobController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;

  // Dropdown states
  String? _selectedGender;
  String? _selectedProgramme;
  String? _selectedFaculty;
  int? _selectedGroup;

  final List<int> tutorialGroups = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
                                    11, 12, 13, 14, 15, 16, 17, 18, 19, 20];

  final Map<String, String> programmeToFaculty = {
    'Bachelor of Software Engineering (Honours)': 'FOCS - Computing & Information Technology',
    'Bachelor of Computer Science (Honours)': 'FOCS - Computing & Information Technology',
    'Bachelor of Business Administration (Honours)': 'FAFB - Accountancy, Finance & Business',
    'Bachelor of Accounting (Honours)': 'FAFB - Accountancy, Finance & Business',
    'Bachelor of Communication (Honours)': 'FCCI - Communication & Creative Industries',
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.student.name);
    _icController = TextEditingController(text: widget.student.ic);
    _dobController = TextEditingController(text: widget.student.dob);
    _addressController = TextEditingController(text: widget.student.address);
    _phoneController = TextEditingController(text: widget.student.phoneNumber); // Initialize

    _selectedGender = widget.student.gender;

    int? currentGroup = widget.student.tutorialGroup?.toInt();
    if (tutorialGroups.contains(currentGroup)) {
      _selectedGroup = currentGroup;
    }

    if (programmeToFaculty.containsKey(widget.student.programme)) {
      _selectedProgramme = widget.student.programme;
      _selectedFaculty = programmeToFaculty[widget.student.programme];
    }

    _icController.addListener(_onIcChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _icController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _phoneController.dispose(); // Clean up
    super.dispose();
  }

  bool _isValidIC(String ic) {
    final icRegex = RegExp(r'^\d{6}-\d{2}-\d{4}$');
    if (!icRegex.hasMatch(ic)) return false;

    String cleanIc = ic.replaceAll('-', '');
    int yearShort = int.parse(cleanIc.substring(0, 2));
    int month = int.parse(cleanIc.substring(2, 4));
    int day = int.parse(cleanIc.substring(4, 6));

    if (month < 1 || month > 12) return false;

    int fullYear = (yearShort > 30) ? 1900 + yearShort : 2000 + yearShort;
    List<int> daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

    if ((fullYear % 4 == 0 && fullYear % 100 != 0) || (fullYear % 400 == 0)) {
      daysInMonth[1] = 29;
    }

    if (day < 1 || day > daysInMonth[month - 1]) return false;

    return true;
  }

  void _onIcChanged() {
    String ic = _icController.text.replaceAll('-', '');
    if (ic.length == 12) {
      String yearShort = ic.substring(0, 2);
      int yearInt = int.parse(yearShort);
      String yearPrefix = (yearInt > 30) ? "19" : "20";
      String month = ic.substring(2, 4);
      String day = ic.substring(4, 6);

      int lastDigit = int.parse(ic.substring(11));

      setState(() {
        _dobController.text = "$day/$month/$yearPrefix$yearShort";
        _selectedGender = (lastDigit % 2 == 0) ? "Female" : "Male";
      });
    }
  }

  Future<void> _updateData() async {
    if (_formKey.currentState!.validate()) {
      try {
        await supabase.from('Student').update({
          'Name': _nameController.text,
          'IC': _icController.text,
          'DateOfBirth': _dobController.text,
          'Gender': _selectedGender,
          'PhoneNumber': _phoneController.text,
          'Programme': _selectedProgramme,
          'Faculty': _selectedFaculty,
          'TutorialGroup': _selectedGroup,
          'Address': _addressController.text,
        }).eq('ID', widget.student.id);

        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Update Failed: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF005A9C),
        title: const Text("Update Student Info", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // --- 1. STUDENT ID INFO AT THE TOP ---
              _buildReadOnlyInfo("Student ID", widget.student.id.toString(), icon: Icons.badge),

              const SizedBox(height: 10),

              _buildTextField("Full Name", _nameController),
              _buildTextField(
                "MyKad (IC)",
                _icController,
                hint: "YYMMDDa-XX-XXXX",
                validator: (value) {
                  if (value == null || value.isEmpty) return "IC is required";
                  if (!_isValidIC(value)) return "Invalid IC format or date";
                  return null;
                },
              ),
              _buildTextField("Date of Birth (Auto)", _dobController, readOnly: true),

              _buildDropdown("Gender", ["Male", "Female"], _selectedGender, (val) {
                setState(() => _selectedGender = val);
              }),

              _buildTextField(
                  "Phone Number",
                  _phoneController,
                  hint: "e.g. 012-3456789",
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Phone number is required";
                    return null;
                  }
              ),

              _buildTextField("Home Address", _addressController, maxLines: 3),

              _buildDropdown("Programme", programmeToFaculty.keys.toList(), _selectedProgramme, (val) {
                setState(() {
                  _selectedProgramme = val;
                  _selectedFaculty = programmeToFaculty[val];
                });
              }),

              _buildReadOnlyInfo("Faculty", _selectedFaculty ?? "N/A", icon: Icons.account_balance),

              _buildDropdown("Tutorial Group", tutorialGroups, _selectedGroup, (val) {
                setState(() => _selectedGroup = val);
              }),

              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005A9C),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      {bool readOnly = false, String? hint, int maxLines = 1, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        validator: validator,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          filled: readOnly,
          fillColor: readOnly ? Colors.grey[100] : null,
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List items, dynamic currentVal, Function(dynamic) onChange) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField(
        isExpanded: true,
        value: currentVal,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        items: items.map((item) => DropdownMenuItem(
          value: item,
          child: Text(item.toString(), overflow: TextOverflow.ellipsis),
        )).toList(),
        onChanged: onChange,
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blueGrey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.blueGrey, size: 20),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF005A9C))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}