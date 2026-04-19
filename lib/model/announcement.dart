class Announcement {
  final String id;
  final String title;
  final String content;
  final String type; // 'General', 'Student', 'Staff', 'Course'
  final String? courseId;
  final String createdBy;
  final String createdAt;
  final String? courseName;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    this.courseId,
    required this.createdBy,
    required this.createdAt,
    this.courseName,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['ID']?.toString() ?? '',
      title: json['Title'] ?? '',
      content: json['Content'] ?? '',
      type: json['Type'] ?? 'General',
      courseId: json['Course_ID']?.toString(),
      createdBy: json['Created_By']?.toString() ?? '',
      createdAt: json['Created_At'] ?? DateTime.now().toIso8601String(),
      courseName: json['Course'] != null ? json['Course']['Name']?.toString() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Title': title,
      'Content': content,
      'Type': type,
      'Course_ID': courseId,
      'Created_By': createdBy,
    };
  }
}