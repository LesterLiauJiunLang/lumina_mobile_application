import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final client = Supabase.instance.client;

  // --- QUIZ OPERATIONS ---

  static Future<void> updateQuizTitle({
    required String quizId,
    required String newTitle,
  }) async {
    try {
      await client
          .from('quizzes')
          .update({'title': newTitle})
          .eq('id', quizId); // ✅ changed
    } catch (e) {
      print("Error updating quiz title: $e");
      rethrow;
    }
  }

  static Future<void> deleteQuiz(String quizId) async {
    try {
      await client
          .from('quizzes')
          .delete()
          .eq('id', quizId); // ✅ changed
    } catch (e) {
      print("Error deleting quiz: $e");
      rethrow;
    }
  }

  // --- QUESTION OPERATIONS ---

  static Future<void> addQuestion({
    required String quizId,
    required String question,
    required String a,
    required String b,
    required String c,
    required String d,
    required int correctIndex,
  }) async {
    await client.from('questions').insert({
      'quiz_id': quizId, // ✅ changed
      'question': question,
      'option_a': a,
      'option_b': b,
      'option_c': c,
      'option_d': d,
      'correct_index': correctIndex.toString(),
    });
  }

  static Future<void> updateQuestion({
    required dynamic id,
    required String question,
    required String a,
    required String b,
    required String c,
    required String d,
    required int correctIndex,
  }) async {
    try {
      await client.from('questions').update({
        'question': question,
        'option_a': a,
        'option_b': b,
        'option_c': c,
        'option_d': d,
        'correct_index': correctIndex.toString(),
      }).eq('id', id);
    } catch (e) {
      print("Error updating question: $e");
      rethrow;
    }
  }

  static Future<void> deleteQuestion(dynamic id) async {
    try {
      await client.from('questions').delete().eq('id', id);
    } catch (e) {
      print("Error deleting question: $e");
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getQuestions(String quizId) async {
    try {
      final List<Map<String, dynamic>> response = await client
          .from('questions')
          .select()
          .eq('quiz_id', quizId) // ✅ changed
          .order('id', ascending: true);
      return response;
    } catch (e) {
      print("Error fetching questions: $e");
      rethrow;
    }
  }

  // --- ATTEMPT OPERATIONS ---

  static Future<void> saveAttempt({
    required String quizId,
    required String studentId,
    required int score,
    required int total,
  }) async {
    try {
      await client.from('attempts').insert({
        'quiz_id': quizId, // ✅ changed
        'student_id': studentId,
        'score': score,
        'total': total,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print("Error saving attempt: $e");
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getStudentPerformance(
      String quizId, String studentId) async {
    try {
      final response = await client
          .from('attempts')
          .select()
          .eq('quiz_id', quizId) // ✅ changed
          .eq('student_id', studentId)
          .order('created_at', ascending: true);
      return response;
    } catch (e) {
      print("Error fetching performance: $e");
      rethrow;
    }
  }
}