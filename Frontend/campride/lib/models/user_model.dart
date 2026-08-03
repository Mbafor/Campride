class UserModel {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String role;
  final String? studentId;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.role,
    this.studentId,
  });

  /// First name(s) = full name minus the last word.
  String get firstName {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length <= 1) return name.trim();
    return parts.sublist(0, parts.length - 1).join(' ');
  }

  /// Last name = the last word of the full name.
  String get lastName {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.last;
  }

  factory UserModel.mockStudent() => const UserModel(
        id: 'student_001',
        name: 'Kwame Mensah',
        email: 'kwame.mensah@st.knust.edu.gh',
        role: 'student',
        studentId: '0020250001',
      );

  factory UserModel.mockDriver() => const UserModel(
        id: 'driver_001',
        name: 'Kofi Asante',
        email: 'kofi.asante@knust.edu.gh',
        role: 'driver',
        studentId: null,
      );

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    String? role,
    String? studentId,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      studentId: studentId ?? this.studentId,
    );
  }
}
