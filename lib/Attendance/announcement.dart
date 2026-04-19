class Announcement {
  final String id;
  final String title;
  final String content;
  final String type; // 'General' or 'Course'
  final String? courseId;
  final String createdBy;
  final String createdAt;
  final String? courseName; // Joined from Course table

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
      id: json['ID'],
      title: json['Title'] ?? '',
      content: json['Content'] ?? '',
      type: json['Type'] ?? 'General',
      courseId: json['Course_ID'],
      createdBy: json['Created_By'] ?? '',
      createdAt: json['Created_At'] ?? '',
      courseName: json['Course'] != null ? json['Course']['Name'] : null,
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