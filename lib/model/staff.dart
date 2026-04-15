class Staff {
  final String id;
  final String? name;
  final String? password;
  final String? email;
  final String? faculty;
  final String? jobTitle;
  final String? campus;
  final String? officeRoom;
  final String? phoneNumber;
  final String? joinedDate; // Stored as timestamptz in Supabase

  Staff({
    required this.id,
    this.name,
    this.password,
    this.email,
    this.faculty,
    this.jobTitle,
    this.campus,
    this.officeRoom,
    this.phoneNumber,
    this.joinedDate,
  });

  // Maps Supabase Staff table columns to Staff object fields
  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['ID'] ?? '',
      name: json['Name'],
      password: json['Password'],
      email: json['Email'],
      faculty: json['Faculty'],
      jobTitle: json['JobTitle'],
      campus: json['Campus'],
      officeRoom: json['OfficeRoom'],
      phoneNumber: json['PhoneNumber'],
      // joinedDate is timestamptz, which comes as a String from Supabase
      joinedDate: json['JoinedDate'],
    );
  }

  // Optional: Map back to JSON if you need to update profile
  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'Name': name,
      'Password': password,
      'Email': email,
      'Faculty': faculty,
      'JobTitle': jobTitle,
      'Campus': campus,
      'OfficeRoom': officeRoom,
      'PhoneNumber': phoneNumber,
      'JoinedDate': joinedDate,
    };
  }
}