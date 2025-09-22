abstract class IAuthRepository {
  Future<bool> hasAnyAdmin();
  Future<void> createInitialAdmin(String username, String password);
  Future<bool> login(String username, String password);
}
