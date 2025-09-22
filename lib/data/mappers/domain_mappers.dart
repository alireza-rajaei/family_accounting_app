import '../../domain/entities/user.dart';
import '../../domain/entities/bank.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/loan.dart';
import '../local/db/app_database.dart';

extension UserToEntity on User {
  UserEntity toEntity() => UserEntity(
    id: id,
    firstName: firstName,
    lastName: lastName,
    fatherName: fatherName,
    mobileNumber: mobileNumber,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

extension BankToEntity on Bank {
  BankEntity toEntity() => BankEntity(
    id: id,
    bankKey: bankKey,
    accountName: accountName,
    accountNumber: accountNumber,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

extension TransactionToEntity on Transaction {
  TransactionEntity toEntity() => TransactionEntity(
    id: id,
    bankId: bankId,
    userId: userId,
    loanId: loanId,
    amount: amount,
    type: type,
    note: note,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

extension LoanToEntity on Loan {
  LoanEntity toEntity() => LoanEntity(
    id: id,
    userId: userId,
    principalAmount: principalAmount,
    installments: installments,
    note: note,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

extension LoanPaymentToEntity on LoanPayment {
  LoanPaymentEntity toEntity() => LoanPaymentEntity(
    id: id,
    loanId: loanId,
    transactionId: transactionId,
    amount: amount,
    paidAt: paidAt,
  );
}
