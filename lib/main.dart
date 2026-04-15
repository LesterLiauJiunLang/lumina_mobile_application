import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer';
import 'model/student.dart';
import 'home.dart';
import 'login.dart';
import 'view_user.dart';
import 'profile.dart';
import 'register_student.dart';
import 'student_dashboard.dart';
import 'staff_dashboard.dart';
import 'staff_profile.dart';
const String supabaseUrl='https://ipclprhdqqxczshihwot.supabase.co';
const String supabaseKey='sb_secret_eDCpEf5_rrI_1aKoTGidNw_lxN5Z82s';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
          // This part is critical to receive the data during navigation
          final student = ModalRoute.of(context)!.settings.arguments as Student;
          return StudentDashboard();
          // return StudentDashboard(student: student);
        },
        '/view_user': (context) => const ViewUserPage(title: 'Student Management',),
        '/register_student': (context) => const RegisterStudentPage(),
        '/profile': (context) => const ProfilePage(),
        '/staff_dashboard': (context) => const StaffDashboard(),
        '/staff_profile': (context) => const StaffProfilePage(),
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

          mainAxisAlignment: .center,
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
