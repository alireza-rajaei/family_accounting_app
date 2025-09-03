part of '../tables.dart';

class LoanPayments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get loanId => integer().named('loan_id').references(Loans, #id)();
  IntColumn get transactionId =>
      integer().named('transaction_id').references(Transactions, #id)();
  IntColumn get amount => integer()();
  DateTimeColumn get paidAt => dateTime().withDefault(currentDateAndTime)();
}
