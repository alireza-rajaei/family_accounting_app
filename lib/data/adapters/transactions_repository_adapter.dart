import '../../domain/repositories/i_transactions_repository.dart';
import '../../domain/entities/transaction.dart';
import '../local/db/app_database.dart';
import '../mappers/domain_mappers.dart';
import 'package:drift/drift.dart' as d;

class TransactionsRepositoryAdapter implements ITransactionsRepository {
  final AppDatabase db;
  TransactionsRepositoryAdapter(this.db);

  @override
  Stream<List<TransactionAggregate>> watchTransactions(
    TransactionsFilterEntity f,
  ) {
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
    }
    if (f.userId != null) {
      whereClauses.add('t.user_id = ?');
      vars.add(d.Variable.withInt(f.userId!));
    }
    if (f.bankId != null) {
      whereClauses.add('t.bank_id = ?');
      vars.add(d.Variable.withInt(f.bankId!));
    }

    final whereSql = whereClauses.isEmpty
        ? ''
        : 'WHERE ${whereClauses.join(' AND ')}';
    final sql =
        'SELECT t.*, b.id AS b_id, b.bank_key, b.account_name, b.account_number, b.created_at AS b_created, b.updated_at AS b_updated, u.id AS u_id, u.first_name, u.last_name, u.father_name, u.mobile_number, u.created_at AS u_created, u.updated_at AS u_updated FROM transactions t JOIN banks b ON b.id = t.bank_id LEFT JOIN users u ON u.id = t.user_id $whereSql ORDER BY t.created_at DESC, t.id DESC';
    return db
        .customSelect(
          sql,
          variables: vars,
          readsFrom: {db.transactions, db.banks, db.users},
        )
        .watch()
        .map(
          (rows) => rows.map((r) {
            final tr = Transaction(
              id: r.read<int>('id'),
              bankId: r.read<int>('bank_id'),
              userId: r.readNullable<int>('user_id'),
              loanId: r.readNullable<int>('loan_id'),
              amount: r.read<int>('amount'),
              type: r.read<String>('type'),
              note: r.readNullable<String>('note'),
              createdAt: r.read<DateTime>('created_at'),
              updatedAt: r.readNullable<DateTime>('updated_at'),
            ).toEntity();
            final bank = Bank(
              id: r.read<int>('b_id'),
              bankKey: r.read<String>('bank_key'),
              accountName: r.read<String>('account_name'),
              accountNumber: r.read<String>('account_number'),
              createdAt: r.read<DateTime>('b_created'),
              updatedAt: r.readNullable<DateTime>('b_updated'),
            ).toEntity();
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
                  ).toEntity();
            return TransactionAggregate(
              transaction: tr,
              bank: bank,
              user: user,
            );
          }).toList(),
        );
  }

  @override
  Future<List<TransactionAggregate>> fetchTransactions(
    TransactionsFilterEntity f, {
    int limit = 50,
    int offset = 0,
  }) async {
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
    }
    if (f.userId != null) {
      whereClauses.add('t.user_id = ?');
      vars.add(d.Variable.withInt(f.userId!));
    }
    if (f.bankId != null) {
      whereClauses.add('t.bank_id = ?');
      vars.add(d.Variable.withInt(f.bankId!));
    }

    final whereSql = whereClauses.isEmpty
        ? ''
        : 'WHERE ${whereClauses.join(' AND ')}';
    final sql =
        'SELECT t.*, b.id AS b_id, b.bank_key, b.account_name, b.account_number, b.created_at AS b_created, b.updated_at AS b_updated, u.id AS u_id, u.first_name, u.last_name, u.father_name, u.mobile_number, u.created_at AS u_created, u.updated_at AS u_updated FROM transactions t JOIN banks b ON b.id = t.bank_id LEFT JOIN users u ON u.id = t.user_id $whereSql ORDER BY t.created_at DESC, t.id DESC LIMIT ? OFFSET ?';

    final rows = await db
        .customSelect(
          sql,
          variables: [
            ...vars,
            d.Variable.withInt(limit),
            d.Variable.withInt(offset),
          ],
          readsFrom: {db.transactions, db.banks, db.users},
        )
        .get();

    return rows.map((r) {
      final tr = Transaction(
        id: r.read<int>('id'),
        bankId: r.read<int>('bank_id'),
        userId: r.readNullable<int>('user_id'),
        loanId: r.readNullable<int>('loan_id'),
        amount: r.read<int>('amount'),
        type: r.read<String>('type'),
        note: r.readNullable<String>('note'),
        createdAt: r.read<DateTime>('created_at'),
        updatedAt: r.readNullable<DateTime>('updated_at'),
      ).toEntity();
      final bank = Bank(
        id: r.read<int>('b_id'),
        bankKey: r.read<String>('bank_key'),
        accountName: r.read<String>('account_name'),
        accountNumber: r.read<String>('account_number'),
        createdAt: r.read<DateTime>('b_created'),
        updatedAt: r.readNullable<DateTime>('b_updated'),
      ).toEntity();
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
            ).toEntity();
      return TransactionAggregate(transaction: tr, bank: bank, user: user);
    }).toList();
  }

  @override
  Future<int> addTransaction({
    required int bankId,
    int? userId,
    required int amount,
    required String type,
    String? note,
    DateTime? createdAt,
  }) {
    return db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            bankId: bankId,
            userId: d.Value(userId),
            amount: amount,
            type: type,
            note: d.Value(note),
            createdAt: d.Value(createdAt ?? DateTime.now()),
          ),
        );
  }

  @override
  Future<void> updateTransaction({
    required int id,
    required int bankId,
    int? userId,
    required int amount,
    required String type,
    String? note,
  }) async {
    await (db.update(db.transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        bankId: d.Value(bankId),
        userId: d.Value(userId),
        amount: d.Value(amount),
        type: d.Value(type),
        note: d.Value(note),
        updatedAt: d.Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> deleteTransaction(int id) async {
    await (db.delete(db.transactions)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> transferBetweenBanks({
    required int fromBankId,
    required int toBankId,
    required int amount,
    String? note,
  }) async {
    await db.transaction(() async {
      final now = DateTime.now();
      await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              bankId: fromBankId,
              amount: -amount,
              type: 'جابجایی بین بانکی',
              note: d.Value(note),
              createdAt: d.Value(now),
            ),
          );
      await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              bankId: toBankId,
              amount: amount,
              type: 'جابجایی بین بانکی',
              note: d.Value(note),
              createdAt: d.Value(now),
            ),
          );
    });
  }

  @override
  Stream<List<(String bankKey, int deposit, int withdraw)>>
  watchBankFlowSums() {
    const sql =
        'SELECT b.bank_key, COALESCE(SUM(CASE WHEN t.amount > 0 THEN t.amount END), 0) AS deposit, COALESCE(SUM(CASE WHEN t.amount < 0 THEN -t.amount END), 0) AS withdraw FROM banks b LEFT JOIN transactions t ON t.bank_id = b.id GROUP BY b.bank_key ORDER BY b.bank_key';
    return db
        .customSelect(sql, readsFrom: {db.transactions, db.banks})
        .watch()
        .map(
          (rows) => rows
              .map(
                (r) => (
                  r.read<String>('bank_key'),
                  r.read<int>('deposit'),
                  r.read<int>('withdraw'),
                ),
              )
              .toList(),
        );
  }
}
