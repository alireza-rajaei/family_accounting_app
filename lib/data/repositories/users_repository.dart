import 'package:drift/drift.dart' as d;

import '../local/db/app_database.dart';

class UsersRepository {
  final AppDatabase db;
  UsersRepository(this.db);

  Stream<List<User>> watchUsers(String query) {
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
    return sel.watch();
  }

  Future<int> addUser({
    required String firstName,
    required String lastName,
    String? fatherName,
    String? mobileNumber,
  }) async {
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

  Future<void> deleteUser(int id) async {
    await (db.delete(db.users)..where((t) => t.id.equals(id))).go();
  }

  Future<void> deleteUserCascade(int userId) async {
    await db.transaction(() async {
      // Gather loan ids for this user
      final loanIdsRows = await db
          .customSelect(
            'SELECT id FROM loans WHERE user_id = ?',
            variables: [d.Variable.withInt(userId)],
            readsFrom: {db.loans},
          )
          .get();
      final loanIds = loanIdsRows.map((r) => r.read<int>('id')).toList();

      if (loanIds.isNotEmpty) {
        // Gather transaction ids linked via loan_payments before deleting them
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

        // Delete loan_payments for user's loans
        await db.customStatement(
          'DELETE FROM loan_payments WHERE loan_id IN (${List.filled(loanIds.length, '?').join(',')})',
          loanIds,
        );

        // Delete transactions created for those loan payments (if any)
        if (txIdsFromPayments.isNotEmpty) {
          await db.customStatement(
            'DELETE FROM transactions WHERE id IN (${List.filled(txIdsFromPayments.length, '?').join(',')})',
            txIdsFromPayments,
          );
        }

        // Delete user's loans
        await db.customStatement(
          'DELETE FROM loans WHERE id IN (${List.filled(loanIds.length, '?').join(',')})',
          loanIds,
        );
      }

      // Delete transactions directly associated with the user
      await db.customStatement('DELETE FROM transactions WHERE user_id = ?', [
        userId,
      ]);

      // Finally, delete the user
      await (db.delete(db.users)..where((t) => t.id.equals(userId))).go();
    });
  }

  Future<int> getUserBalance(int userId) async {
    const sql = '''
SELECT COALESCE(SUM(t.amount), 0) AS balance
FROM transactions t
WHERE t.user_id = ?
''';
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
