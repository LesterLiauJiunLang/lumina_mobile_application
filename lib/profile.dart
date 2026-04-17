import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'model/student.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';



class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  File? _profileImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final student = ModalRoute.of(context)!.settings.arguments as Student;
      _loadImage(student.id);
    });
  }

  Future<void> _loadImage(String studentId) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$studentId.jpg';

    final file = File(path);

    if (await file.exists()) {
      setState(() {
        _profileImage = file;
      });
    }
  }


  bool _isUploading = false; // Add this at the top of your _ProfilePageState class

  Future<void> _pickImage(String studentId) async {
    final picker = ImagePicker();
    final supabase = Supabase.instance.client;

    // 1. Pick Source
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 10),
            const Text("Change Profile Photo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFE3F2FD), child: Icon(Icons.camera_alt, color: Color(0xFF005A9C))),
              title: const Text("Take a New Photo"),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFE8F5E9), child: Icon(Icons.photo_library, color: Colors.green)),
              title: const Text("Choose from Gallery"),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 25),
          ],
        ),
      ),
    );

    if (source == null) return;

    final pickedFile = await picker.pickImage(source: source, imageQuality: 40);

    if (pickedFile != null) {
      setState(() => _isUploading = true); // Start Spinner

      try {
        final file = File(pickedFile.path);
        final String fileName = '$studentId.jpg';

        // 1. Upload to Storage (Bucket: avatars)
        await supabase.storage.from('avatars').upload(
            fileName,
            file,
            fileOptions: const FileOptions(upsert: true)
        );

        // 2. Get Public URL + Timestamp (to force refresh)
        final String rawUrl = supabase.storage.from('avatars').getPublicUrl(fileName);
        final String publicUrl = "$rawUrl?v=${DateTime.now().millisecondsSinceEpoch}";

        // 3. Update Database Table (Table: Student)
        await supabase.from('Student').update({
          'profile_image': publicUrl
        }).eq('ID', studentId);

        setState(() {
          _profileImage = file;
          _isUploading = false;
        });

        _showBeautifulSnackBar("Success!", "Your profile has been updated.", Colors.green, Icons.verified);

      } catch (e) {
        setState(() => _isUploading = false);
        print("CRITICAL ERROR: $e");
        _showBeautifulSnackBar("Upload Failed", e.toString(), Colors.redAccent, Icons.error_outline);
      }
    }
  }

// THE BEAUTIFUL SNACKBAR
  void _showBeautifulSnackBar(String title, String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 30),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                    Text(message, style: const TextStyle(fontSize: 13, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Catch student data
    final student = ModalRoute.of(context)!.settings.arguments as Student;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF005A9C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Profile',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            // Profile Image Section
            Center(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue.shade100, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: const Color(0xFFF3F6F9),
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : (student.profileImage != null ? NetworkImage(student.profileImage!) as ImageProvider : null),
                      child: _isUploading
                          ? const CircularProgressIndicator(color: Color(0xFF005A9C)) // Show this while uploading
                          : (_profileImage == null && student.profileImage == null)
                          ? const Icon(Icons.person, size: 80, color: Color(0xFFBDBDBD))
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 5,
                    right: 5,
                    child: GestureDetector(
                      onTap: () => _pickImage(student.id),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Text(
              student.name ?? "N/A",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Student",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Divider(indent: 20, endIndent: 20),

            // Profile Info List
            _buildProfileItem("Student ID", student.id),
            _buildProfileItem("Email", student.email ?? "N/A"),
            _buildProfileItem("Campus", student.campus ?? "Kuala Lumpur Campus"),
            _buildProfileItem("Faculty", student.faculty ?? "Faculty of Computing"),
            _buildProfileItem("Programme", student.programme ?? "N/A"),
            _buildProfileItem(
                "Tutorial Group",
                student.tutorialGroup?.toInt().toString() ?? "N/A"
            ),
            _buildProfileItem(
                "Session Joined",
                student.sessionJoined?.toInt().toString() ?? "N/A"
            ),

            const SizedBox(height: 40),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F), // Red color
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () {
                    // Navigate back to Home and clear stack
                    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                  },
                  child: const Text(
                    "Logout",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 15),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}