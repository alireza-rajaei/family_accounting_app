import '../entities/user.dart';

abstract class IUsersRepository {
  Stream<List<UserEntity>> watchUsers(String query);
  Future<int> addUser({
    required String firstName,
    required String lastName,
    String? fatherName,
    String? mobileNumber,
    String? membershipNumber,
  });
  Future<void> updateUser({
    required int id,
    required String firstName,
    required String lastName,
    String? fatherName,
    String? mobileNumber,
    String? membershipNumber,
  });
  Future<void> deleteUserCascade(int userId);
  Future<int> getUserBalance(int userId);
  Future<int> getUserLoansRemaining(int userId);
}
