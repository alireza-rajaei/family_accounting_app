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
