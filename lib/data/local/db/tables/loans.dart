part of '../tables.dart';

class Loans extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer()
      .named('user_id')
      .references(Users, #id, onDelete: KeyAction.cascade)();
  IntColumn get principalAmount => integer().named('principal_amount')();
  IntColumn get installments => integer().named('installments')();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}
