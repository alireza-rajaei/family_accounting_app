import 'package:flutter_test/flutter_test.dart';
import 'package:family_accounting_app/data/local/db/app_database.dart';

void main() {
  test('can create in-memory db and insert a user', () async {
    final db = AppDatabase.test();
    final id = await db
        .into(db.users)
        .insert(UsersCompanion.insert(firstName: 'Ali', lastName: 'Reza'));
    final u = await (db.select(
      db.users,
    )..where((t) => t.id.equals(id))).getSingle();
    expect(u.firstName, 'Ali');
    await db.close();
  });
}
