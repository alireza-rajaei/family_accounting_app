// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:family_accounting_app/app/app.dart';
import 'package:family_accounting_app/di/locator.dart';
import 'package:family_accounting_app/data/local/db/app_database.dart';
import 'package:family_accounting_app/data/repositories/auth_repository.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});

    // Minimal DI for the app under test
    if (!locator.isRegistered<AppDatabase>()) {
      locator.registerLazySingleton<AppDatabase>(() => AppDatabase.test());
    }
    if (!locator.isRegistered<AuthRepository>()) {
      locator.registerLazySingleton<AuthRepository>(
        () => AuthRepository(locator<AppDatabase>()),
      );
    }

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('fa')],
        path: 'assets/translations',
        fallbackLocale: const Locale('fa'),
        child: const FamilyAccountingApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsNothing); // using MaterialApp.router
  });
}
