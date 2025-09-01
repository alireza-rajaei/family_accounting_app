import 'package:drift/drift.dart' as d;

import '../local/db/app_database.dart';

class UsersRepository {
  final AppDatabase db;
  UsersRepository(this.db);

  Stream<List<User>> watchUsers({String query = ''}) {
    final q =
        (db.select(db.users)..orderBy([
              (t) => d.OrderingTerm(
                expression: t.lastName,
                mode: d.OrderingMode.asc,
              ),
              (t) => d.OrderingTerm(
                expression: t.firstName,
                mode: d.OrderingMode.asc,
              ),
            ]))
            .watch();

    if (query.trim().isEmpty) return q;
    final normalized = query.trim();
    final pattern = '%$normalized%';
    return (db.select(db.users)
          ..where((t) => t.firstName.like(pattern) | t.lastName.like(pattern))
          ..orderBy([
            (t) => d.OrderingTerm(
              expression: t.lastName,
              mode: d.OrderingMode.asc,
            ),
            (t) => d.OrderingTerm(
              expression: t.firstName,
              mode: d.OrderingMode.asc,
            ),
          ]))
        .watch();
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
WHERE t.user_id = ? AND t.type = 'deposit' AND t.deposit_kind = 'deposit_to_user'
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
