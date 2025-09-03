import 'package:drift/drift.dart';

class Admins extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text().withLength(min: 3, max: 64)();
  TextColumn get passwordHash => text().withLength(min: 32, max: 256)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get lastLoginAt => dateTime().nullable()();
}

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get firstName => text().named('first_name')();
  TextColumn get lastName => text().named('last_name')();
  TextColumn get fatherName => text().named('father_name').nullable()();
  TextColumn get mobileNumber => text().named('mobile_number').nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

class Banks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get bankKey => text().named('bank_key')();
  TextColumn get bankName => text().named('bank_name')();
  TextColumn get accountName => text().named('account_name')();
  TextColumn get accountNumber => text().named('account_number')();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

enum TransactionType { deposit, withdraw }

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get bankId => integer().named('bank_id').references(Banks, #id)();
  IntColumn get userId =>
      integer().named('user_id').nullable().references(Users, #id)();
  IntColumn get amount => integer()();
  TextColumn get type => text()(); // unified type in Persian
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

class Loans extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().named('user_id').references(Users, #id)();
  IntColumn get principalAmount => integer().named('principal_amount')();
  IntColumn get installments => integer().named('installments')();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

class LoanPayments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get loanId => integer().named('loan_id').references(Loans, #id)();
  IntColumn get transactionId =>
      integer().named('transaction_id').references(Transactions, #id)();
  IntColumn get amount => integer()();
  DateTimeColumn get paidAt => dateTime().withDefault(currentDateAndTime)();
}
