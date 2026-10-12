import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../cubits/settings_cubit.dart';
import '../../app/theme/app_colors.dart';
import '../../di/locator.dart';
import '../../domain/repositories/i_backup_repository.dart';

class ShellScaffold extends StatefulWidget {
  final Widget child;
  const ShellScaffold({super.key, required this.child});

  @override
  State<ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends State<ShellScaffold>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int _currentIndexByLocation(String location) {
    if (location.startsWith('/transactions')) return 1;
    if (location.startsWith('/loans')) return 2;
    if (location.startsWith('/users')) return 3;
    if (location.startsWith('/banks')) return 4;
    return 0;
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/transactions');
        break;
      case 2:
        context.go('/loans');
        break;
      case 3:
        context.go('/users');
        break;
      case 4:
        context.go('/banks');
        break;
    }
  }

  String _titleForIndex(int index) {
    switch (index) {
      case 1:
        return tr('tabs.transactions');
      case 2:
        return tr('tabs.loans');
      case 3:
        return tr('tabs.users');
      case 4:
        return tr('tabs.banks');
      default:
        return tr('app_title');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);
    final location = GoRouterState.of(context).uri.toString();
    final index = _currentIndexByLocation(location);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titleForIndex(index),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0.5,
      ),
      drawer: const _AppDrawer(),
      body: PageStorage(bucket: PageStorageBucket(), child: widget.child),
      bottomNavigationBar: _AppBottomNav(
        selectedIndex: index,
        onDestinationSelected: _onItemTapped,
      ),
    );
  }
}

class _AppBottomNav extends StatelessWidget {
  const _AppBottomNav({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, 8 + (bottomInset > 0 ? 0 : 4)),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: (isDark ? AppColors.darkOutline : AppColors.lightOutline)
                  .withValues(alpha: 0.95),
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home_rounded),
                  label: tr('tabs.home'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.compare_arrows_outlined),
                  selectedIcon: const Icon(Icons.compare_arrows_rounded),
                  label: tr('tabs.transactions'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.request_quote_outlined),
                  selectedIcon: const Icon(Icons.request_quote_rounded),
                  label: tr('tabs.loans'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.people_alt_outlined),
                  selectedIcon: const Icon(Icons.people_alt_rounded),
                  label: tr('tabs.users'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.account_balance_outlined),
                  selectedIcon: const Icon(Icons.account_balance_rounded),
                  label: tr('tabs.banks'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppDrawer extends StatefulWidget {
  const _AppDrawer();
  @override
  State<_AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<_AppDrawer> {
  String? _version;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _version = '${info.version}');
      }
    } catch (_) {
      if (mounted) setState(() => _version = null);
    }
  }

  Widget _drawerTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: theme.colorScheme.primary, size: 20),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      trailing: trailing,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>().state;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.horizontal(
          end: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: isDark
                      ? [
                          AppColors.primary.withValues(alpha: 0.35),
                          AppColors.secondary.withValues(alpha: 0.18),
                        ]
                      : [
                          AppColors.primary,
                          AppColors.secondary.withValues(alpha: 0.9),
                        ],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    settings.username,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    settings.lastLoginAt != null
                        ? tr(
                            'drawer.last_login',
                            namedArgs: {
                              'time': _formatLastLogin(
                                context,
                                settings.lastLoginAt!,
                              ),
                            },
                          )
                        : tr(
                            'drawer.last_login',
                            namedArgs: {'time': '-'},
                          ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  _drawerTile(
                    context: context,
                    icon: Icons.person_outline_rounded,
                    title: tr('drawer.change_username'),
                    onTap: () async {
                      final controller = TextEditingController(
                        text: settings.username,
                      );
                      final result = await showDialog<String>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(tr('login.username')),
                          content: TextField(controller: controller),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(tr('common.cancel')),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(
                                context,
                                controller.text.trim(),
                              ),
                              child: Text(tr('common.ok')),
                            ),
                          ],
                        ),
                      );
                      if (result != null && result.isNotEmpty) {
                        context.read<SettingsCubit>().setUsername(result);
                      }
                    },
                  ),
                  SwitchListTile(
                    secondary: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.dark_mode_outlined,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      tr('drawer.theme'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    value: settings.themeMode == ThemeMode.dark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    onChanged: (v) => context
                        .read<SettingsCubit>()
                        .setThemeMode(v ? ThemeMode.dark : ThemeMode.light),
                  ),
                  _drawerTile(
                    context: context,
                    icon: Icons.language_rounded,
                    title: tr('drawer.language'),
                    onTap: () async {
                      final selected = await showDialog<Locale>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(tr('drawer.language')),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Text('🇮🇷'),
                                title: Text(tr('lang.fa')),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onTap: () =>
                                    Navigator.pop(context, const Locale('fa')),
                              ),
                              ListTile(
                                leading: const Text('🇺🇸'),
                                title: Text(tr('lang.en')),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onTap: () =>
                                    Navigator.pop(context, const Locale('en')),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(tr('common.cancel')),
                            ),
                          ],
                        ),
                      );
                      if (selected != null) {
                        await context.setLocale(selected);
                      }
                    },
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                    child: Text(
                      tr('drawer.backup'),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.45,
                        ),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _drawerTile(
                    context: context,
                    icon: Icons.backup_outlined,
                    title: tr('drawer.backup'),
                    onTap: () => _doBackup(context),
                  ),
                  _drawerTile(
                    context: context,
                    icon: Icons.restore_outlined,
                    title: tr('drawer.restore'),
                    onTap: () => _doRestore(context),
                  ),
                  _drawerTile(
                    context: context,
                    icon: Icons.info_outline_rounded,
                    title: tr('drawer.about'),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(tr('about.title')),
                          content: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr('about.body'),
                                  textAlign: TextAlign.start,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  tr('about.lead'),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.45),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      tr('about.email_label'),
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    InkWell(
                                      onTap: () async {
                                        final uri = Uri(
                                          scheme: 'mailto',
                                          path: 'arajaei8@gmail.com',
                                          queryParameters: const {
                                            'subject':
                                                'Feedback - Family Accounting App',
                                          },
                                        );
                                        final launched = await launchUrl(
                                          uri,
                                          mode: LaunchMode.externalApplication,
                                        );
                                        if (!launched) {
                                          await Clipboard.setData(
                                            const ClipboardData(
                                              text: 'arajaei8@gmail.com',
                                            ),
                                          );
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  tr(
                                                    'about.email_copy_fallback',
                                                  ),
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      child: Text(
                                        'arajaei8@gmail.com',
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(tr('common.ok')),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text(
                tr('drawer.version', args: [_version ?? '-']),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatJalaliFull(DateTime dt) {
  final j = dt.toJalali();
  final w = j.formatter.wN;
  final d = j.day.toString();
  final m = j.formatter.mN;
  final y = (j.year % 1000).toString();
  return '$w $d $m $y';
}

String _formatLastLogin(BuildContext context, DateTime dt) {
  if (context.locale.languageCode == 'fa') {
    return _formatJalaliFull(dt);
  }
  return DateFormat('EEE, MMM d, yyyy').format(dt);
}

class _FontScaleDialog extends StatefulWidget {
  final double current;
  const _FontScaleDialog({required this.current});
  @override
  State<_FontScaleDialog> createState() => _FontScaleDialogState();
}

class _FontScaleDialogState extends State<_FontScaleDialog> {
  late double value = widget.current;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('اندازه فونت'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Slider(
              min: 0.8,
              max: 1.4,
              divisions: 12,
              value: value,
              label: 'x${value.toStringAsFixed(2)}',
              onChanged: (v) => setState(() => value = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('انصراف'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, value),
          child: const Text('تأیید'),
        ),
      ],
    );
  }
}

Future<void> _doBackup(BuildContext context) async {
  final backupRepo = locator<IBackupRepository>();
  try {
    final json = await backupRepo.exportJson();
    final now = DateTime.now();
    final j = now.toJalali();
    final dateStr =
        '${j.year.toString().padLeft(4, '0')}-${j.month.toString().padLeft(2, '0')}-${j.day.toString().padLeft(2, '0')}';
    final defaultName = 'backup_$dateStr.json';
    final bytes = Uint8List.fromList(utf8.encode(json));
    final res = await FilePicker.platform.saveFile(
      dialogTitle: 'ذخیره فایل پشتیبان',
      fileName: defaultName,
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: bytes,
    );
    if (res != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('فایل پشتیبان ذخیره شد')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('عملیات ذخیره پشتیبان‌گیری لغو شد')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('خطا در پشتیبان‌گیری: $e')));
  }
}

Future<void> _doRestore(BuildContext context) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
  );
  if (result == null || result.files.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('انتخاب فایل لغو شد')));
    return;
  }
  final bytes = result.files.single.bytes;
  final path = result.files.single.path;
  String content;
  if (bytes != null) {
    content = String.fromCharCodes(bytes);
  } else if (path != null) {
    content = await io.File(path).readAsString();
  } else {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('خطا در خواندن فایل پشتیبان')));
    return;
  }
  try {
    final map = jsonDecode(content) as Map<String, dynamic>;
    await locator<IBackupRepository>().importJson(map);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('بازیابی با موفقیت انجام شد')));
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('خطا در بازیابی: $e')));
  }
}
