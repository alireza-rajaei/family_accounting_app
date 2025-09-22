import '../entities/bank.dart';

abstract class IBanksRepository {
  Stream<List<BankWithBalanceEntity>> watchBanksWithBalance({
    String query = '',
  });
  Future<int> addBank({
    required String bankKey,
    required String accountName,
    required String accountNumber,
  });
  Future<void> updateBank({
    required int id,
    required String bankKey,
    required String accountName,
    required String accountNumber,
  });
  Future<void> deleteBank(int id);
}
