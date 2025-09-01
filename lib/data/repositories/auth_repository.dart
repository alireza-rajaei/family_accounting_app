import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' as d;

import '../local/db/app_database.dart';

class AuthRepository {
  final AppDatabase db;
  AuthRepository(this.db);

  String _hash(String input) => sha256.convert(utf8.encode(input)).toString();

  Future<bool> hasAnyAdmin() async {
    final countExp = d.countAll();
    final query = await (db.selectOnly(db.admins)..addColumns([countExp])).getSingle();
    return (query.read(countExp) ?? 0) > 0;
  }

  Future<void> createInitialAdmin(String username, String password) async {
    await db.into(db.admins).insert(AdminsCompanion.insert(
      username: username,
      passwordHash: _hash(password),
    ));
  }

  Future<bool> login(String username, String password) async {
    final hashed = _hash(password);
    final user = await (db.select(db.admins)
          ..where((tbl) => tbl.username.equals(username) & tbl.passwordHash.equals(hashed)))
        .getSingleOrNull();
    if (user != null) {
      await (db.update(db.admins)..where((tbl) => tbl.id.equals(user.id))).write(
        AdminsCompanion(lastLoginAt: d.Value(DateTime.now())),
      );
      return true;
    }
    return false;
  }
}


