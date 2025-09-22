import '../entities/loan.dart';
import '../entities/bank.dart';
import '../entities/transaction.dart';
import '../repositories/i_loans_repository.dart';

class WatchLoansUseCase {
  final ILoansRepository repo;
  WatchLoansUseCase(this.repo);
  Stream<List<LoanWithStatsEntity>> call() => repo.watchLoans();
}

class AddLoanWithTransactionUseCase {
  final ILoansRepository repo;
  AddLoanWithTransactionUseCase(this.repo);
  Future<int> call({
    required int userId,
    required int bankId,
    required int principalAmount,
    required int installments,
    String? note,
  }) => repo.addLoanWithTransaction(
    userId: userId,
    bankId: bankId,
    principalAmount: principalAmount,
    installments: installments,
    note: note,
  );
}

class UpdateLoanUseCase {
  final ILoansRepository repo;
  UpdateLoanUseCase(this.repo);
  Future<void> call({
    required int id,
    required int userId,
    required int principalAmount,
    required int installments,
    String? note,
  }) => repo.updateLoan(
    id: id,
    userId: userId,
    principalAmount: principalAmount,
    installments: installments,
    note: note,
  );
}

class DeleteLoanUseCase {
  final ILoansRepository repo;
  DeleteLoanUseCase(this.repo);
  Future<void> call(int id) => repo.deleteLoan(id);
}

class WatchPaymentsUseCase {
  final ILoansRepository repo;
  WatchPaymentsUseCase(this.repo);
  Stream<List<(LoanPaymentEntity, TransactionEntity, BankEntity)>> call(
    int loanId,
  ) => repo.watchPayments(loanId);
}

class AddPaymentUseCase {
  final ILoansRepository repo;
  AddPaymentUseCase(this.repo);
  Future<void> call({
    required int loanId,
    required int bankId,
    required int amount,
    String? note,
  }) => repo.addPayment(
    loanId: loanId,
    bankId: bankId,
    amount: amount,
    note: note,
  );
}

class GetPrincipalBankIdForLoanUseCase {
  final ILoansRepository repo;
  GetPrincipalBankIdForLoanUseCase(this.repo);
  Future<int?> call(int loanId) => repo.getPrincipalBankIdForLoan(loanId);
}

class WatchLoanTransactionsUseCase {
  final ILoansRepository repo;
  WatchLoanTransactionsUseCase(this.repo);
  Stream<List<(TransactionEntity, BankEntity)>> call(int loanId) =>
      repo.watchLoanTransactions(loanId);
}
