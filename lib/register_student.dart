import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Helper class for auto-formatting dashes
class DashFormatter extends TextInputFormatter {
  final List<int> dashPositions;
  DashFormatter(this.dashPositions);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll('-', '');
    // Limit to 12 digits (IC length)
    if (text.length > 12) return oldValue;

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (dashPositions.contains(i + 1) && i != text.length - 1) {
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

class RegisterStudentPage extends StatefulWidget {
  const RegisterStudentPage({super.key});

  @override
  State<RegisterStudentPage> createState() => _RegisterStudentPageState();
}

class _RegisterStudentPageState extends State<RegisterStudentPage> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _icController = TextEditingController();
  final _dobController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  String? _selectedGender;
  String? _selectedProgramme;
  String? _selectedFaculty;
  // FIXED: Value must exactly match an item in the list to avoid the red error screen
  String? _selectedCampus = "Kuala Lumpur Campus";
  int? _selectedGroup;

  final List<int> tutorialGroups = List.generate(20, (index) => index + 1);

  final Map<String, List<String>> programmes = {
    'Foundation Programmes': [
      'Foundation in Computing',
      'Foundation in Business',
      'Foundation in Arts',
    ],
    'Diploma Programmes': [
      'Diploma in Computer Science',
      'Diploma in Business Administration',
      'Diploma in Communication',
    ],
    'Bachelor Degree Programmes': [
      'Bachelor of Software Engineering (Honours)',
      'Bachelor of Computer Science (Honours)',
      'Bachelor of Business Administration (Honours)',
      'Bachelor of Accounting (Honours)',
      'Bachelor of Communication (Honours)',
    ],
  };

  final Map<String, String> programmeToFaculty = {
    // Foundation
    'Foundation in Computing': 'FOCS - Computing & Information Technology',
    'Foundation in Business': 'FAFB - Accountancy, Finance & Business',
    'Foundation in Arts': 'FCCI - Communication & Creative Industries',

    // Diploma
    'Diploma in Computer Science': 'FOCS - Computing & Information Technology',
    'Diploma in Business Administration': 'FAFB - Accountancy, Finance & Business',
    'Diploma in Communication': 'FCCI - Communication & Creative Industries',

    // Bachelor
    'Bachelor of Software Engineering (Honours)': 'FOCS - Computing & Information Technology',
    'Bachelor of Computer Science (Honours)': 'FOCS - Computing & Information Technology',
    'Bachelor of Business Administration (Honours)': 'FAFB - Accountancy, Finance & Business',
    'Bachelor of Accounting (Honours)': 'FAFB - Accountancy, Finance & Business',
    'Bachelor of Communication (Honours)': 'FCCI - Communication & Creative Industries',
  };

  @override
  void initState() {
    super.initState();
    _icController.addListener(_onIcChanged);
    _nameController.addListener(_onNameChanged);
  }

  void _showStatusSnackbar(String title, String message, bool isSuccess) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        dismissDirection: DismissDirection.up,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height - 160, left: 10, right: 10),
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSuccess ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(isSuccess ? Icons.check_circle : Icons.error, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(message, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TweenAnimationBuilder<double>(
                duration: const Duration(seconds: 4),
                tween: Tween(begin: 1.0, end: 0.0),
                builder: (context, value, child) => LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onNameChanged() {
    String name = _nameController.text.trim();

    if (name.isNotEmpty && _selectedProgramme != null) {
      List<String> parts = name.split(' ');
      String firstName = parts[0].toLowerCase();
      String initials = "";
      if (parts.length > 1) {
        for (int i = 1; i < parts.length; i++) {
          if (parts[i].isNotEmpty) initials += parts[i][0].toLowerCase();
        }
      }

      // Determine Prefix
      String prefix = "wm"; // Default
      if (_selectedProgramme!.contains("Foundation")) {
        prefix = "wp";
      } else if (_selectedProgramme!.contains("Bachelor")) {
        prefix = "wr"; // Preferred for Degree
      } else if (_selectedProgramme!.contains("Diploma")) {
        prefix = "wm";
      }

      String year = DateFormat('yy').format(DateTime.now());
      setState(() => _emailController.text = "$firstName$initials-$prefix$year@student.lumina.edu.my");
    }
  }

  void _onIcChanged() {
    String ic = _icController.text.replaceAll('-', '');
    if (ic.length >= 6) {
      int yearShort = int.parse(ic.substring(0, 2));
      int month = int.parse(ic.substring(2, 4));
      int day = int.parse(ic.substring(4, 6));

      if (month < 1 || month > 12) {
        setState(() => _dobController.text = "Invalid Month (01-12)");
        return;
      }

      int yearFull = (yearShort > 30) ? 1900 + yearShort : 2000 + yearShort;

      // --- FUTURE DATE CHECK ---
      DateTime now = DateTime.now();
      DateTime birthDate = DateTime(yearFull, month, day);

      if (birthDate.isAfter(now)) {
        setState(() => _dobController.text = "IC Date is in the future");
        return;
      }

      List<int> daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
      if ((yearFull % 4 == 0 && yearFull % 100 != 0) || (yearFull % 400 == 0)) daysInMonth[1] = 29;

      if (day < 1 || day > daysInMonth[month - 1]) {
        setState(() => _dobController.text = "Invalid Day for Month");
        return;
      }

      if (ic.length == 12) {
        String yearPrefix = (yearShort > 30) ? "19" : "20";
        setState(() {
          _dobController.text = "${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$yearPrefix${yearShort.toString().padLeft(2, '0')}";
          _selectedGender = (int.parse(ic.substring(11)) % 2 == 0) ? "Female" : "Male";
        });
      }
    }
  }

  Future<void> _registerStudent() async {
    final String name = _nameController.text.trim();
    final String icRaw = _icController.text.replaceAll('-', '');
    final String mobile = _mobileController.text.replaceAll('-', '');

    // --- STRICT VALIDATION ---
    if (name.isEmpty) {
      _showStatusSnackbar("Name Required", "Please enter the student's full name.", false);
      return;
    }
    if (icRaw.length < 12) {
      _showStatusSnackbar("IC Format", "MyKad must be 12 digits.", false);
      return;
    }
    // 1. Future Date Check (User is not born yet)
    if (_dobController.text.contains("future")) {
      _showStatusSnackbar(
          "Future Date Detected",
          "The IC indicates a birth date in the future. Please check the first 6 digits.",
          false
      );
      return;
    }
    // 2. Mathematical Check (e.g., 31st of February or Month 13)
    if (_dobController.text.contains("Invalid")) {
      _showStatusSnackbar(
          "Invalid Calendar Date",
          "The birth date in this IC is not a valid calendar date (e.g., wrong days for the month).",
          false
      );
      return;
    }
    // PHONE VALIDATION: Must start with 01
    if (!mobile.startsWith("01")) {
      _showStatusSnackbar("Invalid Mobile", "Phone number must start with '01'.", false);
      return;
    }
    if (mobile.length < 10 || mobile.length > 11) {
      _showStatusSnackbar("Invalid Mobile", "Phone number must be 10-11 digits.", false);
      return;
    }
    if (_selectedGroup == null) {
      _showStatusSnackbar("Group Missing", "Please select a Tutorial Group.", false);
      return;
    }
    if (_selectedProgramme == null) {
      _showStatusSnackbar("Programme Missing", "Please select a course.", false);
      return;
    }

    try {
      final now = DateTime.now();
      final yearDigit = DateFormat('yy').format(now);

      // --- LOGIC: ID GENERATION (WMR / WMD / JMR / JMD) ---
      // If Johor campus, use 'J', otherwise use 'W'
      String campusChar = (_selectedCampus == "Johor") ? "J" : "W";
      // Middle char is always 'M' as requested
      String levelChar = "M";
      // Last char is 'R' for Degree, 'D' for Diploma
      String typeChar = (_selectedProgramme!.contains("Diploma")) ? "D" : "R";

      String idPrefix = "$yearDigit$campusChar$levelChar$typeChar"; // e.g., 26WMR

      final response = await supabase
          .from('Student')
          .select('ID')
          .like('ID', '$idPrefix%')
          .order('ID', ascending: false)
          .limit(1)
          .maybeSingle();

      int nextSequence = 1;
      if (response != null) {
        String lastId = response['ID'].toString();
        // Take the last 5 digits and increment
        nextSequence = int.parse(lastId.substring(lastId.length - 5)) + 1;
      }

      String studentId = "$idPrefix${nextSequence.toString().padLeft(5, '0')}";

      await supabase.from('Student').insert({
        'ID': studentId,
        'Name': name,
        'Password': icRaw,
        'IC': _icController.text,
        'DateOfBirth': _dobController.text,
        'Gender': _selectedGender,
        'Email': _emailController.text,
        'TutorialGroup': _selectedGroup,
        'PhoneNumber': _mobileController.text,
        'Programme': _selectedProgramme,
        'Faculty': _selectedFaculty,
        'Address': _addressController.text,
        'Campus': _selectedCampus,
        'SessionJoined': now.month <= 6 ? "${now.year}05" : "${now.year}09",
      });

      _showStatusSnackbar("Registered!", "$name ($studentId) added successfully.", true);
      _resetForm();

    } catch (e) {
      _showStatusSnackbar("System Error", e.toString(), false);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _icController.clear();
    _dobController.clear();
    _mobileController.clear();
    _emailController.clear();
    _addressController.clear();
    setState(() {
      _selectedGroup = null;
      _selectedProgramme = null;
      _selectedFaculty = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF005A9C),
        title: const Text("Add New Student", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField("Full Name", _nameController, icon: Icons.person_outline),
              _buildTextField("Kad No (IC)", _icController, hint: "YYMMDD-XX-XXXX",
                  formatters: [FilteringTextInputFormatter.digitsOnly, DashFormatter([6, 8])],
                  keyboard: TextInputType.number, icon: Icons.badge_outlined),
              _buildDropdown("Gender", ["Male", "Female"], _selectedGender, (val) => setState(() => _selectedGender = val), icon: Icons.wc),
              _buildTextField("Date of Birth (Auto)", _dobController, readOnly: true, icon: Icons.calendar_month),
              _buildTextField("Mobile No", _mobileController, hint: "01X-XXXXXXX",
                  formatters: [FilteringTextInputFormatter.digitsOnly, DashFormatter([3])],
                  keyboard: TextInputType.phone, icon: Icons.phone_android),
              _buildTextField("Email Address (Auto)", _emailController, readOnly: true, icon: Icons.alternate_email),
              _buildDropdown("Tutorial Group", tutorialGroups, _selectedGroup, (val) => setState(() => _selectedGroup = val), icon: Icons.groups_outlined),


              // FIXED: Campus list must contain the default _selectedCampus value
              _buildDropdown(
                  "Campus Location",
                  ["Kuala Lumpur Campus", "Penang", "Johor"], // Ensure these strings match _selectedCampus
                  _selectedCampus,
                      (val) => setState(() => _selectedCampus = val),
                  icon: Icons.location_on_outlined
              ),
              // Categorized Programme
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DropdownButtonFormField<String>(
                  isExpanded: true, // Prevents horizontal overflow
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.school_outlined, color: Color(0xFF005A9C)),
                    labelText: "Programme",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  value: _selectedProgramme,
                  items: [
                    // --- Foundations Section ---
                    const DropdownMenuItem(
                        enabled: false,
                        child: Text("-- Foundations --", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))
                    ),
                    ...programmes['Foundation Programmes']!.map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p, overflow: TextOverflow.ellipsis)
                    )),
                    const DropdownMenuItem(
                        enabled: false,
                        child: Text("-- Diplomas --", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))
                    ),
                    ...programmes['Diploma Programmes']!.map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p, overflow: TextOverflow.ellipsis))
                    ),
                    const DropdownMenuItem(
                        enabled: false,
                        child: Text("-- Degrees --", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))
                    ),
                    ...programmes['Bachelor Degree Programmes']!.map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p, overflow: TextOverflow.ellipsis))
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedProgramme = val;
                      _selectedFaculty = programmeToFaculty[val];
                    });
                    _onNameChanged(); // Re-calculate email with the new prefix
                  },
                ),
              ),

              _buildReadOnlyInfo("Faculty", _selectedFaculty ?? "N/A", icon: Icons.account_balance),
              _buildTextField("Home Address", _addressController, maxLines: 3, icon: Icons.home_outlined),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005A9C),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: _registerStudent,
                child: const Text("Register Student", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 40), // Extra space for keyboard
            ],
          ),
        ),
      ),
    );
  }

  // UI Helpers (Same as before)
  Widget _buildTextField(String label, TextEditingController controller, {bool readOnly = false, String? hint, int maxLines = 1, List<TextInputFormatter>? formatters, TextInputType? keyboard, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        maxLines: maxLines,
        inputFormatters: formatters,
        keyboardType: keyboard,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF005A9C)),
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: readOnly,
          fillColor: readOnly ? Colors.grey[100] : Colors.white,
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List items, dynamic currentVal, Function(dynamic) onChange, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField(
        isExpanded: true,
        value: currentVal,
        decoration: InputDecoration(prefixIcon: Icon(icon, color: const Color(0xFF005A9C)), labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item.toString()))).toList(),
        onChanged: onChange,
      ),
    );
  }

  Widget _buildReadOnlyInfo(String label, String value, {IconData? icon}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.blueGrey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blueGrey.withOpacity(0.2))),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 11, color: Colors.blueGrey)), Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF005A9C)))]))
        ],
      ),
    );
  }
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Helper class for auto-formatting dashes
class DashFormatter extends TextInputFormatter {
  final List<int> dashPositions;
  DashFormatter(this.dashPositions);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll('-', '');
    // Limit to 12 digits (IC length)
    if (text.length > 12) return oldValue;

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (dashPositions.contains(i + 1) && i != text.length - 1) {
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

class RegisterStudentPage extends StatefulWidget {
  const RegisterStudentPage({super.key});

  @override
  State<RegisterStudentPage> createState() => _RegisterStudentPageState();
}

class _RegisterStudentPageState extends State<RegisterStudentPage> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _icController = TextEditingController();
  final _dobController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  String? _selectedGender;
  String? _selectedProgramme;
  String? _selectedFaculty;
  // FIXED: Value must exactly match an item in the list to avoid the red error screen
  String? _selectedCampus = "Kuala Lumpur Campus";
  int? _selectedGroup;

  final List<int> tutorialGroups = List.generate(20, (index) => index + 1);

  final Map<String, List<String>> programmes = {
    'Foundation Programmes': [
      'Foundation in Computing',
      'Foundation in Business',
      'Foundation in Arts',
    ],
    'Diploma Programmes': [
      'Diploma in Computer Science',
      'Diploma in Business Administration',
      'Diploma in Communication',
    ],
    'Bachelor Degree Programmes': [
      'Bachelor of Software Engineering (Honours)',
      'Bachelor of Computer Science (Honours)',
      'Bachelor of Business Administration (Honours)',
      'Bachelor of Accounting (Honours)',
      'Bachelor of Communication (Honours)',
    ],
  };

  final Map<String, String> programmeToFaculty = {
    // Foundation
    'Foundation in Computing': 'FOCS - Computing & Information Technology',
    'Foundation in Business': 'FAFB - Accountancy, Finance & Business',
    'Foundation in Arts': 'FCCI - Communication & Creative Industries',

    // Diploma
    'Diploma in Computer Science': 'FOCS - Computing & Information Technology',
    'Diploma in Business Administration': 'FAFB - Accountancy, Finance & Business',
    'Diploma in Communication': 'FCCI - Communication & Creative Industries',

    // Bachelor
    'Bachelor of Software Engineering (Honours)': 'FOCS - Computing & Information Technology',
    'Bachelor of Computer Science (Honours)': 'FOCS - Computing & Information Technology',
    'Bachelor of Business Administration (Honours)': 'FAFB - Accountancy, Finance & Business',
    'Bachelor of Accounting (Honours)': 'FAFB - Accountancy, Finance & Business',
    'Bachelor of Communication (Honours)': 'FCCI - Communication & Creative Industries',
  };

  @override
  void initState() {
    super.initState();
    _icController.addListener(_onIcChanged);
    _nameController.addListener(_onNameChanged);
  }

  void _showStatusSnackbar(String title, String message, bool isSuccess) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        dismissDirection: DismissDirection.up,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height - 160, left: 10, right: 10),
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSuccess ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(isSuccess ? Icons.check_circle : Icons.error, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(message, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TweenAnimationBuilder<double>(
                duration: const Duration(seconds: 4),
                tween: Tween(begin: 1.0, end: 0.0),
                builder: (context, value, child) => LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onNameChanged() {
    String name = _nameController.text.trim();

    if (name.isNotEmpty && _selectedProgramme != null) {
      List<String> parts = name.split(' ');
      String firstName = parts[0].toLowerCase();
      String initials = "";
      if (parts.length > 1) {
        for (int i = 1; i < parts.length; i++) {
          if (parts[i].isNotEmpty) initials += parts[i][0].toLowerCase();
        }
      }

      // Determine Prefix
      String prefix = "wm"; // Default
      if (_selectedProgramme!.contains("Foundation")) {
        prefix = "wp";
      } else if (_selectedProgramme!.contains("Bachelor")) {
        prefix = "wr"; // Preferred for Degree
      } else if (_selectedProgramme!.contains("Diploma")) {
        prefix = "wm";
      }

      String year = DateFormat('yy').format(DateTime.now());
      setState(() => _emailController.text = "$firstName$initials-$prefix$year@student.lumina.edu.my");
    }
  }

  void _onIcChanged() {
    String ic = _icController.text.replaceAll('-', '');
    if (ic.length >= 6) {
      int yearShort = int.parse(ic.substring(0, 2));
      int month = int.parse(ic.substring(2, 4));
      int day = int.parse(ic.substring(4, 6));

      if (month < 1 || month > 12) {
        setState(() => _dobController.text = "Invalid Month (01-12)");
        return;
      }

      int yearFull = (yearShort > 30) ? 1900 + yearShort : 2000 + yearShort;

      // --- FUTURE DATE CHECK ---
      DateTime now = DateTime.now();
      DateTime birthDate = DateTime(yearFull, month, day);

      if (birthDate.isAfter(now)) {
        setState(() => _dobController.text = "IC Date is in the future");
        return;
      }

      List<int> daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
      if ((yearFull % 4 == 0 && yearFull % 100 != 0) || (yearFull % 400 == 0)) daysInMonth[1] = 29;

      if (day < 1 || day > daysInMonth[month - 1]) {
        setState(() => _dobController.text = "Invalid Day for Month");
        return;
      }

      if (ic.length == 12) {
        String yearPrefix = (yearShort > 30) ? "19" : "20";
        setState(() {
          _dobController.text = "${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$yearPrefix${yearShort.toString().padLeft(2, '0')}";
          _selectedGender = (int.parse(ic.substring(11)) % 2 == 0) ? "Female" : "Male";
        });
      }
    }
  }

  Future<void> _registerStudent() async {
    final String name = _nameController.text.trim();
    final String icRaw = _icController.text.replaceAll('-', '');
    final String mobile = _mobileController.text.replaceAll('-', '');

    // --- STRICT VALIDATION ---
    if (name.isEmpty) {
      _showStatusSnackbar("Name Required", "Please enter the student's full name.", false);
      return;
    }
    if (icRaw.length < 12) {
      _showStatusSnackbar("IC Format", "MyKad must be 12 digits.", false);
      return;
    }
    // 1. Future Date Check (User is not born yet)
    if (_dobController.text.contains("future")) {
      _showStatusSnackbar(
          "Future Date Detected",
          "The IC indicates a birth date in the future. Please check the first 6 digits.",
          false
      );
      return;
    }
    // 2. Mathematical Check (e.g., 31st of February or Month 13)
    if (_dobController.text.contains("Invalid")) {
      _showStatusSnackbar(
          "Invalid Calendar Date",
          "The birth date in this IC is not a valid calendar date (e.g., wrong days for the month).",
          false
      );
      return;
    }
    // PHONE VALIDATION: Must start with 01
    if (!mobile.startsWith("01")) {
      _showStatusSnackbar("Invalid Mobile", "Phone number must start with '01'.", false);
      return;
    }
    if (mobile.length < 10 || mobile.length > 11) {
      _showStatusSnackbar("Invalid Mobile", "Phone number must be 10-11 digits.", false);
      return;
    }
    if (_selectedGroup == null) {
      _showStatusSnackbar("Group Missing", "Please select a Tutorial Group.", false);
      return;
    }
    if (_selectedProgramme == null) {
      _showStatusSnackbar("Programme Missing", "Please select a course.", false);
      return;
    }

    try {
      final now = DateTime.now();
      final yearDigit = DateFormat('yy').format(now);

      // --- LOGIC: ID GENERATION (WMR / WMD / JMR / JMD) ---
      // If Johor campus, use 'J', otherwise use 'W'
      String campusChar = (_selectedCampus == "Johor") ? "J" : "W";
      // Middle char is always 'M' as requested
      String levelChar = "M";
      // Last char is 'R' for Degree, 'D' for Diploma
      String typeChar = (_selectedProgramme!.contains("Diploma")) ? "D" : "R";

      String idPrefix = "$yearDigit$campusChar$levelChar$typeChar"; // e.g., 26WMR

      final response = await supabase
          .from('Student')
          .select('ID')
          .like('ID', '$idPrefix%')
          .order('ID', ascending: false)
          .limit(1)
          .maybeSingle();

      int nextSequence = 1;
      if (response != null) {
        String lastId = response['ID'].toString();
        // Take the last 5 digits and increment
        nextSequence = int.parse(lastId.substring(lastId.length - 5)) + 1;
      }

      String studentId = "$idPrefix${nextSequence.toString().padLeft(5, '0')}";

      await supabase.from('Student').insert({
        'ID': studentId,
        'Name': name,
        'Password': icRaw,
        'IC': _icController.text,
        'DateOfBirth': _dobController.text,
        'Gender': _selectedGender,
        'Email': _emailController.text,
        'TutorialGroup': _selectedGroup,
        'PhoneNumber': _mobileController.text,
        'Programme': _selectedProgramme,
        'Faculty': _selectedFaculty,
        'Address': _addressController.text,
        'Campus': _selectedCampus,
        'SessionJoined': now.month <= 6 ? "${now.year}05" : "${now.year}09",
      });

      _showStatusSnackbar("Registered!", "$name ($studentId) added successfully.", true);
      _resetForm();

    } catch (e) {
      _showStatusSnackbar("System Error", e.toString(), false);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _icController.clear();
    _dobController.clear();
    _mobileController.clear();
    _emailController.clear();
    _addressController.clear();
    setState(() {
      _selectedGroup = null;
      _selectedProgramme = null;
      _selectedFaculty = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF005A9C),
        title: const Text("Add New Student", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField("Full Name", _nameController, icon: Icons.person_outline),
              _buildTextField("Kad No (IC)", _icController, hint: "YYMMDD-XX-XXXX",
                  formatters: [FilteringTextInputFormatter.digitsOnly, DashFormatter([6, 8])],
                  keyboard: TextInputType.number, icon: Icons.badge_outlined),
              _buildDropdown("Gender", ["Male", "Female"], _selectedGender, (val) => setState(() => _selectedGender = val), icon: Icons.wc),
              _buildTextField("Date of Birth (Auto)", _dobController, readOnly: true, icon: Icons.calendar_month),
              _buildTextField("Mobile No", _mobileController, hint: "01X-XXXXXXX",
                  formatters: [FilteringTextInputFormatter.digitsOnly, DashFormatter([3])],
                  keyboard: TextInputType.phone, icon: Icons.phone_android),
              _buildTextField("Email Address (Auto)", _emailController, readOnly: true, icon: Icons.alternate_email),
              _buildDropdown("Tutorial Group", tutorialGroups, _selectedGroup, (val) => setState(() => _selectedGroup = val), icon: Icons.groups_outlined),


              // FIXED: Campus list must contain the default _selectedCampus value
              _buildDropdown(
                  "Campus Location",
                  ["Kuala Lumpur Campus", "Penang", "Johor"], // Ensure these strings match _selectedCampus
                  _selectedCampus,
                      (val) => setState(() => _selectedCampus = val),
                  icon: Icons.location_on_outlined
              ),
              // Categorized Programme
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DropdownButtonFormField<String>(
                  isExpanded: true, // Prevents horizontal overflow
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.school_outlined, color: Color(0xFF005A9C)),
                    labelText: "Programme",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  value: _selectedProgramme,
                  items: [
                    // --- Foundations Section ---
                    const DropdownMenuItem(
                        enabled: false,
                        child: Text("-- Foundations --", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))
                    ),
                    ...programmes['Foundation Programmes']!.map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p, overflow: TextOverflow.ellipsis)
                    )),
                    const DropdownMenuItem(
                        enabled: false,
                        child: Text("-- Diplomas --", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))
                    ),
                    ...programmes['Diploma Programmes']!.map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p, overflow: TextOverflow.ellipsis))
                    ),
                    const DropdownMenuItem(
                        enabled: false,
                        child: Text("-- Degrees --", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))
                    ),
                    ...programmes['Bachelor Degree Programmes']!.map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p, overflow: TextOverflow.ellipsis))
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedProgramme = val;
                      _selectedFaculty = programmeToFaculty[val];
                    });
                    _onNameChanged(); // Re-calculate email with the new prefix
                  },
                ),
              ),

              _buildReadOnlyInfo("Faculty", _selectedFaculty ?? "N/A", icon: Icons.account_balance),
              _buildTextField("Home Address", _addressController, maxLines: 3, icon: Icons.home_outlined),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005A9C),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: _registerStudent,
                child: const Text("Register Student", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 40), // Extra space for keyboard
            ],
          ),
        ),
      ),
    );
  }

  // UI Helpers (Same as before)
  Widget _buildTextField(String label, TextEditingController controller, {bool readOnly = false, String? hint, int maxLines = 1, List<TextInputFormatter>? formatters, TextInputType? keyboard, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        maxLines: maxLines,
        inputFormatters: formatters,
        keyboardType: keyboard,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF005A9C)),
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: readOnly,
          fillColor: readOnly ? Colors.grey[100] : Colors.white,
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List items, dynamic currentVal, Function(dynamic) onChange, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField(
        isExpanded: true,
        value: currentVal,
        decoration: InputDecoration(prefixIcon: Icon(icon, color: const Color(0xFF005A9C)), labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item.toString()))).toList(),
        onChanged: onChange,
      ),
    );
  }

  Widget _buildReadOnlyInfo(String label, String value, {IconData? icon}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.blueGrey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blueGrey.withOpacity(0.2))),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 11, color: Colors.blueGrey)), Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF005A9C)))]))
        ],
      ),
    );
  }
}