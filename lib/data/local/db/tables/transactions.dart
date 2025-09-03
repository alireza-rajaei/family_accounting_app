part of '../tables.dart';

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
