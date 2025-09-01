import 'package:flutter/material.dart';
import 'app/app.dart';
import 'di/locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();
  runApp(const FamilyAccountingApp());
}
