import 'package:supabase_flutter/supabase_flutter.dart';

class ConflictDetector {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Checks if a new or updated personal event conflicts with existing events
  /// (both course schedule and other personal events) on the same day.
  ///
  /// Returns a list of conflicting event descriptions, or an empty list if none.
  Future<List<String>> checkConflicts({
    required String studentId,
    required String day,
    required String startTime,
    required String endTime,
    String? excludeEventId, // for editing, exclude the event itself
  }) async {
    final List<String> conflicts = [];

    // 1. Check against course schedule (from Enrollment + Schedule)
    final enrollments = await _supabase
        .from('Enrollment')
        .select('Course_ID')
        .eq('Student_ID', studentId);
    final courseIds = enrollments.map((e) => e['Course_ID'] as String).toList();

    if (courseIds.isNotEmpty) {
      final schedule = await _supabase
          .from('Schedule')
          .select('*, Course(Name)')
          .inFilter('Course_ID', courseIds)
          .eq('DayOfWeek', day.toUpperCase()) // Supabase stores days uppercase
          .order('StartTime');

      for (var course in schedule) {
        final courseStart = course['StartTime'] as String;
        final courseEnd = course['EndTime'] as String;
        if (_isOverlapping(startTime, endTime, courseStart, courseEnd)) {
          final courseName = course['Course']?['Name'] ?? course['Course_ID'];
          conflicts.add('Course: $courseName (${_formatTime(courseStart)} - ${_formatTime(courseEnd)})');
        }
      }
    }

    // 2. Check against other personal events (excluding current if editing)
    var query = _supabase
        .from('personal_events')
        .select()
        .eq('student_id', studentId)
        .eq('day', day);

    if (excludeEventId != null) {
      query = query.neq('id', excludeEventId);
    }

    final personalEvents = await query;
    for (var event in personalEvents) {
      final eventStart = event['start_time'] as String;
      final eventEnd = event['end_time'] as String;
      if (_isOverlapping(startTime, endTime, eventStart, eventEnd)) {
        conflicts.add('Personal: ${event['title']} (${_formatTime(eventStart)} - ${_formatTime(eventEnd)})');
      }
    }

    return conflicts;
  }

  /// Returns true if two time intervals overlap.
  bool _isOverlapping(String start1, String end1, String start2, String end2) {
    // Convert "HH:MM" to minutes since midnight for easy comparison
    int toMinutes(String time) {
      final parts = time.split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    }

    final s1 = toMinutes(start1);
    final e1 = toMinutes(end1);
    final s2 = toMinutes(start2);
    final e2 = toMinutes(end2);

    return s1 < e2 && s2 < e1;
  }

  String _formatTime(String time) {
    final parts = time.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return time;
  }

  /// Check for schedule conflicts with other schedule entries (for staff editing)
  Future<List<String>> checkConflictsForSchedule({
    required String courseId,
    required String day,
    required String startTime,
    required String endTime,
    String? excludeEntryId,
  }) async {
    final List<String> conflicts = [];

    // Fetch all schedule entries for the same day (excluding this course if editing)
    var query = _supabase
        .from('Schedule')
        .select('*, Course(Name)')
        .eq('DayOfWeek', day)
        .neq('Course_ID', courseId); // exclude same course? Actually we need all courses on same day

    if (excludeEntryId != null) {
      query = query.neq('ID', excludeEntryId);
    }

    final entries = await query;
    for (var entry in entries) {
      final entryStart = entry['StartTime'] as String;
      final entryEnd = entry['EndTime'] as String;
      if (_isOverlapping(startTime, endTime, entryStart, entryEnd)) {
        final courseName = entry['Course']?['Name'] ?? entry['Course_ID'];
        conflicts.add('$courseName (${_formatTime(entryStart)} - ${_formatTime(entryEnd)})');
      }
    }
    return conflicts;
  }

}

