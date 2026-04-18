import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'model/announcement.dart';
import 'model/student.dart';
import 'model/staff.dart';

class AnnouncementScreen extends StatefulWidget {
  final dynamic user; 
  const AnnouncementScreen({super.key, required this.user});

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Announcement> _announcements = [];
  final Color _mainBlue = const Color(0xFF005A9C);
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchAnnouncements();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAnnouncements() async {
    try {
      List<dynamic> data;
      
      if (widget.user is Student) {
        final student = widget.user as Student;
        // 1. Get courses student is enrolled in
        final enrollmentRes = await supabase
            .from('Enrollment')
            .select('Course_ID')
            .eq('Student_ID', student.id);
        
        List<String> courseIds = (enrollmentRes as List)
            .map((e) => e['Course_ID'].toString())
            .toList();

        // 2. Fetch General, Student, and Course announcements (filtered)
        String filter;
        if (courseIds.isEmpty) {
          filter = 'Type.eq.General,Type.eq.Student';
        } else {
          // or(Type.eq.General,Type.eq.Student,Course_ID.in.(CS001,CS002))
          filter = 'Type.eq.General,Type.eq.Student,Course_ID.in.(${courseIds.join(",")})';
        }

        data = await supabase
            .from('Announcement')
            .select('*, Course:Course_ID(Name)')
            .or(filter)
            .order('Created_At', ascending: false);

      } else {
        // Staff view
        final staff = widget.user as Staff;
        bool isSuperAdmin = staff.jobTitle?.toLowerCase() == 'superadmin';

        if (isSuperAdmin) {
          // Superadmins see everything
          data = await supabase
              .from('Announcement')
              .select('*, Course:Course_ID(Name)')
              .order('Created_At', ascending: false);
        } else {
          // Regular staff see General, Staff, and Course announcements they created
          data = await supabase
              .from('Announcement')
              .select('*, Course:Course_ID(Name)')
              .or('Type.eq.General,Type.eq.Staff,Created_By.eq.${staff.id}')
              .order('Created_At', ascending: false);
        }
      }

      setState(() {
        _announcements = data.map((json) => Announcement.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching announcements: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isStaff = widget.user is Staff;
    bool canPost = false;
    if (isStaff) {
      final staff = widget.user as Staff;
      canPost = staff.jobTitle?.toLowerCase() == 'superadmin' || 
                staff.jobTitle?.toLowerCase().contains('lecturer') == true ||
                staff.jobTitle?.toLowerCase().contains('tutor') == true;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        backgroundColor: _mainBlue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Official'),
            Tab(text: 'Classes'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchAnnouncements();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Official (General, Student, Staff)
                _buildAnnouncementList(_announcements.where((a) => a.type != 'Course').toList()),
                // Tab 2: Classes (Course)
                _buildAnnouncementList(_announcements.where((a) => a.type == 'Course').toList()),
              ],
            ),
      floatingActionButton: canPost
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.pushNamed(context, '/create_announcement', arguments: widget.user);
                if (result == true) {
                  setState(() => _isLoading = true);
                  _fetchAnnouncements();
                }
              },
              backgroundColor: _mainBlue,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildAnnouncementList(List<Announcement> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('No announcements found', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final ann = list[index];
        final bool isCourse = ann.type == 'Course';
        
        Color headerColor;
        String label;
        IconData icon;

        switch (ann.type) {
          case 'General':
            headerColor = Colors.orange[900]!;
            label = 'OFFICIAL';
            icon = Icons.public;
            break;
          case 'Student':
            headerColor = Colors.teal[700]!;
            label = 'FOR STUDENTS';
            icon = Icons.school;
            break;
          case 'Staff':
            headerColor = Colors.purple[700]!;
            label = 'FOR STAFF';
            icon = Icons.badge;
            break;
          default: // Course
            headerColor = _mainBlue;
            label = ann.courseName ?? 'CLASS UPDATE';
            icon = Icons.book_outlined;
        }
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: headerColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 16, color: headerColor),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: headerColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('MMM dd, yyyy').format(DateTime.parse(ann.createdAt)),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ann.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ann.content,
                      style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}