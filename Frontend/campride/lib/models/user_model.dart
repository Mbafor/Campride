class UserModel {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String role;
  final String? studentId;
  final String? phoneNumber;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.role,
    this.studentId,
    this.phoneNumber,
  });

  factory UserModel.mockStudent() => const UserModel(
        id: 'student_001',
        name: 'Kwame Mensah',
        email: 'kwame.mensah@st.knust.edu.gh',
        role: 'student',
        studentId: '0020250001',
        phoneNumber: '+233 24 000 0001',
      );

  factory UserModel.mockDriver() => const UserModel(
        id: 'driver_001',
        name: 'Kofi Asante',
        email: 'kofi.asante@knust.edu.gh',
        role: 'driver',
        phoneNumber: '+233 20 000 0002',
        studentId: null,
      );
}
