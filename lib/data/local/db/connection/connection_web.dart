import 'package:drift/drift.dart' show QueryExecutor;
import 'package:drift/web.dart';

QueryExecutor openConnection() {
  return WebDatabase('family_accounting');
}
