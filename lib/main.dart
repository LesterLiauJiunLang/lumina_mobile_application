import 'package:flutter/material.dart';
import 'package:lumina_mobile_application/staff_create_quiz.dart';
import 'package:lumina_mobile_application/staff_dashboard_quiz.dart';
import 'package:lumina_mobile_application/staff_directory.dart';
import 'package:lumina_mobile_application/staff_distribution_chart.dart';
import 'package:lumina_mobile_application/staff_view_all_quiz.dart';
import 'package:lumina_mobile_application/student_directory.dart';
import 'package:lumina_mobile_application/update_staff.dart';
import 'package:lumina_mobile_application/view_staff.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer';
import 'admin_add_staff.dart';
import 'all_score_quiz_screen.dart';
import 'model/student.dart';
import 'model/staff.dart';
import 'home.dart';
import 'login.dart';
import 'view_user.dart';
import 'profile.dart';
import 'register_student.dart';
import 'student_dashboard.dart';
import 'staff_dashboard.dart';
import 'staff_profile.dart';
import 'student_dashboard_quiz.dart';
import 'Attendance/attendance_history_screen.dart';
import 'Attendance/student_attendance_scanner.dart';
import 'Timetable/timetable_screen.dart';
import 'Attendance/staff_attendance.dart';


const String supabaseUrl='https://ipclprhdqqxczshihwot.supabase.co';
const String supabaseKey='sb_secret_eDCpEf5_rrI_1aKoTGidNw_lxN5Z82s';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  runApp(const CampusApp());
}

class CampusApp extends StatelessWidget {
  const CampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lumina Hub',
      theme: ThemeData(
        primaryColor: const Color(0xFF005A9C),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF005A9C)),
      ),
      // '/' tells Flutter to look at the routes below and load the HomePage first
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/student_dashboard': (context) {
          final student = ModalRoute.of(context)!.settings.arguments as Student;
          return const StudentDashboard();
        },
        '/view_user': (context) => const ViewUserPage(title: 'Student Management',),
        '/register_student': (context) => const RegisterStudentPage(),
        '/profile': (context) => const ProfilePage(),
        '/staff_dashboard': (context) => const StaffDashboard(),
        '/staff_profile': (context) => const StaffProfilePage(),
        '/staff_directory': (context) => const StaffDirectoryPage(),
        '/student_directory': (context) => const StudentDirectoryPage(),
        '/admin_add_staff': (context) => const AdminAddStaffPage(),
        '/view_staff': (context) => const ViewStaffPage(),
        '/student_dashboard_quiz' : (context) => const StudentDashboardQuiz(),
        '/staff_dashboard_quiz' : (context) => const StaffDashboardQuiz(),
        '/create_quiz': (context) => const StaffCreateQuizScreen(),
        '/view_all_quiz': (context) => const StaffViewAllQuizScreen(),
        '/quiz_results': (context) => const AllScoreQuizScreen(),
        '/attendance_history': (context) => const AttendanceHistoryScreen(isStaff: false),
        '/attendance_scanner': (context) => const StudentAttendanceScanner(),
        '/timetable': (context) {
          final student = ModalRoute.of(context)!.settings.arguments as Student;
          return TimetableScreen(studentId: student.id);
        },
        '/attendance': (context) => const StaffAttendanceDashboard(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});


  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {

      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(

        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        title: Text(widget.title),
      ),
      body: Center(

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
