import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../cubits/auth_cubit.dart';
import '../cubits/settings_cubit.dart';
import '../../app/theme/app_icons.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  bool _obscurePassword = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthState auth) async {
    if (_submitting || !_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    FocusScope.of(context).unfocus();

    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final authCubit = context.read<AuthCubit>();

    final ok = auth is AuthNeedsSetup
        ? await authCubit.setupAndLogin(username, password)
        : await authCubit.login(username, password);

    if (!mounted) return;

    if (ok) {
      context.read<SettingsCubit>().setUsername(username);
      context.read<SettingsCubit>().setLastLogin(DateTime.now());
      context.go('/');
    } else {
      setState(() => _submitting = false);
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Row(
            children: [
              const Icon(AppIcons.error, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(tr('login.invalid'))),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      body: Stack(
        children: [
          const _LoginBackdrop(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 24 + bottomInset),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: BlocBuilder<AuthCubit, AuthState>(
                        builder: (context, auth) {
                          final isSetup = auth is AuthNeedsSetup;
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _BrandHeader(isSetup: isSetup),
                              const SizedBox(height: 28),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color:
                                        (isDark
                                                ? AppColors.darkOutline
                                                : AppColors.lightOutline)
                                            .withValues(alpha: 0.9),
                                  ),
                                  boxShadow: isDark
                                      ? null
                                      : [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.06,
                                            ),
                                            blurRadius: 28,
                                            offset: const Offset(0, 12),
                                          ),
                                        ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    22,
                                    20,
                                    22,
                                  ),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          isSetup
                                              ? tr('login.setup_and_login')
                                              : tr('login.title'),
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          isSetup
                                              ? tr('login.setup_subtitle')
                                              : tr('login.subtitle'),
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.6),
                                              ),
                                        ),
                                        const SizedBox(height: 22),
                                        TextFormField(
                                          controller: _usernameController,
                                          textInputAction: TextInputAction.next,
                                          autofillHints: const [
                                            AutofillHints.username,
                                          ],
                                          onFieldSubmitted: (_) =>
                                              _passwordFocus.requestFocus(),
                                          decoration: InputDecoration(
                                            labelText: tr('login.username'),
                                            prefixIcon: const Icon(
                                              AppIcons.user,
                                            ),
                                          ),
                                          validator: (v) =>
                                              (v == null || v.trim().isEmpty)
                                              ? tr('login.required')
                                              : null,
                                        ),
                                        const SizedBox(height: 14),
                                        TextFormField(
                                          controller: _passwordController,
                                          focusNode: _passwordFocus,
                                          obscureText: _obscurePassword,
                                          textInputAction: TextInputAction.done,
                                          autofillHints: const [
                                            AutofillHints.password,
                                          ],
                                          onFieldSubmitted: (_) =>
                                              _submit(auth),
                                          decoration: InputDecoration(
                                            labelText: tr('login.password'),
                                            prefixIcon: const Icon(
                                              AppIcons.lock,
                                            ),
                                            suffixIcon: IconButton(
                                              tooltip: _obscurePassword
                                                  ? tr('login.show_password')
                                                  : tr('login.hide_password'),
                                              onPressed: () => setState(
                                                () => _obscurePassword =
                                                    !_obscurePassword,
                                              ),
                                              icon: Icon(
                                                _obscurePassword
                                                    ? AppIcons.eye
                                                    : AppIcons.eyeSlash,
                                              ),
                                            ),
                                          ),
                                          validator: (v) =>
                                              (v == null || v.isEmpty)
                                              ? tr('login.required')
                                              : null,
                                        ),
                                        const SizedBox(height: 22),
                                        FilledButton(
                                          onPressed: _submitting
                                              ? null
                                              : () => _submit(auth),
                                          child: _submitting
                                              ? const SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2.4,
                                                        color: Colors.white,
                                                      ),
                                                )
                                              : Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      isSetup
                                                          ? AppIcons.userAdd
                                                          : AppIcons.login,
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      isSetup
                                                          ? tr(
                                                              'login.setup_and_login',
                                                            )
                                                          : tr('login.submit'),
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                tr('app_title'),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.45,
                                  ),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginBackdrop extends StatelessWidget {
  const _LoginBackdrop();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: isDark
              ? [
                  AppColors.darkBackground,
                  AppColors.primary.withValues(alpha: 0.22),
                  AppColors.darkBackground,
                ]
              : [
                  const Color(0xFFEFF4FF),
                  AppColors.primary.withValues(alpha: 0.12),
                  AppColors.secondary.withValues(alpha: 0.10),
                  AppColors.lightBackground,
                ],
          stops: isDark ? const [0.0, 0.45, 1.0] : const [0.0, 0.35, 0.7, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: _GlowOrb(
              size: 180,
              color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.16),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -50,
            child: _GlowOrb(
              size: 160,
              color: AppColors.secondary.withValues(
                alpha: isDark ? 0.14 : 0.14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.isSetup});

  final bool isSetup;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          width: 108,
          height: 108,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      AppColors.primary.withValues(alpha: 0.45),
                      AppColors.secondary.withValues(alpha: 0.25),
                    ]
                  : [
                      AppColors.primary,
                      AppColors.secondary.withValues(alpha: 0.9),
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(
                  alpha: isDark ? 0.25 : 0.28,
                ),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: ColoredBox(
              color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.92),
              child: Image.asset(
                'assets/icons/app_icon.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          tr('login.welcome'),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isSetup ? tr('login.setup_subtitle') : tr('login.subtitle'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
