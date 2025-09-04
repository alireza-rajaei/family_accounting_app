part of '../tables.dart';

class Banks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get bankKey => text().named('bank_key')();
  TextColumn get accountName => text().named('account_name')();
  TextColumn get accountNumber => text().named('account_number')();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}
