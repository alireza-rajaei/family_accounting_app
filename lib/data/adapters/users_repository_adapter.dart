import '../../domain/repositories/i_users_repository.dart';
import '../../domain/entities/user.dart';
import '../local/db/app_database.dart';
import '../mappers/domain_mappers.dart';
import 'package:drift/drift.dart' as d;

class UsersRepositoryAdapter implements IUsersRepository {
  final AppDatabase db;
  UsersRepositoryAdapter(this.db);

  @override
  Stream<List<UserEntity>> watchUsers(String query) {
    final sel = db.select(db.users);
    final q = query.trim();
    if (q.isNotEmpty) {
      final like = '%$q%';
      sel.where(
        (u) =>
            u.firstName.like(like) |
            u.lastName.like(like) |
            u.mobileNumber.like(like),
      );
    }
    sel.orderBy([
      (u) => d.OrderingTerm(expression: u.firstName),
      (u) => d.OrderingTerm(expression: u.lastName),
    ]);
    return sel.watch().map((rows) => rows.map((u) => u.toEntity()).toList());
  }

  @override
  Future<int> addUser({
    required String firstName,
    required String lastName,
    String? fatherName,
    String? mobileNumber,
  }) {
    return db
        .into(db.users)
        .insert(
          UsersCompanion.insert(
            firstName: firstName,
            lastName: lastName,
            fatherName: d.Value(fatherName),
            mobileNumber: d.Value(mobileNumber),
          ),
        );
  }

  @override
  Future<void> updateUser({
    required int id,
    required String firstName,
    required String lastName,
    String? fatherName,
    String? mobileNumber,
  }) async {
    await (db.update(db.users)..where((t) => t.id.equals(id))).write(
      UsersCompanion(
        firstName: d.Value(firstName),
        lastName: d.Value(lastName),
        fatherName: d.Value(fatherName),
        mobileNumber: d.Value(mobileNumber),
        updatedAt: d.Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> deleteUserCascade(int userId) async {
    await db.transaction(() async {
      final loanIdsRows = await db
          .customSelect(
            'SELECT id FROM loans WHERE user_id = ?',
            variables: [d.Variable.withInt(userId)],
            readsFrom: {db.loans},
          )
          .get();
      final loanIds = loanIdsRows.map((r) => r.read<int>('id')).toList();

      if (loanIds.isNotEmpty) {
        final txIdRows = await db
            .customSelect(
              'SELECT transaction_id FROM loan_payments WHERE loan_id IN (${List.filled(loanIds.length, '?').join(',')})',
              variables: loanIds.map((e) => d.Variable.withInt(e)).toList(),
              readsFrom: {db.loanPayments},
            )
            .get();
        final txIdsFromPayments = txIdRows
            .map((r) => r.read<int>('transaction_id'))
            .toList();

        await db.customStatement(
          'DELETE FROM loan_payments WHERE loan_id IN (${List.filled(loanIds.length, '?').join(',')})',
          loanIds,
        );

        if (txIdsFromPayments.isNotEmpty) {
          await db.customStatement(
            'DELETE FROM transactions WHERE id IN (${List.filled(txIdsFromPayments.length, '?').join(',')})',
            txIdsFromPayments,
          );
        }

        await db.customStatement(
          'DELETE FROM loans WHERE id IN (${List.filled(loanIds.length, '?').join(',')})',
          loanIds,
        );
      }

      await db.customStatement('DELETE FROM transactions WHERE user_id = ?', [
        userId,
      ]);

      await (db.delete(db.users)..where((t) => t.id.equals(userId))).go();
    });
  }

  @override
  Future<int> getUserBalance(int userId) async {
    const sql =
        'SELECT COALESCE(SUM(t.amount), 0) AS balance '
        'FROM transactions t '
        'WHERE t.user_id = ? AND t.loan_id IS NULL';
    final row = await db
        .customSelect(
          sql,
          variables: [d.Variable.withInt(userId)],
          readsFrom: {db.transactions},
        )
        .getSingle();
    return row.read<int>('balance');
  }
}
