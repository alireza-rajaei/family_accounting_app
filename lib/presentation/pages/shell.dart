import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';

import '../cubits/settings_cubit.dart';
import '../../di/locator.dart';
import '../../data/repositories/backup_repository.dart';

class ShellScaffold extends StatefulWidget {
  final Widget child;
  const ShellScaffold({super.key, required this.child});

  @override
  State<ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends State<ShellScaffold> {
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
    // final settings = context.watch<SettingsCubit>().state;

    final location = GoRouterState.of(context).uri.toString();
    // final settings = context.watch<SettingsCubit>().state;

    return Scaffold(
      appBar: AppBar(title: Text(tr('app_title'))),
      drawer: const _AppDrawer(),
      body: widget.child,
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

class _AppDrawer extends StatelessWidget {
  const _AppDrawer();
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>().state;
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(0),
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(settings.username),
              accountEmail: Text(
                settings.lastLoginAt != null
                    ? 'آخرین ورود: ${settings.lastLoginAt}'
                    : 'آخرین ورود: -',
              ),
              currentAccountPicture: const CircleAvatar(
                child: Icon(Icons.person),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.text_increase),
              title: Text(tr('drawer.font_size')),
              subtitle: Text('x${settings.fontScale.toStringAsFixed(2)}'),
              onTap: () async {
                final cubit = context.read<SettingsCubit>();
                final value = await showDialog<double>(
                  context: context,
                  builder: (context) =>
                      _FontScaleDialog(current: settings.fontScale),
                );
                if (value != null) cubit.setFontScale(value);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(tr('drawer.change_username')),
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
                        onPressed: () =>
                            Navigator.pop(context, controller.text.trim()),
                        child: const Text('ذخیره'),
                      ),
                    ],
                  ),
                );
                if (result != null && result.isNotEmpty) {
                  // ignore: use_build_context_synchronously
                  context.read<SettingsCubit>().setUsername(result);
                }
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: Text(tr('drawer.theme')),
              value: settings.themeMode == ThemeMode.dark,
              onChanged: (v) => context.read<SettingsCubit>().setThemeMode(
                v ? ThemeMode.dark : ThemeMode.light,
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.backup_outlined),
              title: Text(tr('drawer.backup')),
              onTap: () {
                _doBackup(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.restore_outlined),
              title: Text(tr('drawer.restore')),
              onTap: () {
                _doRestore(context);
              },
            ),
          ],
        ),
      ),
    );
  }
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
  final res = await FilePicker.platform.saveFile(
    dialogTitle: 'ذخیره فایل پشتیبان',
    fileName: 'backup.json',
  );
  if (res != null) {
    try {
      // If running on platforms with IO access
      await io.File(res).writeAsString(json);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('فایل پشتیبان ذخیره شد')));
    } catch (_) {
      // Fallback: copy to clipboard
      await Clipboard.setData(ClipboardData(text: json));
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('متن پشتیبان در کلیپ‌بورد کپی شد')),
      );
    }
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
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('بازیابی با موفقیت انجام شد')));
  } catch (e) {
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('خطا در بازیابی: $e')));
  }
}
