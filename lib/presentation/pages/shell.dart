import 'dart:convert';
import 'dart:io' as io;

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_icons.dart';
import '../../app/theme/app_ui.dart';
import '../../di/locator.dart';
import '../../domain/repositories/i_backup_repository.dart';
import '../cubits/settings_cubit.dart';

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
                  icon: const Icon(AppIcons.home),
                  selectedIcon: const Icon(AppIcons.homeFilled),
                  label: tr('tabs.home'),
                ),
                NavigationDestination(
                  icon: const Icon(AppIcons.transactions),
                  selectedIcon: const Icon(AppIcons.transactionsFilled),
                  label: tr('tabs.transactions'),
                ),
                NavigationDestination(
                  icon: const Icon(AppIcons.loans),
                  selectedIcon: const Icon(AppIcons.loansFilled),
                  label: tr('tabs.loans'),
                ),
                NavigationDestination(
                  icon: const Icon(AppIcons.users),
                  selectedIcon: const Icon(AppIcons.usersFilled),
                  label: tr('tabs.users'),
                ),
                NavigationDestination(
                  icon: const Icon(AppIcons.banks),
                  selectedIcon: const Icon(AppIcons.banksFilled),
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
      if (mounted) setState(() => _version = info.version);
    } catch (_) {
      if (mounted) setState(() => _version = null);
    }
  }

  Future<void> _changeUsername(String current) async {
    final result = await showAppModalSheet<String>(
      context: context,
      builder: (ctx) => _ChangeUsernameSheet(initial: current),
    );
    if (result != null && result.isNotEmpty && mounted) {
      await context.read<SettingsCubit>().setUsername(result);
    }
  }

  Future<void> _pickLanguage() async {
    final current = context.locale.languageCode;
    final selected = await showAppModalSheet<Locale>(
      context: context,
      builder: (ctx) => AppSheetBody(
        title: tr('drawer.language'),
        icon: AppIcons.language,
        child: Column(
          children: [
            _LangOption(
              label: tr('lang.fa'),
              flag: '🇮🇷',
              selected: current == 'fa',
              onTap: () => Navigator.pop(ctx, const Locale('fa')),
            ),
            const SizedBox(height: 8),
            _LangOption(
              label: tr('lang.en'),
              flag: '🇺🇸',
              selected: current == 'en',
              onTap: () => Navigator.pop(ctx, const Locale('en')),
            ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) {
      await context.setLocale(selected);
    }
  }

  void _showAbout() {
    final theme = Theme.of(context);
    showAppModalSheet<void>(
      context: context,
      builder: (ctx) => AppSheetBody(
        title: tr('about.title'),
        icon: AppIcons.info,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(tr('about.body'), style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            Text(
              tr('about.lead'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final uri = Uri(
                  scheme: 'mailto',
                  path: 'arajaei8@gmail.com',
                  queryParameters: const {
                    'subject': 'Feedback - Family Accounting App',
                  },
                );
                final launched = await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                );
                if (!launched) {
                  await Clipboard.setData(
                    const ClipboardData(text: 'arajaei8@gmail.com'),
                  );
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(tr('about.email_copy_fallback'))),
                    );
                  }
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    AppIconBadge(icon: AppIcons.phone, size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('about.email_label'),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.55,
                              ),
                            ),
                          ),
                          Text(
                            'arajaei8@gmail.com',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr('common.ok')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>().state;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final outline = (isDark ? AppColors.darkOutline : AppColors.lightOutline)
        .withValues(alpha: 0.95);
    final langLabel = context.locale.languageCode == 'fa'
        ? tr('lang.fa')
        : tr('lang.en');
    final initial = settings.username.isNotEmpty
        ? settings.username.characters.first.toUpperCase()
        : '?';

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.horizontal(
          end: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
              child: _DrawerHeader(
                username: settings.username,
                initial: initial,
                lastLogin: settings.lastLoginAt != null
                    ? tr(
                        'drawer.last_login',
                        namedArgs: {
                          'time': _formatLastLogin(
                            context,
                            settings.lastLoginAt!,
                          ),
                        },
                      )
                    : tr('drawer.last_login', namedArgs: {'time': '-'}),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                children: [
                  _DrawerSectionLabel(tr('drawer.section_account')),
                  AppSurface(
                    padding: EdgeInsets.zero,
                    radius: 18,
                    child: _DrawerTile(
                      icon: AppIcons.userEdit,
                      title: tr('drawer.change_username'),
                      subtitle: settings.username,
                      onTap: () => _changeUsername(settings.username),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _DrawerSectionLabel(tr('drawer.section_appearance')),
                  AppSurface(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    radius: 18,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            AppIconBadge(icon: AppIcons.moon, size: 40),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                tr('drawer.theme'),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _ThemeSegmented(
                          isDark: settings.themeMode == ThemeMode.dark,
                          onChanged: (dark) =>
                              context.read<SettingsCubit>().setThemeMode(
                                dark ? ThemeMode.dark : ThemeMode.light,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Divider(height: 20, color: outline),
                        _DrawerTile(
                          icon: AppIcons.language,
                          title: tr('drawer.language'),
                          trailingLabel: langLabel,
                          dense: true,
                          onTap: _pickLanguage,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _DrawerSectionLabel(tr('drawer.section_data')),
                  AppSurface(
                    padding: EdgeInsets.zero,
                    radius: 18,
                    child: Column(
                      children: [
                        _DrawerTile(
                          icon: AppIcons.backup,
                          title: tr('drawer.backup'),
                          onTap: () => _doBackup(context),
                        ),
                        Divider(height: 1, indent: 68, color: outline),
                        _DrawerTile(
                          icon: AppIcons.restore,
                          title: tr('drawer.restore'),
                          onTap: () => _doRestore(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppSurface(
                    padding: EdgeInsets.zero,
                    radius: 18,
                    child: _DrawerTile(
                      icon: AppIcons.info,
                      title: tr('drawer.about'),
                      onTap: _showAbout,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                children: [
                  Text(
                    tr('app_title'),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tr(
                      'drawer.version',
                      namedArgs: {'version': _version ?? '-'},
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangeUsernameSheet extends StatefulWidget {
  const _ChangeUsernameSheet({required this.initial});

  final String initial;

  @override
  State<_ChangeUsernameSheet> createState() => _ChangeUsernameSheetState();
}

class _ChangeUsernameSheetState extends State<_ChangeUsernameSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final trimmed = _controller.text.trim();
    if (trimmed.isNotEmpty) Navigator.pop(context, trimmed);
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetBody(
      title: tr('drawer.change_username'),
      icon: AppIcons.userEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: tr('login.username'),
              hintText: tr('drawer.username_hint'),
              prefixIcon: const Icon(AppIcons.user),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(AppIcons.save, size: 18),
            label: Text(tr('common.ok')),
          ),
        ],
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.username,
    required this.initial,
    required this.lastLogin,
  });

  final String username;
  final String initial;
  final String lastLogin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: isDark
              ? [
                  AppColors.primary.withValues(alpha: 0.42),
                  AppColors.secondary.withValues(alpha: 0.22),
                ]
              : [
                  AppColors.primary,
                  Color.lerp(AppColors.primary, AppColors.secondary, 0.7)!,
                ],
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('app_title'),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lastLogin,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerSectionLabel extends StatelessWidget {
  const _DrawerSectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailingLabel,
    this.onTap,
    this.dense = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailingLabel;
  final VoidCallback? onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flipChevron = Directionality.of(context).name != 'rtl';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: dense ? 0 : 12,
            vertical: dense ? 8 : 12,
          ),
          child: Row(
            children: [
              AppIconBadge(icon: icon, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailingLabel != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    trailingLabel!,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Transform.flip(
                flipX: flipChevron,
                child: Icon(
                  AppIcons.chevron,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeSegmented extends StatelessWidget {
  const _ThemeSegmented({required this.isDark, required this.onChanged});

  final bool isDark;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outline =
        (theme.brightness == Brightness.dark
                ? AppColors.darkOutline
                : AppColors.lightOutline)
            .withValues(alpha: 0.95);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ThemeChip(
              icon: AppIcons.sun,
              label: tr('drawer.theme_light'),
              selected: !isDark,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _ThemeChip(
              icon: AppIcons.moon,
              label: tr('drawer.theme_dark'),
              selected: isDark,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected ? theme.colorScheme.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? Colors.white
                    : theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: selected
                      ? Colors.white
                      : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  const _LangOption({
    required this.label,
    required this.flag,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String flag;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final outline = (isDark ? AppColors.darkOutline : AppColors.lightOutline)
        .withValues(alpha: 0.95);

    return Material(
      color: selected
          ? theme.colorScheme.primary.withValues(alpha: 0.1)
          : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? theme.colorScheme.primary : outline,
          width: selected ? 1.4 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (selected)
                Icon(
                  AppIcons.check,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
            ],
          ),
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
