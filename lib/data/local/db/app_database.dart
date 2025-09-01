import 'package:drift/drift.dart';
import 'package:drift/native.dart'
    show NativeDatabase; // for AppDatabase.test()

import 'tables.dart';
import 'connection/connection.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Admins, Users, Banks, Transactions, Loans, LoanPayments],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  // In-memory constructor for tests
  AppDatabase.test() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;
}

// platform-specific implementation in connection/connection_*.dart
