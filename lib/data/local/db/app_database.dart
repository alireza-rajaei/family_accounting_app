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
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
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
        // Drop bank_name column by recreating banks table without it
        await m.alterTable(
          TableMigration(
            banks,
            newColumns: [
              banks.id,
              banks.bankKey,
              banks.accountName,
              banks.accountNumber,
              banks.createdAt,
              banks.updatedAt,
            ],
            // Explicitly map columns from the old table using bare names (no alias)
            columnTransformer: {
              banks.id: const CustomExpression('id'),
              banks.bankKey: const CustomExpression('bank_key'),
              banks.accountName: const CustomExpression('account_name'),
              banks.accountNumber: const CustomExpression('account_number'),
              banks.createdAt: const CustomExpression('created_at'),
              banks.updatedAt: const CustomExpression('updated_at'),
            },
          ),
        );
      }
    },
  );
}

// platform-specific implementation in connection/connection_*.dart
