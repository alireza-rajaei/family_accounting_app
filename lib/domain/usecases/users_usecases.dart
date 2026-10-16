import '../entities/user.dart';
import '../repositories/i_users_repository.dart';

class WatchUsersUseCase {
  final IUsersRepository repo;
  WatchUsersUseCase(this.repo);
  Stream<List<UserEntity>> call(String query) => repo.watchUsers(query);
}

class AddUserUseCase {
  final IUsersRepository repo;
  AddUserUseCase(this.repo);
  Future<int> call({
    required String firstName,
    required String lastName,
    String? fatherName,
    String? mobileNumber,
    String? membershipNumber,
  }) => repo.addUser(
    firstName: firstName,
    lastName: lastName,
    fatherName: fatherName,
    mobileNumber: mobileNumber,
    membershipNumber: membershipNumber,
  );
}

class UpdateUserUseCase {
  final IUsersRepository repo;
  UpdateUserUseCase(this.repo);
  Future<void> call({
    required int id,
    required String firstName,
    required String lastName,
    String? fatherName,
    String? mobileNumber,
    String? membershipNumber,
  }) => repo.updateUser(
    id: id,
    firstName: firstName,
    lastName: lastName,
    fatherName: fatherName,
    mobileNumber: mobileNumber,
    membershipNumber: membershipNumber,
  );
}

class DeleteUserCascadeUseCase {
  final IUsersRepository repo;
  DeleteUserCascadeUseCase(this.repo);
  Future<void> call(int userId) => repo.deleteUserCascade(userId);
}

class GetUserBalanceUseCase {
  final IUsersRepository repo;
  GetUserBalanceUseCase(this.repo);
  Future<int> call(int userId) => repo.getUserBalance(userId);
}

class GetUserLoansRemainingUseCase {
  final IUsersRepository repo;
  GetUserLoansRemainingUseCase(this.repo);
  Future<int> call(int userId) => repo.getUserLoansRemaining(userId);
}
