class UserEntity {
  final int id;
  final String firstName;
  final String lastName;
  final String? fatherName;
  final String? mobileNumber;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserEntity({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.fatherName,
    this.mobileNumber,
    required this.createdAt,
    this.updatedAt,
  });
}
