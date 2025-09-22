import '../entities/transaction.dart';

abstract class ITransactionsRepository {
  Stream<List<TransactionAggregate>> watchTransactions(
    TransactionsFilterEntity f,
  );
  Future<List<TransactionAggregate>> fetchTransactions(
    TransactionsFilterEntity f, {
    int limit = 50,
    int offset = 0,
  });
  Future<int> addTransaction({
    required int bankId,
    int? userId,
    required int amount,
    required String type,
    String? note,
    DateTime? createdAt,
  });
  Future<void> updateTransaction({
    required int id,
    required int bankId,
    int? userId,
    required int amount,
    required String type,
    String? note,
  });
  Future<void> deleteTransaction(int id);
  Future<void> transferBetweenBanks({
    required int fromBankId,
    required int toBankId,
    required int amount,
    String? note,
  });

  Stream<List<(String bankKey, int deposit, int withdraw)>> watchBankFlowSums();
}
