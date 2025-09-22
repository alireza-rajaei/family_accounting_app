import '../../domain/repositories/i_backup_repository.dart';
import '../local/db/app_database.dart';
import 'dart:convert';

class BackupRepositoryAdapter implements IBackupRepository {
  final AppDatabase db;
  BackupRepositoryAdapter(this.db);

  @override
  Future<String> exportJson() async {
    final admins = await db.select(db.admins).get();
    final users = await db.select(db.users).get();
    final banks = await db.select(db.banks).get();
    final transactions = await db.select(db.transactions).get();
    final loans = await db.select(db.loans).get();
    final payments = await db.select(db.loanPayments).get();

    final map = {
      'admins': admins.map((e) => e.toJson()).toList(),
      'users': users.map((e) => e.toJson()).toList(),
      'banks': banks.map((e) => e.toJson()).toList(),
      'transactions': transactions.map((e) => e.toJson()).toList(),
      'loans': loans.map((e) => e.toJson()).toList(),
      'loan_payments': payments.map((e) => e.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  @override
  Future<void> importJson(Map<String, dynamic> json) async {
    await db.transaction(() async {
      await db.delete(db.loanPayments).go();
      await db.delete(db.transactions).go();
      await db.delete(db.loans).go();
      await db.delete(db.banks).go();
      await db.delete(db.users).go();
      await db.delete(db.admins).go();

      Future<void> insertMany<T>(
        List<dynamic>? list,
        Future<void> Function(Map<String, dynamic>) insert,
      ) async {
        if (list == null) return;
        for (final item in list.cast<Map<String, dynamic>>()) {
          await insert(item);
        }
      }

      final admins = (json['admins'] as List?)?.cast<Map<String, dynamic>>();
      final users = (json['users'] as List?)?.cast<Map<String, dynamic>>();
      final banks = (json['banks'] as List?)?.cast<Map<String, dynamic>>();
      final transactions = (json['transactions'] as List?)
          ?.cast<Map<String, dynamic>>();
      final loans = (json['loans'] as List?)?.cast<Map<String, dynamic>>();
      final payments = (json['loan_payments'] as List?)
          ?.cast<Map<String, dynamic>>();

      await insertMany(
        admins,
        (m) async => await db
            .into(db.admins)
            .insert(Admin.fromJson(m).toCompanion(true)),
      );
      await insertMany(
        users,
        (m) async =>
            await db.into(db.users).insert(User.fromJson(m).toCompanion(true)),
      );
      await insertMany(
        banks,
        (m) async =>
            await db.into(db.banks).insert(Bank.fromJson(m).toCompanion(true)),
      );
      await insertMany(
        transactions,
        (m) async => await db
            .into(db.transactions)
            .insert(Transaction.fromJson(m).toCompanion(true)),
      );
      await insertMany(
        loans,
        (m) async =>
            await db.into(db.loans).insert(Loan.fromJson(m).toCompanion(true)),
      );
      await insertMany(
        payments,
        (m) async => await db
            .into(db.loanPayments)
            .insert(LoanPayment.fromJson(m).toCompanion(true)),
      );
    });
  }
}
