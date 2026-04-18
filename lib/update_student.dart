import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'model/student.dart';
import 'package:flutter/services.dart';

class UpdateStudentPage extends StatefulWidget {
  final Student student;
  const UpdateStudentPage({super.key, required this.student});

  @override
  State<UpdateStudentPage> createState() => _UpdateStudentPageState();
}

class _UpdateStudentPageState extends State<UpdateStudentPage> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _icController;
  late TextEditingController _dobController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;

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
    _phoneController = TextEditingController(text: widget.student.phoneNumber);

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
    _phoneController.dispose();
    super.dispose();
  }

  // --- IC LOGIC ---
  bool _isValidIC(String ic) {
    final icRegex = RegExp(r'^\d{6}-\d{2}-\d{4}$');
    if (!icRegex.hasMatch(ic)) return false;
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

        if (mounted) {
          // --- BEAUTIFUL SUCCESS SNACKBAR ---
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 28),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Update Successful!",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          "ID: ${widget.student.id} | ${_nameController.text}",
                          style: const TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(15),
              duration: const Duration(seconds: 3),
            ),
          );

          // Delay slightly so user can see the snackbar before popping the page
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) Navigator.pop(context, true);
          });
        }
      } catch (e) {
        // --- BEAUTIFUL ERROR SNACKBAR ---
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text("Error: ${e.toString()}")),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(15),
          ),
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
              _buildReadOnlyInfo("Student ID", widget.student.id.toString(), icon: Icons.badge),
              const SizedBox(height: 10),

              _buildTextField("Full Name", _nameController),

              // --- UPDATED IC FIELD TO HAVE DASHES ---
              _buildTextField(
                "MyKad (IC)",
                _icController,
                hint: "YYMMDD-XX-XXXX",
                keyboard: TextInputType.number,
                formatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  ICFormatter(), // Added IC Formatter
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return "IC is required";
                  if (!_isValidIC(value)) return "Invalid IC format";
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
                  hint: "01X-XXXXXXX",
                  keyboard: TextInputType.number,
                  prefixIcon: Icons.phone_android,
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

  Widget _buildTextField(String label, TextEditingController controller,
      {bool readOnly = false,
        String? hint,
        int maxLines = 1,
        TextInputType? keyboard,
        IconData? prefixIcon,
        List<TextInputFormatter>? formatters,
        String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        validator: validator,
        maxLines: maxLines,
        keyboardType: keyboard,
        inputFormatters: formatters,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: const Color(0xFF005A9C)) : null,
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

// --- ADDED IC FORMATTER ---
class ICFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll('-', '');
    if (text.length > 12) text = text.substring(0, 12);

    String formatted = "";
    for (int i = 0; i < text.length; i++) {
      formatted += text[i];
      // Adds dash after 6th and 8th characters: 000000-00-0000
      if ((i == 5 || i == 7) && i != text.length - 1) {
        formatted += "-";
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class StaffPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll('-', '');
    if (text.length > 11) text = text.substring(0, 11);

    String formatted = "";
    for (int i = 0; i < text.length; i++) {
      formatted += text[i];
      if (i == 2 && text.length > 3) formatted += "-";
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}