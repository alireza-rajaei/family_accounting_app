import '../entities/bank.dart';
import '../repositories/i_banks_repository.dart';

class WatchBanksWithBalanceUseCase {
  final IBanksRepository repo;
  WatchBanksWithBalanceUseCase(this.repo);
  Stream<List<BankWithBalanceEntity>> call({String query = ''}) =>
      repo.watchBanksWithBalance(query: query);
}

class AddBankUseCase {
  final IBanksRepository repo;
  AddBankUseCase(this.repo);
  Future<int> call({
    required String bankKey,
    required String accountName,
    required String accountNumber,
  }) => repo.addBank(
    bankKey: bankKey,
    accountName: accountName,
    accountNumber: accountNumber,
  );
}

class UpdateBankUseCase {
  final IBanksRepository repo;
  UpdateBankUseCase(this.repo);
  Future<void> call({
    required int id,
    required String bankKey,
    required String accountName,
    required String accountNumber,
  }) => repo.updateBank(
    id: id,
    bankKey: bankKey,
    accountName: accountName,
    accountNumber: accountNumber,
  );
}

class DeleteBankUseCase {
  final IBanksRepository repo;
  DeleteBankUseCase(this.repo);
  Future<void> call(int id) => repo.deleteBank(id);
}
