import 'package:drift/drift.dart' as d;

import '../local/db/app_database.dart';

class BankWithBalance {
  final Bank bank;
  final int balance;
  BankWithBalance({required this.bank, required this.balance});
}

class BanksRepository {
  final AppDatabase db;
  BanksRepository(this.db);

  Stream<List<BankWithBalance>> watchBanksWithBalance({String query = ''}) {
    final t = db.transactions;
    final b = db.banks;

    final signedAmount = d.CaseWhen<int>(
      [
        d.CaseWhenEntry(t.type.equals('deposit'), then: t.amount),
      ],
      else_: t.amount * d.Constant(-1),
    );

    final sumExpr = d.sum(signedAmount);

    final base = db.select(b).join([
      d.leftOuterJoin(
        db.selectOnly(t)
          ..addColumns([t.bankId, sumExpr])
          ..groupBy([t.bankId]),
        t.bankId.equalsExp(b.id),
      )
    ]);

    if (query.trim().isNotEmpty) {
      final pattern = '%${query.trim()}%';
      base.where(b.bankName.like(pattern) | b.accountName.like(pattern) | b.accountNumber.like(pattern));
    }

    base.orderBy([
      d.OrderingTerm.asc(b.bankName),
      d.OrderingTerm.asc(b.accountName),
    ]);

    return base.watch().map((rows) {
      return rows.map((r) {
        final bank = r.readTable(b);
        final balance = r.read(sumExpr) ?? 0;
        return BankWithBalance(bank: bank, balance: balance);
      }).toList();
    });
  }

  Future<int> addBank({
    required String bankKey,
    required String bankName,
    required String accountName,
    required String accountNumber,
  }) async {
    return db.into(db.banks).insert(BanksCompanion.insert(
          bankKey: bankKey,
          bankName: bankName,
          accountName: accountName,
          accountNumber: accountNumber,
        ));
  }

  Future<void> updateBank({
    required int id,
    required String bankKey,
    required String bankName,
    required String accountName,
    required String accountNumber,
  }) async {
    await (db.update(db.banks)..where((tbl) => tbl.id.equals(id))).write(BanksCompanion(
      bankKey: d.Value(bankKey),
      bankName: d.Value(bankName),
      accountName: d.Value(accountName),
      accountNumber: d.Value(accountNumber),
      updatedAt: d.Value(DateTime.now()),
    ));
  }

  Future<void> deleteBank(int id) async {
    await (db.delete(db.banks)..where((tbl) => tbl.id.equals(id))).go();
  }
}


