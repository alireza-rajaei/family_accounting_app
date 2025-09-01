import 'package:drift/drift.dart' as d;

import '../local/db/app_database.dart';

class TransactionWithJoins {
  final Transaction transaction;
  final User? user;
  final Bank bank;
  TransactionWithJoins({required this.transaction, required this.bank, this.user});
}

class TransactionsFilter {
  final DateTime? from;
  final DateTime? to;
  final String? type; // 'deposit' | 'withdraw' | null
  final String? depositKind; // when type == 'deposit'
  final String? withdrawKind; // when type == 'withdraw'
  final int? userId;
  final int? bankId;
  const TransactionsFilter({this.from, this.to, this.type, this.depositKind, this.withdrawKind, this.userId, this.bankId});
}

class TransactionsRepository {
  final AppDatabase db;
  TransactionsRepository(this.db);

  Stream<List<TransactionWithJoins>> watchTransactions(TransactionsFilter f) {
    final whereClauses = <String>[];
    final vars = <d.Variable>[];

    if (f.from != null) {
      whereClauses.add('t.created_at >= ?');
      vars.add(d.Variable<DateTime>(f.from!));
    }
    if (f.to != null) {
      whereClauses.add('t.created_at <= ?');
      vars.add(d.Variable<DateTime>(f.to!));
    }
    if (f.type != null) {
      whereClauses.add('t.type = ?');
      vars.add(d.Variable.withString(f.type!));
      if (f.type == 'deposit' && f.depositKind != null) {
        whereClauses.add('t.deposit_kind = ?');
        vars.add(d.Variable.withString(f.depositKind!));
      }
      if (f.type == 'withdraw' && f.withdrawKind != null) {
        whereClauses.add('t.withdraw_kind = ?');
        vars.add(d.Variable.withString(f.withdrawKind!));
      }
    }
    if (f.userId != null) {
      whereClauses.add('t.user_id = ?');
      vars.add(d.Variable.withInt(f.userId!));
    }
    if (f.bankId != null) {
      whereClauses.add('t.bank_id = ?');
      vars.add(d.Variable.withInt(f.bankId!));
    }

    final whereSql = whereClauses.isEmpty ? '' : 'WHERE ${whereClauses.join(' AND ')}';
    final sql = '''
SELECT t.*, b.id AS b_id, b.bank_key, b.bank_name, b.account_name, b.account_number, b.created_at AS b_created, b.updated_at AS b_updated,
       u.id AS u_id, u.first_name, u.last_name, u.father_name, u.mobile_number, u.created_at AS u_created, u.updated_at AS u_updated
FROM transactions t
JOIN banks b ON b.id = t.bank_id
LEFT JOIN users u ON u.id = t.user_id
$whereSql
ORDER BY t.created_at DESC, t.id DESC
''';

    return db
        .customSelect(sql, variables: vars, readsFrom: {db.transactions, db.banks, db.users})
        .watch()
        .map((rows) => rows.map((r) {
              final tr = Transaction(
                id: r.read<int>('id'),
                bankId: r.read<int>('bank_id'),
                userId: r.readNullable<int>('user_id'),
                amount: r.read<int>('amount'),
                type: r.read<String>('type'),
                depositKind: r.readNullable<String>('deposit_kind'),
                withdrawKind: r.readNullable<String>('withdraw_kind'),
                note: r.readNullable<String>('note'),
                createdAt: r.read<DateTime>('created_at'),
                updatedAt: r.readNullable<DateTime>('updated_at'),
              );
              final bank = Bank(
                id: r.read<int>('b_id'),
                bankKey: r.read<String>('bank_key'),
                bankName: r.read<String>('bank_name'),
                accountName: r.read<String>('account_name'),
                accountNumber: r.read<String>('account_number'),
                createdAt: r.read<DateTime>('b_created'),
                updatedAt: r.readNullable<DateTime>('b_updated'),
              );
              final uid = r.readNullable<int>('u_id');
              final user = uid == null
                  ? null
                  : User(
                      id: uid,
                      firstName: r.read<String>('first_name'),
                      lastName: r.read<String>('last_name'),
                      fatherName: r.readNullable<String>('father_name'),
                      mobileNumber: r.readNullable<String>('mobile_number'),
                      createdAt: r.read<DateTime>('u_created'),
                      updatedAt: r.readNullable<DateTime>('u_updated'),
                    );
              return TransactionWithJoins(transaction: tr, bank: bank, user: user);
            }).toList());
  }

  Future<int> addTransaction({
    required int bankId,
    int? userId,
    required int amount,
    required String type,
    String? depositKind,
    String? withdrawKind,
    String? note,
    DateTime? createdAt,
  }) async {
    return db.into(db.transactions).insert(TransactionsCompanion.insert(
          bankId: bankId,
          userId: d.Value(userId),
          amount: amount,
          type: type,
          depositKind: d.Value(depositKind),
          withdrawKind: d.Value(withdrawKind),
          note: d.Value(note),
          createdAt: d.Value(createdAt ?? DateTime.now()),
        ));
  }

  Future<void> updateTransaction({
    required int id,
    required int bankId,
    int? userId,
    required int amount,
    required String type,
    String? depositKind,
    String? withdrawKind,
    String? note,
  }) async {
    await (db.update(db.transactions)..where((t) => t.id.equals(id))).write(TransactionsCompanion(
      bankId: d.Value(bankId),
      userId: d.Value(userId),
      amount: d.Value(amount),
      type: d.Value(type),
      depositKind: d.Value(depositKind),
      withdrawKind: d.Value(withdrawKind),
      note: d.Value(note),
      updatedAt: d.Value(DateTime.now()),
    ));
  }

  Future<void> deleteTransaction(int id) async {
    await (db.delete(db.transactions)..where((t) => t.id.equals(id))).go();
  }
}


