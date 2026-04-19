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
        final enrollmentRes = await supabase
            .from('Enrollment')
            .select('Course_ID')
            .eq('Student_ID', student.id);
        
        List<String> courseIds = (enrollmentRes as List)
            .map((e) => e['Course_ID'].toString())
            .toList();

        String filter;
        if (courseIds.isEmpty) {
          filter = 'Type.eq.General,Type.eq.Student';
        } else {
          filter = 'Type.eq.General,Type.eq.Student,Course_ID.in.("${courseIds.join('","')}")';
        }

        data = await supabase
            .from('Announcement')
            .select('*, Course:Course_ID(Name)')
            .or(filter)
            .order('Created_At', ascending: false);

      } else {
        final staff = widget.user as Staff;
        bool isSuperAdmin = staff.id.startsWith('SU');

        if (isSuperAdmin) {
          data = await supabase
              .from('Announcement')
              .select('*, Course:Course_ID(Name)')
              .order('Created_At', ascending: false);
        } else {
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

  void _showOptions(Announcement ann) {
    if (widget.user is! Staff) return;
    final staff = widget.user as Staff;
    bool isSuperAdmin = staff.id.startsWith('SU');
    bool isCreator = ann.createdBy == staff.id;

    if (!isSuperAdmin && !isCreator) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.blue),
            title: const Text('Edit Announcement'),
            onTap: () {
              Navigator.pop(context);
              _editAnnouncement(ann);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Delete Announcement'),
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(ann);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _editAnnouncement(Announcement ann) async {
    // FIX: Passing both staff and the announcement correctly in a Map
    final result = await Navigator.pushNamed(context, '/create_announcement', arguments: {
      'staff': widget.user as Staff,
      'editAnnouncement': ann,
    });
    if (result == true) {
      setState(() => _isLoading = true);
      _fetchAnnouncements();
    }
  }

  void _confirmDelete(Announcement ann) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete?'),
        content: const Text('Are you sure you want to remove this announcement?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAnnouncement(ann.id);
            }, 
            child: const Text('Delete', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAnnouncement(String id) async {
    try {
      await supabase.from('Announcement').delete().eq('ID', id);
      _showStatusSnackbar('Announcement Deleted', true);
      _fetchAnnouncements();
    } catch (e) {
      _showStatusSnackbar('Delete Failed: $e', false);
    }
  }

  void _showStatusSnackbar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isSuccess ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
        behavior: SnackBarBehavior.floating,
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isStaff = widget.user is Staff;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        backgroundColor: _mainBlue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          tabs: const [Tab(text: 'OFFICIAL'), Tab(text: 'CLASSES')],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => _fetchAnnouncements()),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAnnouncementList(_announcements.where((a) => a.type != 'Course').toList()),
                _buildAnnouncementList(_announcements.where((a) => a.type == 'Course').toList()),
              ],
            ),
      floatingActionButton: isStaff
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.pushNamed(context, '/create_announcement', arguments: widget.user);
                if (result == true) _fetchAnnouncements();
              },
              backgroundColor: _mainBlue,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildAnnouncementList(List<Announcement> list) {
    if (list.isEmpty) return const Center(child: Text('No announcements found'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final ann = list[index];
        bool isStaff = widget.user is Staff;
        
        return InkWell(
          onLongPress: isStaff ? () => _showOptions(ann) : null,
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardHeader(ann),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ann.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(ann.content, style: TextStyle(fontSize: 14, color: Colors.grey[800])),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardHeader(Announcement ann) {
    Color color;
    String label;
    switch (ann.type) {
      case 'General': color = Colors.orange[900]!; label = 'OFFICIAL'; break;
      case 'Student': color = Colors.teal[700]!; label = 'STUDENTS'; break;
      case 'Staff': color = Colors.purple[700]!; label = 'STAFF'; break;
      default: color = _mainBlue; label = ann.courseName ?? 'CLASS';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          const Spacer(),
          Text(DateFormat('MMM dd').format(DateTime.parse(ann.createdAt)), style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}