import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter/foundation.dart';

import '../../di/locator.dart';
import '../../data/local/db/app_database.dart';
import '../cubits/users_cubit.dart';
import '../../app/utils/format.dart';
import '../../app/utils/bank_icons.dart';
import '../../app/utils/jalali_utils.dart';
import '../../data/repositories/transactions_repository.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
// removed: not needed here after using openTransactionSheet
import 'transactions_page.dart' show showTransactionSheet;

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UsersCubit(locator())..watch(),
      child: const _UsersView(),
    );
  }
}

class _UsersView extends StatefulWidget {
  const _UsersView();
  @override
  State<_UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<_UsersView> {
  final TextEditingController _search = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _search.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<UsersCubit>();
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<UsersCubit, UsersState>(
          builder: (context, state) {
            final users = state.users;
            return Stack(
              children: [
                CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SearchHeaderDelegate(
                        searchController: _search,
                        hintText: tr('users.search_hint'),
                        onChanged: (v) {
                          cubit.watch(v);
                          setState(() {});
                        },
                        onClear: () {
                          _search.clear();
                          cubit.watch('');
                          setState(() {});
                        },
                      ),
                    ),
                    if (state.loading)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (users.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: Text(tr('users.not_found'))),
                      ),
                    if (!state.loading && users.isNotEmpty)
                      ..._buildGroupedUserSlivers(users),
                  ],
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openUserSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  List<Widget> _buildGroupedUserSlivers(List<User> users) {
    final List<Widget> slivers = [];
    String? currentHeader;
    final List<User> buffer = [];

    void flushBuffer() {
      if (currentHeader == null || buffer.isEmpty) return;
      final String safeHeader = currentHeader;
      slivers.add(
        SliverToBoxAdapter(
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            height: 36,
            child: Text(
              safeHeader,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
      final List<User> sectionItems = List<User>.from(buffer);
      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final u = sectionItems[index];
            return _UserTile(
              user: u,
              onTap: () => _openUserSheet(context, user: u),
              onSelectedAction: (v) async {
                if (v == 'add_tx') {
                  await _openTransactionSheetForUser(context, userId: u.id);
                } else if (v == 'edit') {
                  _openUserSheet(context, user: u);
                } else if (v == 'delete') {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(tr('users.delete')),
                      content: Text(
                        '${tr('users.confirm_delete', namedArgs: {'name': '${u.firstName} ${u.lastName}'})}\n${tr('users.delete_cascade_note')}',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(tr('common.cancel')),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(tr('users.delete')),
                        ),
                      ],
                    ),
                  );
                  if (ok == true && context.mounted) {
                    await context.read<UsersCubit>().deleteUser(u.id);
                  }
                } else if (v == 'user_report') {
                  await _openUserReportSheet(context, u);
                }
              },
            );
          }, childCount: sectionItems.length),
        ),
      );
      buffer.clear();
    }

    for (final u in users) {
      final hdr = _initialOf(u);
      if (currentHeader == null) {
        currentHeader = hdr;
      }
      if (hdr != currentHeader) {
        flushBuffer();
        currentHeader = hdr;
      }
      buffer.add(u);
    }
    flushBuffer();

    return slivers;
  }

  Future<void> _openTransactionSheetForUser(
    BuildContext context, {
    int? userId,
  }) async {
    await showTransactionSheet(context, initialUserId: userId);
  }

  String _initialOf(User u) {
    final source = (u.firstName.isNotEmpty ? u.firstName : u.lastName).trim();
    if (source.isEmpty) return '#';
    return source.substring(0, 1).toUpperCase();
  }

  Future<void> _openUserSheet(BuildContext context, {User? user}) async {
    final usersCubit = context.read<UsersCubit>();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => BlocProvider.value(
        value: usersCubit,
        child: _UserSheet(user: user),
      ),
    );
  }

  Future<void> _openUserReportSheet(BuildContext context, User user) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => _UserReportSheet(user: user),
    );
  }
}

class _UserBalanceText extends StatelessWidget {
  final int userId;
  const _UserBalanceText({required this.userId});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: context.read<UsersCubit>().getUserBalance(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Text('${tr('users.balance')}: ...');
        }
        final balance = snapshot.data ?? 0;
        return Text('${tr('users.balance')}: ${formatThousands(balance)}');
      },
    );
  }
}

class _UserReportSheet extends StatefulWidget {
  final User user;
  const _UserReportSheet({required this.user});
  @override
  State<_UserReportSheet> createState() => _UserReportSheetState();
}

class _UserReportSheetState extends State<_UserReportSheet> {
  late Future<List<TransactionWithJoins>> _future;
  String? _typeFilter; // null = all
  late final TransactionsRepository _repo;
  @override
  void initState() {
    super.initState();
    _repo = TransactionsRepository(locator());
    _future = _repo.fetchTransactions(
      TransactionsFilter(userId: widget.user.id, type: _typeFilter),
      limit: 20,
      offset: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, controller) {
        return SafeArea(
          top: false,
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    'ریز تراکنش های کاربر',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(
                    '${widget.user.firstName} ${widget.user.lastName}',
                  ),
                  subtitle: Text(
                    [
                      if ((widget.user.fatherName ?? '').isNotEmpty)
                        widget.user.fatherName!,
                      if ((widget.user.mobileNumber ?? '').isNotEmpty)
                        widget.user.mobileNumber!,
                    ].join(' · '),
                  ),
                  trailing: FilledButton.icon(
                    onPressed: _exportUserPdf,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: Text(tr('common.export_pdf')),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          value: _typeFilter,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'نوع تراکنش',
                          ),
                          items:
                              <String?>[
                                null,
                                tr('transactions.deposit'),
                                tr('transactions.withdraw'),
                                tr('transactions.loan_principal'),
                                tr('transactions.loan_installment'),
                                tr('transactions.bank_transfer'),
                              ].map((v) {
                                return DropdownMenuItem<String?>(
                                  value: v,
                                  child: Text(v ?? 'همه'),
                                );
                              }).toList(),
                          onChanged: (v) {
                            setState(() {
                              _typeFilter = v;
                              _future = _repo.fetchTransactions(
                                TransactionsFilter(
                                  userId: widget.user.id,
                                  type: _typeFilter,
                                ),
                                limit: 20,
                                offset: 0,
                              );
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    '۲۰ تراکنش اخیر',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<TransactionWithJoins>>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final items = snapshot.data ?? [];
                      if (items.isEmpty) {
                        return Center(
                          child: Text(tr('transactions.not_found')),
                        );
                      }
                      return ListView.builder(
                        controller: controller,
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final it = items[index];
                          final trn = it.transaction;
                          final isIncome = trn.amount >= 0;
                          return ListTile(
                            leading: BankCircleAvatar(
                              bankKey: it.bank.bankKey,
                              name:
                                  BankIcons.persianNames[it.bank.bankKey] ??
                                  it.bank.bankKey,
                            ),
                            title: Text(
                              JalaliUtils.formatJalali(trn.createdAt),
                            ),
                            subtitle: Text(
                              '${BankIcons.persianNames[it.bank.bankKey] ?? it.bank.bankKey} · ${it.bank.accountName}',
                            ),
                            trailing: Text(
                              '${formatThousands(trn.amount.abs())} ${tr('banks.rial')}',
                              style: TextStyle(
                                color: isIncome ? Colors.green : Colors.red,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _exportUserPdf() async {
    // Load fonts used earlier for Farsi support
    final baseFontData = await rootBundle.load(
      'assets/fonts/Vazirmatn-Regular.ttf',
    );
    final boldFontData = await rootBundle.load(
      'assets/fonts/Vazirmatn-Bold.ttf',
    );
    final baseFont = pw.Font.ttf(baseFontData.buffer.asByteData());
    final boldFont = pw.Font.ttf(boldFontData.buffer.asByteData());

    final repo = TransactionsRepository(locator());
    final rows = await repo.fetchTransactions(
      TransactionsFilter(userId: widget.user.id),
      limit: 20,
      offset: 0,
    );

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
        build: (ctx) => [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'ریز تراکنش‌های کاربر',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text('${widget.user.firstName} ${widget.user.lastName}'),
                if ((widget.user.mobileNumber ?? '').isNotEmpty)
                  pw.Text(widget.user.mobileNumber!),
                pw.SizedBox(height: 10),
                if (rows.isEmpty)
                  pw.Text(tr('transactions.not_found'))
                else
                  pw.Table.fromTextArray(
                    headers: [
                      tr('transactions.date'),
                      tr('transactions.type'),
                      tr('transactions.amount'),
                      tr('banks.bank'),
                    ],
                    cellAlignments: {
                      0: pw.Alignment.centerRight,
                      1: pw.Alignment.centerRight,
                      2: pw.Alignment.centerRight,
                      3: pw.Alignment.centerRight,
                    },
                    data: rows
                        .map(
                          (it) => [
                            JalaliUtils.formatJalali(it.transaction.createdAt),
                            it.transaction.type,
                            formatThousands(it.transaction.amount.abs()),
                            it.bank.accountName,
                          ],
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/user_${widget.user.id}_last20_$ts.pdf');
    await file.writeAsBytes(await doc.save());
    await Share.shareXFiles([XFile(file.path)], text: 'ریز تراکنش‌های کاربر');
  }
}

class _UserSheet extends StatefulWidget {
  final User? user;
  const _UserSheet({this.user});
  @override
  State<_UserSheet> createState() => _UserSheetState();
}

// Transaction sheet wrapper customized for Users page to preselect user
// wrapper حذف شد

class _UserSheetState extends State<_UserSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController firstName;
  late final TextEditingController lastName;
  late final TextEditingController fatherName;
  late final TextEditingController mobile;

  @override
  void initState() {
    super.initState();
    firstName = TextEditingController(text: widget.user?.firstName ?? '');
    lastName = TextEditingController(text: widget.user?.lastName ?? '');
    fatherName = TextEditingController(text: widget.user?.fatherName ?? '');
    mobile = TextEditingController(text: widget.user?.mobileNumber ?? '');
  }

  @override
  void dispose() {
    firstName.dispose();
    lastName.dispose();
    fatherName.dispose();
    mobile.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.user != null;
    final padding =
        MediaQuery.of(context).viewInsets + const EdgeInsets.all(16);
    return Padding(
      padding: padding,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isEdit ? tr('users.edit') : tr('users.add'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: firstName,
                    decoration: InputDecoration(
                      labelText: tr('users.first_name'),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'الزامی' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: lastName,
                    decoration: InputDecoration(
                      labelText: tr('users.last_name'),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'الزامی' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: fatherName,
              decoration: InputDecoration(labelText: tr('users.father_name')),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'الزامی' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: mobile,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: tr('users.mobile'),
                suffixIcon: IconButton(
                  tooltip: 'انتخاب از مخاطبین',
                  icon: const Icon(Icons.contacts),
                  onPressed: _pickContactAndFill,
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'الزامی' : null,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final cubit = context.read<UsersCubit>();
                    if (isEdit) {
                      await cubit.updateUser(
                        id: widget.user!.id,
                        firstName: firstName.text.trim(),
                        lastName: lastName.text.trim(),
                        fatherName: fatherName.text.trim(),
                        mobile: mobile.text.trim(),
                      );
                    } else {
                      await cubit.addUser(
                        firstName: firstName.text.trim(),
                        lastName: lastName.text.trim(),
                        fatherName: fatherName.text.trim(),
                        mobile: mobile.text.trim(),
                      );
                    }
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                child: Text(isEdit ? tr('users.save') : tr('users.create')),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _SearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TextEditingController searchController;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  _SearchHeaderDelegate({
    required this.searchController,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
  });

  @override
  double get minExtent => 72;

  @override
  double get maxExtent => 72;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: overlapsContent ? 1 : 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: hintText,
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: onClear,
                    ),
            ),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SearchHeaderDelegate oldDelegate) {
    return oldDelegate.searchController != searchController ||
        oldDelegate.hintText != hintText;
  }
}

class _UserTile extends StatelessWidget {
  final User user;
  final VoidCallback onTap;
  final ValueChanged<String> onSelectedAction;

  const _UserTile({
    required this.user,
    required this.onTap,
    required this.onSelectedAction,
  });

  String _initials() {
    final first = user.firstName.trim();
    final last = user.lastName.trim();
    if (first.isEmpty && last.isEmpty) return '#';
    final i1 = first.isNotEmpty ? first[0] : '';
    final i2 = last.isNotEmpty ? last[0] : '';
    final initials = (i1 + i2).toUpperCase();
    return initials.isEmpty ? '#' : initials;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(child: Text(_initials())),
            title: Text('${user.firstName} ${user.lastName}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [
                    user.fatherName,
                    user.mobileNumber,
                  ].where((e) => (e ?? '').isNotEmpty).join(' · '),
                ),
                const SizedBox(height: 2),
                _UserBalanceText(userId: user.id),
              ],
            ),
            trailing: PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              onSelected: onSelectedAction,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'add_tx',
                  child: Text(tr('users.add_transaction')),
                ),
                PopupMenuItem(value: 'edit', child: Text(tr('users.edit'))),
                PopupMenuItem(value: 'delete', child: Text(tr('users.delete'))),
                const PopupMenuItem(
                  value: 'user_report',
                  child: Text('نمایش ریز تراکنش‌ها'),
                ),
              ],
            ),
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

extension on _UserSheetState {
  Future<void> _pickContactAndFill() async {
    try {
      // Guard unsupported platforms (web/desktop)
      final bool isMobilePlatform =
          !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS);
      if (!isMobilePlatform) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('این قابلیت فقط روی موبایل در دسترس است'),
            ),
          );
        }
        return;
      }

      final bool granted = await FlutterContacts.requestPermission(
        readonly: true,
      );
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('اجازه دسترسی به مخاطبین داده نشد')),
          );
        }
        return;
      }

      // Using the external contact picker may cause a transient overlay/layout
      // glitch on return; we handle dialog with root navigator below.
      final Contact? picked = await FlutterContacts.openExternalPick();
      if (picked == null) return;

      final Contact? full = await FlutterContacts.getContact(
        picked.id,
        withProperties: true,
      );
      final List<String> numbers = (full ?? picked).phones
          .map((p) => p.number)
          .where((n) => n.trim().isNotEmpty)
          .toList();

      if (numbers.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('این مخاطب شماره‌ای ندارد')),
          );
        }
        return;
      }

      String? selected;
      if (numbers.length == 1) {
        selected = numbers.first;
      } else {
        if (!mounted) return;
        FocusScope.of(context).unfocus();
        await Future<void>.delayed(const Duration(milliseconds: 16));
        selected = await showModalBottomSheet<String>(
          context: context,
          useRootNavigator: true,
          isScrollControlled: true,
          builder: (sheetCtx) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.4,
              minChildSize: 0.25,
              maxChildSize: 0.9,
              builder: (ctx, scrollController) {
                return SafeArea(
                  top: false,
                  child: Material(
                    color: Theme.of(context).colorScheme.surface,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'انتخاب شماره تماس',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            controller: scrollController,
                            itemCount: numbers.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final n = numbers[index];
                              return ListTile(
                                title: Text(n),
                                onTap: () => Navigator.of(sheetCtx).pop(n),
                              );
                            },
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () => Navigator.of(sheetCtx).pop(),
                            child: Text(tr('common.cancel')),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      }

      if (selected != null && mounted) {
        // Fill name fields if empty using contact's name
        final Contact chosenContact = full ?? picked;
        if (firstName.text.trim().isEmpty || lastName.text.trim().isEmpty) {
          String cFirst = (chosenContact.name.first).trim();
          String cLast = (chosenContact.name.last).trim();

          if (cFirst.isEmpty && cLast.isEmpty) {
            final String dn = (chosenContact.displayName).trim();
            if (dn.isNotEmpty) {
              final parts = dn.split(RegExp(r"\s+"));
              if (parts.length == 1) {
                cFirst = parts.first;
              } else {
                cLast = parts.last;
                cFirst = parts.sublist(0, parts.length - 1).join(' ');
              }
            }
          }

          if (firstName.text.trim().isEmpty && cFirst.isNotEmpty) {
            firstName.text = cFirst;
          }
          if (lastName.text.trim().isEmpty && cLast.isNotEmpty) {
            lastName.text = cLast;
          }
        }
        mobile.text = _cleanPhone(selected);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطا در دسترسی به مخاطبین: $e')));
      }
    }
  }

  String _cleanPhone(String input) {
    String s = _toEnglishDigits(input).trim();
    // Remove common separators
    s = s.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    // Keep digits and optional leading plus for country code handling
    s = s.replaceAll(RegExp(r'[^0-9\+]'), '');

    // Normalize Iranian country code to leading 0
    if (s.startsWith('+98')) {
      s = '0' + s.substring(3);
    } else if (s.startsWith('0098')) {
      s = '0' + s.substring(4);
    } else if (s.startsWith('98')) {
      s = '0' + s.substring(2);
    }

    // If starts with 9 (without 0) and looks like mobile, prefix 0
    if (s.startsWith('9') && s.length >= 10) {
      s = '0' + s;
    }

    // Remove any remaining non-digits
    s = s.replaceAll(RegExp(r'[^0-9]'), '');

    // If number starts with double zero, collapse to a single leading zero
    s = s.replaceFirst(RegExp(r'^00+'), '0');

    return s;
  }

  String _toEnglishDigits(String input) {
    const String fa = '۰۱۲۳۴۵۶۷۸۹';
    const String ar = '٠١٢٣٤٥٦٧٨٩';
    return input.replaceAllMapped(RegExp('[\u06F0-\u06F9\u0660-\u0669]'), (m) {
      final String ch = m.group(0)!;
      int idx = fa.indexOf(ch);
      if (idx == -1) idx = ar.indexOf(ch);
      return idx >= 0 ? idx.toString() : ch;
    });
  }
}

// removed _NumberPickerPage; replaced with root bottom sheet selection
