import 'bank.dart';
import 'user.dart';

class TransactionEntity {
  final int id;
  final int bankId;
  final int? userId;
  final int? loanId;
  final int amount;
  final String type;
  final String? note;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const TransactionEntity({
    required this.id,
    required this.bankId,
    this.userId,
    this.loanId,
    required this.amount,
    required this.type,
    this.note,
    required this.createdAt,
    this.updatedAt,
  });
}

class TransactionAggregate {
  final TransactionEntity transaction;
  final BankEntity bank;
  final UserEntity? user;
  const TransactionAggregate({
    required this.transaction,
    required this.bank,
    this.user,
  });
}

class TransactionsFilterEntity {
  final DateTime? from;
  final DateTime? to;
  final String? type;
  final int? userId;
  final int? bankId;
  const TransactionsFilterEntity({
    this.from,
    this.to,
    this.type,
    this.userId,
    this.bankId,
  });

  TransactionsFilterEntity copyWith({
    DateTime? from,
    DateTime? to,
    String? type,
    int? userId,
    int? bankId,
  }) => TransactionsFilterEntity(
    from: from ?? this.from,
    to: to ?? this.to,
    type: type ?? this.type,
    userId: userId ?? this.userId,
    bankId: bankId ?? this.bankId,
  );
}
