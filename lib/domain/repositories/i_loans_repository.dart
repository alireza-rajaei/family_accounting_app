import '../entities/loan.dart';
import '../entities/bank.dart';
import '../entities/transaction.dart';

abstract class ILoansRepository {
  Stream<List<LoanWithStatsEntity>> watchLoans();
  Future<int> addLoan({
    required int userId,
    required int principalAmount,
    required int installments,
    String? note,
  });
  Future<int> addLoanWithTransaction({
    required int userId,
    required int bankId,
    required int principalAmount,
    required int installments,
    String? note,
  });
  Future<void> updateLoan({
    required int id,
    required int userId,
    required int principalAmount,
    required int installments,
    String? note,
  });
  Future<void> deleteLoan(int id);
  Stream<List<(LoanPaymentEntity, TransactionEntity, BankEntity)>>
  watchPayments(int loanId);
  Future<void> addPayment({
    required int loanId,
    required int bankId,
    required int amount,
    String? note,
  });
  Future<int?> getPrincipalBankIdForLoan(int loanId);
  Stream<List<(TransactionEntity, BankEntity)>> watchLoanTransactions(
    int loanId,
  );
}
