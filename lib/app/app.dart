import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

import '../di/locator.dart';
import '../presentation/cubits/auth_cubit.dart';
import '../presentation/cubits/settings_cubit.dart';
import '../presentation/router/app_router.dart';
import 'theme/app_theme.dart';

class FamilyAccountingApp extends StatefulWidget {
  const FamilyAccountingApp({super.key});

  @override
  State<FamilyAccountingApp> createState() => _FamilyAccountingAppState();
}

class _FamilyAccountingAppState extends State<FamilyAccountingApp> {
  late final GoRouter _router = createAppRouter();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => SettingsCubit()..load()),
        BlocProvider(create: (_) => AuthCubit(locator())..check()),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return MaterialApp.router(
            title: tr('app_title'),
            debugShowCheckedModeBanner: false,
            routerConfig: _router,
            themeMode: state.themeMode,
            theme: AppTheme.light(scale: state.fontScale),
            darkTheme: AppTheme.dark(scale: state.fontScale),
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            builder: (context, child) {
              final isFa = context.locale.languageCode == 'fa';
              return Directionality(
                textDirection: isFa ? TextDirection.rtl : TextDirection.ltr,
                child: child ?? const SizedBox(),
              );
            },
          );
        },
      ),
    );
  }
}
