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

import '../cubits/settings_cubit.dart';
import '../../di/locator.dart';
import '../../data/repositories/backup_repository.dart';

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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final location = GoRouterState.of(context).uri.toString();

    return Scaffold(
      appBar: AppBar(title: Text(tr('app_title'))),
      drawer: const _AppDrawer(),
      body: PageStorage(bucket: PageStorageBucket(), child: widget.child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndexByLocation(location),
        onDestinationSelected: _onItemTapped,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            label: tr('tabs.home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.swap_vert),
            label: tr('tabs.transactions'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.request_quote_outlined),
            label: tr('tabs.loans'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_alt_outlined),
            label: tr('tabs.users'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_outlined),
            label: tr('tabs.banks'),
          ),
        ],
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

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>().state;
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(0),
                children: [
                  DrawerHeader(
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          child: Icon(Icons.person, size: 28),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          settings.username,
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          settings.lastLoginAt != null
                              ? 'آخرین ورود: ${_formatJalaliFull(settings.lastLoginAt!)}'
                              : 'آخرین ورود: -',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(
                      tr('drawer.change_username'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
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
                              child: const Text('انصراف'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(
                                context,
                                controller.text.trim(),
                              ),
                              child: const Text('ذخیره'),
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
                    secondary: const Icon(Icons.dark_mode_outlined),
                    title: Text(
                      tr('drawer.theme'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    value: settings.themeMode == ThemeMode.dark,
                    onChanged: (v) => context
                        .read<SettingsCubit>()
                        .setThemeMode(v ? ThemeMode.dark : ThemeMode.light),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(
                      tr('drawer.language'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
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
                                onTap: () =>
                                    Navigator.pop(context, const Locale('fa')),
                              ),
                              ListTile(
                                leading: const Text('🇺🇸'),
                                title: Text(tr('lang.en')),
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
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.backup_outlined),
                    title: Text(
                      tr('drawer.backup'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    onTap: () {
                      _doBackup(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.restore_outlined),
                    title: Text(
                      tr('drawer.restore'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    onTap: () {
                      _doRestore(context);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(
                      tr('drawer.about'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
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
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge!
                                            .color!
                                            .withValues(alpha: 0.2),
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      tr('about.email_label'),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
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
                                      child: const Text(
                                        'arajaei8@gmail.com',
                                        style: TextStyle(
                                          color: Colors.blue,
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
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  tr('drawer.version', args: [_version ?? '-']),
                  style: Theme.of(context).textTheme.bodySmall,
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
  final backupRepo = locator<BackupRepository>();
  final json = await backupRepo.exportJson();
  final bytes = Uint8List.fromList(utf8.encode(json));
  final res = await FilePicker.platform.saveFile(
    dialogTitle: 'ذخیره فایل پشتیبان',
    fileName: 'backup.json',
    type: FileType.custom,
    allowedExtensions: ['json'],
    bytes: bytes,
  );
  if (res != null) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('فایل پشتیبان ذخیره شد')));
  }
}

Future<void> _doRestore(BuildContext context) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
  );
  if (result == null || result.files.isEmpty) return;
  final bytes = result.files.single.bytes;
  final path = result.files.single.path;
  String content;
  if (bytes != null) {
    content = String.fromCharCodes(bytes);
  } else if (path != null) {
    content = await io.File(path).readAsString();
  } else {
    return;
  }
  try {
    final map = jsonDecode(content) as Map<String, dynamic>;
    await locator<BackupRepository>().importJson(map);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('بازیابی با موفقیت انجام شد')));
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('خطا در بازیابی: $e')));
  }
}
