import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../pages/banks_page.dart';
import '../pages/home_page.dart';
import '../pages/loans_page.dart';
import '../pages/login_page.dart';
import '../pages/shell.dart';
import '../pages/transactions_page.dart';
import '../pages/users_page.dart';

GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => ShellScaffold(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/transactions',
            name: 'transactions',
            builder: (context, state) => const TransactionsPage(),
          ),
          GoRoute(
            path: '/loans',
            name: 'loans',
            builder: (context, state) => const LoansPage(),
          ),
          GoRoute(
            path: '/users',
            name: 'users',
            builder: (context, state) => const UsersPage(),
          ),
          GoRoute(
            path: '/banks',
            name: 'banks',
            builder: (context, state) => const BanksPage(),
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      // TODO: Replace with real auth check later
      final isLoggingIn = state.matchedLocation == '/login';
      final bool loggedIn = true;
      if (!loggedIn && !isLoggingIn) return '/login';
      if (loggedIn && isLoggingIn) return '/';
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('خطا: ${state.error}')),
    ),
  );
}


