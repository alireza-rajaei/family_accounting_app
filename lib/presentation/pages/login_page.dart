import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

import '../cubits/auth_cubit.dart';
import '../cubits/settings_cubit.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('login.title'))),
      body: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: MediaQuery.sizeOf(context).height * 0.1,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Image.asset(
                    'assets/icons/app_icon.png',
                    width: 200,
                    height: 200,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(labelText: tr('login.username')),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? tr('login.invalid') : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: tr('login.password')),
                  obscureText: true,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? tr('login.password') : null,
                ),
                const SizedBox(height: 16),
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, auth) {
                    return SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            final username = _usernameController.text.trim();
                            final password = _passwordController.text;
                            final authCubit = context.read<AuthCubit>();
                            bool ok = false;
                            if (auth is AuthNeedsSetup) {
                              ok = await authCubit.setupAndLogin(
                                username,
                                password,
                              );
                            } else {
                              ok = await authCubit.login(username, password);
                            }
                            if (ok && context.mounted) {
                              context.read<SettingsCubit>().setUsername(
                                username,
                              );
                              context.read<SettingsCubit>().setLastLogin(
                                DateTime.now(),
                              );
                              context.go('/');
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(tr('login.invalid'))),
                                );
                              }
                            }
                          }
                        },
                        child: Text(
                          auth is AuthNeedsSetup
                              ? tr('login.setup_and_login')
                              : tr('login.submit'),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
