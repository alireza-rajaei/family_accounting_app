class LoanEntity {
  final int id;
  final int userId;
  final int principalAmount;
  final int installments;
  final String? note;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const LoanEntity({
    required this.id,
    required this.userId,
    required this.principalAmount,
    required this.installments,
    this.note,
    required this.createdAt,
    this.updatedAt,
  });
}

class LoanWithStatsEntity {
  final LoanEntity loan;
  final int paidAmount;
  const LoanWithStatsEntity({required this.loan, required this.paidAmount});
  int get remaining => loan.principalAmount - paidAmount;
  bool get settled => remaining <= 0;
}

class LoanPaymentEntity {
  final int id;
  final int loanId;
  final int transactionId;
  final int amount;
  final DateTime paidAt;
  const LoanPaymentEntity({
    required this.id,
    required this.loanId,
    required this.transactionId,
    required this.amount,
    required this.paidAt,
  });
}
