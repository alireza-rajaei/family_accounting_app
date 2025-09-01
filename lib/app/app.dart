import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../di/locator.dart';
import '../presentation/cubits/auth_cubit.dart';
import '../presentation/cubits/settings_cubit.dart';
import '../presentation/router/app_router.dart';

class FamilyAccountingApp extends StatelessWidget {
  const FamilyAccountingApp({super.key});

  @override
  Widget build(BuildContext context) {
    final GoRouter router = createAppRouter();

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => SettingsCubit()..load()),
        BlocProvider(create: (_) => AuthCubit(locator())..check()),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return MaterialApp.router(
            title: 'حسابداری خانوادگی',
            debugShowCheckedModeBanner: false,
            routerConfig: router,
            themeMode: state.themeMode,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              textTheme: ThemeData.light()
                  .textTheme
                  .apply(fontSizeFactor: state.fontScale),
              fontFamily: 'Vazirmatn',
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              textTheme: ThemeData.dark()
                  .textTheme
                  .apply(fontSizeFactor: state.fontScale),
              fontFamily: 'Vazirmatn',
            ),
            locale: const Locale('fa'),
            supportedLocales: const [Locale('fa')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              return Directionality(textDirection: TextDirection.rtl, child: child ?? const SizedBox());
            },
          );
        },
      ),
    );
  }
}


