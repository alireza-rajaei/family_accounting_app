class BankEntity {
  final int id;
  final String bankKey;
  final String accountName;
  final String accountNumber;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const BankEntity({
    required this.id,
    required this.bankKey,
    required this.accountName,
    required this.accountNumber,
    required this.createdAt,
    this.updatedAt,
  });
}

class BankWithBalanceEntity {
  final BankEntity bank;
  final int balance;
  const BankWithBalanceEntity({required this.bank, required this.balance});
}
