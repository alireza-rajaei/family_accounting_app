import '../entities/transaction.dart';
import '../repositories/i_transactions_repository.dart';

class WatchTransactionsUseCase {
  final ITransactionsRepository repo;
  WatchTransactionsUseCase(this.repo);
  Stream<List<TransactionAggregate>> call(TransactionsFilterEntity f) =>
      repo.watchTransactions(f);
}

class FetchTransactionsUseCase {
  final ITransactionsRepository repo;
  FetchTransactionsUseCase(this.repo);
  Future<List<TransactionAggregate>> call(
    TransactionsFilterEntity f, {
    int limit = 50,
    int offset = 0,
  }) => repo.fetchTransactions(f, limit: limit, offset: offset);
}

class AddTransactionUseCase {
  final ITransactionsRepository repo;
  AddTransactionUseCase(this.repo);
  Future<int> call({
    required int bankId,
    int? userId,
    required int amount,
    required String type,
    String? note,
    DateTime? createdAt,
  }) => repo.addTransaction(
    bankId: bankId,
    userId: userId,
    amount: amount,
    type: type,
    note: note,
    createdAt: createdAt,
  );
}

class UpdateTransactionUseCase {
  final ITransactionsRepository repo;
  UpdateTransactionUseCase(this.repo);
  Future<void> call({
    required int id,
    required int bankId,
    int? userId,
    required int amount,
    required String type,
    String? note,
  }) => repo.updateTransaction(
    id: id,
    bankId: bankId,
    userId: userId,
    amount: amount,
    type: type,
    note: note,
  );
}

class DeleteTransactionUseCase {
  final ITransactionsRepository repo;
  DeleteTransactionUseCase(this.repo);
  Future<void> call(int id) => repo.deleteTransaction(id);
}

class TransferBetweenBanksUseCase {
  final ITransactionsRepository repo;
  TransferBetweenBanksUseCase(this.repo);
  Future<void> call({
    required int fromBankId,
    required int toBankId,
    required int amount,
    String? note,
  }) => repo.transferBetweenBanks(
    fromBankId: fromBankId,
    toBankId: toBankId,
    amount: amount,
    note: note,
  );
}

class WatchBankFlowSumsUseCase {
  final ITransactionsRepository repo;
  WatchBankFlowSumsUseCase(this.repo);
  Stream<List<(String bankKey, int deposit, int withdraw)>> call() =>
      repo.watchBankFlowSums();
}
