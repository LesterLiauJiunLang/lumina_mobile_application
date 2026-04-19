import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'model/staff.dart';

class CreateAnnouncementScreen extends StatefulWidget {
  final Staff staff;
  const CreateAnnouncementScreen({super.key, required this.staff});

  @override
  State<CreateAnnouncementScreen> createState() => _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final supabase = Supabase.instance.client;
  
  String _selectedType = 'Course'; // 'General', 'Student', 'Staff', 'Course'
  String? _selectedCourseId;
  List<Map<String, dynamic>> _courses = [];
  bool _isLoading = false;
  bool _isSuperAdmin = false;

  final Color _mainBlue = const Color(0xFF005A9C);

  @override
  void initState() {
    super.initState();
    // Logic: Only IDs starting with "SU" are Superadmins
    _isSuperAdmin = widget.staff.id.startsWith('SU');
    
    if (!_isSuperAdmin) {
      _selectedType = 'Course';
    }
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    try {
      // Start the base query
      var request = supabase.from('Course').select('ID, Name');
      
      // LOGICAL FIX: Reassign the request with the filter to make it stick
      // If we don't reassign, the filter is calculated but discarded.
      if (!_isSuperAdmin) {
        request = request.eq('Staff_ID', widget.staff.id);
      }
      
      final data = await request;
      setState(() {
        _courses = List<Map<String, dynamic>>.from(data);
        if (_courses.isNotEmpty) {
          _selectedCourseId = _courses.first['ID'];
        }
      });
    } catch (e) {
      debugPrint('Error fetching courses: $e');
    }
  }

  Future<void> _submitAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedType == 'Course' && _selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a course')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await supabase.from('Announcement').insert({
        'Title': _titleController.text.trim(),
        'Content': _contentController.text.trim(),
        'Type': _selectedType,
        'Course_ID': _selectedType == 'Course' ? _selectedCourseId : null,
        'Created_By': widget.staff.id,
      });

      if (mounted) {
        Navigator.pop(context, true);
        _showStatusSnackbar('Announcement Posted', true);
      }
    } catch (e) {
      if (mounted) _showStatusSnackbar('Error: $e', false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showStatusSnackbar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isSuccess ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
        behavior: SnackBarBehavior.floating,
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Announcement'),
        backgroundColor: _mainBlue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Target Audience', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (_isSuperAdmin) ...[
                          _buildTypeChip('General'),
                          _buildTypeChip('Student'),
                          _buildTypeChip('Staff'),
                        ],
                        _buildTypeChip('Course'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (_selectedType == 'Course') ...[
                      const Text('Select Course', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedCourseId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        items: _courses.isEmpty 
                          ? [const DropdownMenuItem(value: null, child: Text("No assigned courses found"))]
                          : _courses.map((c) {
                          return DropdownMenuItem<String>(
                            value: c['ID'],
                            child: Text(c['Name'], overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedCourseId = val),
                        validator: (val) => val == null && _selectedType == 'Course' ? 'Course is required' : null,
                      ),
                      const SizedBox(height: 24),
                    ],
                    const Text('Title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Headline of announcement',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 24),
                    const Text('Message Content', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _contentController,
                      maxLines: 6,
                      decoration: InputDecoration(
                        hintText: 'Write your message here...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Content is required' : null,
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _mainBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _submitAnnouncement,
                        child: const Text('Post Now', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTypeChip(String label) {
    bool isSelected = _selectedType == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: _mainBlue,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
      onSelected: (val) => setState(() => _selectedType = label),
    );
  }
}