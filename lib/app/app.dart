import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

import '../di/locator.dart';
import '../presentation/cubits/auth_cubit.dart';
import '../presentation/cubits/settings_cubit.dart';
import '../presentation/router/app_router.dart';
import 'theme/app_theme.dart';

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
            title: tr('app_title'),
            debugShowCheckedModeBanner: false,
            routerConfig: router,
            themeMode: state.themeMode,
            theme: AppTheme.light(scale: state.fontScale),
            darkTheme: AppTheme.dark(scale: state.fontScale),
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            builder: (context, child) {
              return Directionality(textDirection: TextDirection.rtl, child: child ?? const SizedBox());
            },
          );
        },
      ),
    );
  }
}


