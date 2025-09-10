import 'package:flutter/material.dart';
import 'app/app.dart';
import 'di/locator.dart';
import 'package:easy_localization/easy_localization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();
  await EasyLocalization.ensureInitialized();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('fa'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('fa'),
      startLocale: const Locale('fa'),
      saveLocale: true,
      child: const FamilyAccountingApp(),
    ),
  );
}
