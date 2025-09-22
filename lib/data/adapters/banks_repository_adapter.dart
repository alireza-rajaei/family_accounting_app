import '../../domain/repositories/i_banks_repository.dart';
import '../../domain/entities/bank.dart';
import '../local/db/app_database.dart';
import '../mappers/domain_mappers.dart';
import 'package:drift/drift.dart' as d;

class BanksRepositoryAdapter implements IBanksRepository {
  final AppDatabase db;
  BanksRepositoryAdapter(this.db);

  @override
  Stream<List<BankWithBalanceEntity>> watchBanksWithBalance({
    String query = '',
  }) {
    final like = '%${query.trim()}%';
    const sql = '''
SELECT b.id, b.bank_key, b.account_name, b.account_number, b.created_at, b.updated_at,
       COALESCE(SUM(CASE WHEN t.amount IS NULL THEN 0 ELSE t.amount END), 0) AS balance
FROM banks b
LEFT JOIN transactions t ON t.bank_id = b.id
WHERE (? = '' OR b.account_name LIKE ? OR b.account_number LIKE ?)
GROUP BY b.id
ORDER BY b.account_name ASC
''';
    return db
        .customSelect(
          sql,
          variables: [
            d.Variable.withString(query.trim()),
            d.Variable.withString(like),
            d.Variable.withString(like),
          ],
          readsFrom: {db.banks, db.transactions},
        )
        .watch()
        .map(
          (rows) => rows
              .map(
                (r) => BankWithBalanceEntity(
                  bank: Bank(
                    id: r.read<int>('id'),
                    bankKey: r.read<String>('bank_key'),
                    accountName: r.read<String>('account_name'),
                    accountNumber: r.read<String>('account_number'),
                    createdAt: r.read<DateTime>('created_at'),
                    updatedAt: r.readNullable<DateTime>('updated_at'),
                  ).toEntity(),
                  balance: r.read<int>('balance'),
                ),
              )
              .toList(),
        );
  }

  @override
  Future<int> addBank({
    required String bankKey,
    required String accountName,
    required String accountNumber,
  }) {
    return db
        .into(db.banks)
        .insert(
          BanksCompanion.insert(
            bankKey: bankKey,
            accountName: accountName,
            accountNumber: accountNumber,
          ),
        );
  }

  @override
  Future<void> updateBank({
    required int id,
    required String bankKey,
    required String accountName,
    required String accountNumber,
  }) async {
    await (db.update(db.banks)..where((tbl) => tbl.id.equals(id))).write(
      BanksCompanion(
        bankKey: d.Value(bankKey),
        accountName: d.Value(accountName),
        accountNumber: d.Value(accountNumber),
        updatedAt: d.Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> deleteBank(int id) async {
    await (db.delete(db.banks)..where((tbl) => tbl.id.equals(id))).go();
  }
}
