import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'model/student.dart';
import 'model/staff.dart';
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  final supabase = Supabase.instance.client;

  // --- BEAUTIFUL SNACKBAR VALIDATION ---
  void _showStatusSnackbar(String title, String message, bool isSuccess) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSuccess ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
            ],
          ),
          child: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error_outline,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    Text(
                      message,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    String input = _idController.text.trim().toUpperCase();
    String password = _passwordController.text.trim();

    if (input.isEmpty || password.isEmpty) {
      _showStatusSnackbar("Required Fields", "Please enter ID and Password.", false);
      return;
    }

    setState(() => _isLoading = true);
    String finalId = input;

    // Student ID transformation logic (keeping your existing logic)
    if (input.length == 7 && !input.contains('WMR')) {
      finalId = "${input.substring(0, 2)}WMR${input.substring(2)}";
    }

    try {
      // 1. TRY LOGIN AS STUDENT
      final studentRes = await supabase
          .from('Student')
          .select()
          .eq('ID', finalId)
          .eq('Password', password)
          .maybeSingle();

      if (studentRes != null) {
        final user = Student.fromJson(studentRes);
        _proceedToDashboard('/student_dashboard', user);
        return;
      }

      // 2. IF NOT STUDENT, TRY LOGIN AS STAFF
      final staffRes = await supabase
          .from('Staff') // Make sure your table name is 'Staff'
          .select()
          .eq('ID', input) // Staff might not use the WMR transformation
          .eq('Password', password)
          .maybeSingle();

      if (staffRes != null) {
        final staffUser = Staff.fromJson(staffRes);
        _proceedToDashboard('/staff_dashboard', staffUser);

      } else {
        _showStatusSnackbar("Login Failed", "Invalid ID or Password.", false);
      }
    } catch (e) {
      _showStatusSnackbar("Error", "System error: $e", false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

// Helper to handle navigation
  void _proceedToDashboard(String route, dynamic data) {
    if (mounted) {
      _showStatusSnackbar("Success", "Welcome back!", true);
      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.pushReplacementNamed(context, route, arguments: data);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF005A9C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context); // Goes back to Dashboard or Home
            } else {
              Navigator.pushReplacementNamed(context, '/'); // Fallback to Home
            }
          },
        ),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.white),
            SizedBox(width: 10),
            Text('Login',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Image.asset(
                'assets/images/logo.png',
                height: 120,
                errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.broken_image, size: 100, color: Colors.red),
              ),
            ),
            const SizedBox(height: 40),

            // --- USER ID FIELD (Underlined Style) ---
            const Text('User ID',
                style: TextStyle(
                    color: Color(0xFF005A9C),
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            TextField(
              controller: _idController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'e.g. 23WMR00001',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF005A9C), width: 2),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF005A9C), width: 3),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // --- PASSWORD FIELD (Underlined Style) ---
            const Text('Password',
                style: TextStyle(
                    color: Color(0xFF005A9C),
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                hintText: 'Your Password',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 1),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF005A9C), width: 2),
                ),
                suffixIcon: IconButton(
                  icon: Icon(_isPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off),
                  color: const Color(0xFF005A9C),
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
              ),
            ),

            const SizedBox(height: 50),

            // --- LOGIN BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005A9C),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 2,
                ),
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                    : const Text('Login',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}