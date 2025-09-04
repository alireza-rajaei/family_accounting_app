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
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      // Ensure foreign keys are enforced for cascade deletes
      await customStatement('PRAGMA foreign_keys = ON');
    },
    onUpgrade: (m, from, to) async {
      // No-op on create; constraints declared in table definitions apply
      if (from < 2) {
        // Normalize amounts by making withdrawals negative and deposits positive
        await customStatement("""
UPDATE transactions
SET amount = CASE WHEN type = 'withdraw' THEN -ABS(amount) ELSE ABS(amount) END
""");
        // Map old type + kind columns into unified Persian type values
        await customStatement("""
UPDATE transactions
SET type = CASE
  WHEN deposit_kind = 'deposit_to_bank_transfer' OR withdraw_kind = 'withdraw_from_bank_transfer' THEN 'جابجایی بین بانکی'
  WHEN withdraw_kind = 'loan_principal' THEN 'پرداخت وام به کاربر'
  WHEN deposit_kind = 'loan_installment' THEN 'پرداخت قسط وام'
  WHEN deposit_kind = 'deposit_to_user' THEN 'واریز'
  WHEN withdraw_kind = 'withdraw_from_user' THEN 'برداشت'
  ELSE type
END
""");
        // Drop old columns by recreating the table without them
        await m.alterTable(
          TableMigration(
            transactions,
            newColumns: [
              transactions.id,
              transactions.bankId,
              transactions.userId,
              transactions.amount,
              transactions.type,
              transactions.note,
              transactions.createdAt,
              transactions.updatedAt,
            ],
          ),
        );
      }
      if (from < 3) {
        // Rebuild banks table to drop deprecated bank_name column using SQL to avoid
        // columnTransformer issues on some older schemas.
        await customStatement('''
CREATE TABLE IF NOT EXISTS banks_new (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  bank_key TEXT NOT NULL,
  account_name TEXT NOT NULL,
  account_number TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER
);
''');
        await customStatement('''
INSERT INTO banks_new (id, bank_key, account_name, account_number, created_at, updated_at)
SELECT id, bank_key, account_name, account_number, created_at, updated_at FROM banks;
''');
        await customStatement('DROP TABLE banks;');
        await customStatement('ALTER TABLE banks_new RENAME TO banks;');
      }
      if (from < 4) {
        // Ensure legacy schemas have the optional loan_id column before copying
        try {
          await customStatement(
            'ALTER TABLE transactions ADD COLUMN loan_id INTEGER',
          );
        } catch (_) {
          // Ignore if the column already exists
        }
        // Recreate tables with ON DELETE CASCADE constraints where needed
        // 1) transactions references banks, users, loans
        await customStatement('''
CREATE TABLE IF NOT EXISTS transactions_new (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  bank_id INTEGER NOT NULL REFERENCES banks(id) ON DELETE CASCADE,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  loan_id INTEGER REFERENCES loans(id) ON DELETE CASCADE,
  amount INTEGER NOT NULL,
  type TEXT NOT NULL,
  note TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER
);
''');
        await customStatement('''
INSERT INTO transactions_new (id, bank_id, user_id, loan_id, amount, type, note, created_at, updated_at)
SELECT id, bank_id, user_id, loan_id, amount, type, note, created_at, updated_at FROM transactions;
''');
        await customStatement('DROP TABLE transactions;');
        await customStatement(
          'ALTER TABLE transactions_new RENAME TO transactions;',
        );

        // 2) loans references users
        await customStatement('''
CREATE TABLE IF NOT EXISTS loans_new (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  principal_amount INTEGER NOT NULL,
  installments INTEGER NOT NULL,
  note TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER
);
''');
        await customStatement('''
INSERT INTO loans_new (id, user_id, principal_amount, installments, note, created_at, updated_at)
SELECT id, user_id, principal_amount, installments, note, created_at, updated_at FROM loans;
''');
        await customStatement('DROP TABLE loans;');
        await customStatement('ALTER TABLE loans_new RENAME TO loans;');

        // 3) loan_payments references loans and transactions
        await customStatement('''
CREATE TABLE IF NOT EXISTS loan_payments_new (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  loan_id INTEGER NOT NULL REFERENCES loans(id) ON DELETE CASCADE,
  transaction_id INTEGER NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  amount INTEGER NOT NULL,
  paid_at INTEGER NOT NULL
);
''');
        await customStatement('''
INSERT INTO loan_payments_new (id, loan_id, transaction_id, amount, paid_at)
SELECT id, loan_id, transaction_id, amount, paid_at FROM loan_payments;
''');
        await customStatement('DROP TABLE loan_payments;');
        await customStatement(
          'ALTER TABLE loan_payments_new RENAME TO loan_payments;',
        );
      }
    },
  );
}

// platform-specific implementation in connection/connection_*.dart
