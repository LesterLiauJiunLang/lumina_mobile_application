class Student {
  final String id;
  final String? ic;
  final String? email;
  final String? gender;
  final String? dob;
  final String? phoneNumber;
  final String? address;
  final String? campus;
  final String? faculty;
  final String? programme;
  final double? tutorialGroup; // Using double because table is numeric
  final double? sessionJoined;
  final String? password;
  final String? name;

  Student({
    required this.id,
    this.ic,
    this.email,
    this.gender,
    this.dob,
    this.phoneNumber,
    this.address,
    this.campus,
    this.faculty,
    this.programme,
    this.tutorialGroup,
    this.sessionJoined,
    this.password,
    this.name,
  });
  //Student
  // Maps Supabase columns to Student object fields
  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['ID'] ?? '',
      ic: json['IC'],
      email: json['Email'],
      gender: json['Gender'],
      dob: json['DateOfBirth'],
      phoneNumber: json['PhoneNumber'],
      address: json['Address'],
      campus: json['Campus'],
      faculty: json['Faculty'],
      programme: json['Programme'],
      // Handle numeric type safely
      tutorialGroup: json['TutorialGroup']?.toDouble(),
      sessionJoined: json['SessionJoined']?.toDouble(),
      password: json['Password'],
      name: json['Name'],
    );
  }
class Student {
  final String id;
  final String? ic;
  final String? email;
  final String? gender;
  final String? dob;
  final String? phoneNumber;
  final String? address;
  final String? campus;
  final String? faculty;
  final String? programme;
  final double? tutorialGroup; // Using double because table is numeric
  final double? sessionJoined;
  final String? password;
  final String? name;

  Student({
    required this.id,
    this.ic,
    this.email,
    this.gender,
    this.dob,
    this.phoneNumber,
    this.address,
    this.campus,
    this.faculty,
    this.programme,
    this.tutorialGroup,
    this.sessionJoined,
    this.password,
    this.name,
  });
  //Student
  // Maps Supabase columns to Student object fields
  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['ID'] ?? '',
      ic: json['IC'],
      email: json['Email'],
      gender: json['Gender'],
      dob: json['DateOfBirth'],
      phoneNumber: json['PhoneNumber'],
      address: json['Address'],
      campus: json['Campus'],
      faculty: json['Faculty'],
      programme: json['Programme'],
      // Handle numeric type safely
      tutorialGroup: json['TutorialGroup']?.toDouble(),
      sessionJoined: json['SessionJoined']?.toDouble(),
      password: json['Password'],
      name: json['Name'],
    );
  }
}