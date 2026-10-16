import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_ui.dart';
import '../../app/utils/bank_icons.dart';
import '../../app/utils/format.dart';
import '../../app/utils/jalali_utils.dart';
import '../../app/utils/pdf_report_utils.dart';
import '../../di/locator.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/transactions_usecases.dart';
import '../../domain/usecases/users_usecases.dart';
import '../cubits/users_cubit.dart';
// removed: not needed here after using openTransactionSheet
import 'transactions_page.dart' show showTransactionSheet;
import '../../app/theme/app_icons.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          UsersCubit(locator(), locator(), locator(), locator(), locator(), locator())
            ..watch(),
      child: const _UsersView(),
    );
  }
}

extension on _UserReportSheetState {
  Future<({List<int> userRunning, Map<int, int> loanRemainingByTxId})>
  _computeRunningData(List<TransactionAggregate> items) async {
    // Build running balance for the user (descending list from repo)
    // Rule: balance = sum(deposits) - sum(withdrawals). Other types are ignored.
    final List<int> running = List<int>.filled(items.length, 0);
    int cumulative = 0;
    for (int i = 0; i < items.length; i++) {
      final trn = items[i].transaction;
      if (isDepositType(trn.type)) {
        cumulative += trn.amount.abs();
      } else if (isWithdrawType(trn.type)) {
        cumulative -= trn.amount.abs();
      }
      running[i] = cumulative;
    }

    // Loan remaining after every transaction (oldest → newest), carried forward
    // onto non-loan rows (deposits/withdrawals) so the PDF column is never blank.
    final allTx = await _fetchTx(
      TransactionsFilterEntity(userId: widget.user.id),
      limit: 100000,
      offset: 0,
    );
    final chronological = allTx.map((e) => e.transaction).toList()
      ..sort((a, b) {
        final byDate = a.createdAt.compareTo(b.createdAt);
        return byDate != 0 ? byDate : a.id.compareTo(b.id);
      });

    int remaining = 0;
    final Map<int, int> loanRemainingByTxId = <int, int>{};
    for (final trn in chronological) {
      if (isLoanPrincipalType(trn.type)) {
        remaining += trn.amount.abs();
      } else if (isLoanInstallmentType(trn.type)) {
        remaining -= trn.amount.abs();
      }
      loanRemainingByTxId[trn.id] = remaining;
    }

    return (userRunning: running, loanRemainingByTxId: loanRemainingByTxId);
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
                        child: AppEmptyState(
                          message: tr('users.not_found'),
                          icon: AppIcons.users,
                        ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openUserSheet(context),
        icon: const Icon(AppIcons.userAdd),
        label: Text(tr('users.add')),
      ),
    );
  }

  List<Widget> _buildGroupedUserSlivers(List<UserEntity> users) {
    final List<Widget> slivers = [];
    String? currentHeader;
    final List<UserEntity> buffer = [];

    void flushBuffer() {
      final header = currentHeader;
      if (header == null || buffer.isEmpty) return;
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: AppSectionLabel(header),
          ),
        ),
      );
      final List<UserEntity> sectionItems = List<UserEntity>.from(buffer);
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
      currentHeader ??= hdr;
      if (hdr != currentHeader) {
        flushBuffer();
        currentHeader = hdr;
      }
      buffer.add(u);
    }
    flushBuffer();

    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 80)));

    return slivers;
  }

  Future<void> _openTransactionSheetForUser(
    BuildContext context, {
    int? userId,
  }) async {
    await showTransactionSheet(context, initialUserId: userId);
    if (!mounted) return;
    // Rebuild to refresh per-user balance FutureBuilders after adding a tx
    setState(() {});
  }

  String _initialOf(UserEntity u) {
    final source = (u.firstName.isNotEmpty ? u.firstName : u.lastName).trim();
    if (source.isEmpty) return '#';
    return source.substring(0, 1).toUpperCase();
  }

  Future<void> _openUserSheet(BuildContext context, {UserEntity? user}) async {
    final usersCubit = context.read<UsersCubit>();
    await showAppModalSheet(
      context: context,
      builder: (context) => BlocProvider.value(
        value: usersCubit,
        child: _UserSheet(user: user),
      ),
    );
  }

  Future<void> _openUserReportSheet(
    BuildContext context,
    UserEntity user,
  ) async {
    await showAppModalSheet(
      context: context,
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
        return Text('${tr('users.balance')}: ${formatAmount(balance)}');
      },
    );
  }
}

class _UserLoansRemainingText extends StatelessWidget {
  final int userId;
  const _UserLoansRemainingText({required this.userId});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: context.read<UsersCubit>().getUserLoansRemaining(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Text('${tr('users.installments_remaining')}: ...');
        }
        final remaining = snapshot.data ?? 0;
        return Text(
          '${tr('users.installments_remaining')}: ${formatAmount(remaining)}',
        );
      },
    );
  }
}

class _UserReportSheet extends StatefulWidget {
  final UserEntity user;
  const _UserReportSheet({required this.user});
  @override
  State<_UserReportSheet> createState() => _UserReportSheetState();
}

class _UserReportSheetState extends State<_UserReportSheet> {
  late Future<List<TransactionAggregate>> _future;
  String? _typeFilter; // null = all
  late final FetchTransactionsUseCase _fetchTx;
  @override
  void initState() {
    super.initState();
    _fetchTx = locator<FetchTransactionsUseCase>();
    _future = _fetchTx(
      TransactionsFilterEntity(userId: widget.user.id, type: _typeFilter),
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: AppSheetTitle(
                tr('users_report.title_pdf'),
                icon: AppIcons.receipt,
              ),
            ),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.secondary.withValues(alpha: 0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: const Icon(AppIcons.user, color: Colors.white),
              ),
              title: Text(
                '${widget.user.firstName} ${widget.user.lastName}',
                style: const TextStyle(fontWeight: FontWeight.w700),
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
                icon: const Icon(AppIcons.pdf),
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
                      initialValue: _typeFilter,
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
                          _future = _fetchTx(
                            TransactionsFilterEntity(
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
                tr('users_report.last20'),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Expanded(
              child: FutureBuilder<List<TransactionAggregate>>(
                future: _future,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return Center(child: Text(tr('transactions.not_found')));
                  }
                  return FutureBuilder<
                    ({List<int> userRunning, Map<int, int> loanRemainingByTxId})
                  >(
                    future: _computeRunningData(items),
                    builder: (context, snap2) {
                      if (!snap2.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final computed = snap2.data!;
                      return ListView.builder(
                        controller: controller,
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final it = items[index];
                          final trn = it.transaction;
                          final isIncome = trn.amount >= 0;

                          String? loanRemainingLine;
                          String? walletRemainingLine;
                          if (isLoanRelatedType(trn.type)) {
                            final remaining =
                                computed.loanRemainingByTxId[trn.id] ?? 0;
                            loanRemainingLine =
                                '${tr('transactions.loan_remaining')}: ${formatAmount(remaining)}';
                          } else {
                            final bal = computed.userRunning[index];
                            walletRemainingLine =
                                '${tr('users.balance')}: ${formatAmount(bal)}';
                          }

                          return ListTile(
                            leading: BankCircleAvatar(
                              bankKey: it.bank.bankKey,
                              name:
                                  (context.locale.languageCode == 'fa'
                                      ? BankIcons.persianNames[it.bank.bankKey]
                                      : BankIcons.englishNames[it
                                            .bank
                                            .bankKey]) ??
                                  it.bank.bankKey,
                            ),
                            title: Text(
                              (context.locale.languageCode == 'fa'
                                  ? JalaliUtils.formatJalali(trn.createdAt)
                                  : JalaliUtils.formatGregorian(trn.createdAt)),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${(context.locale.languageCode == 'fa' ? (BankIcons.persianNames[it.bank.bankKey] ?? it.bank.bankKey) : (BankIcons.englishNames[it.bank.bankKey] ?? it.bank.bankKey))} · ${it.bank.accountName}',
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${tr('transactions.type')}: ${_localizedType(context, trn.type)}',
                                ),
                                if (loanRemainingLine != null)
                                  Text(loanRemainingLine),
                                if (walletRemainingLine != null)
                                  Text(walletRemainingLine),
                              ],
                            ),
                            trailing: Text(
                              formatAmount(trn.amount.abs()),
                              style: TextStyle(
                                color: isIncome ? Colors.green : Colors.red,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportUserPdf() async {
    // Load fonts used earlier for Farsi support
    final baseFontData = await rootBundle.load(
      'assets/fonts/IRANYekanXFaNum-Regular.ttf',
    );
    final boldFontData = await rootBundle.load(
      'assets/fonts/IRANYekanXFaNum-Bold.ttf',
    );
    final baseFont = pw.Font.ttf(baseFontData.buffer.asByteData());
    final boldFont = pw.Font.ttf(boldFontData.buffer.asByteData());

    final repo = locator<FetchTransactionsUseCase>();
    final rows = await repo(
      TransactionsFilterEntity(userId: widget.user.id),
      limit: 20,
      offset: 0,
    );
    final computed = await _computeRunningData(rows);
    // Current total user balance (deposits - withdrawals), excluding loan rows
    final getUserBalance = locator<GetUserBalanceUseCase>();
    final int totalUserBalance = await getUserBalance(widget.user.id);

    final doc = pw.Document();
    // Resolve headers with safe fallbacks if a key is missing at runtime
    String safeTr(String key, String fallback) {
      final val = tr(key);
      return (val == key || val.trim().isEmpty) ? fallback : val;
    }

    final String hDate = safeTr('transactions.date', 'تاریخ');
    final String hType = safeTr('transactions.type', 'نوع');
    final String hAmount = safeTr('transactions.amount', 'مبلغ');
    final String hUserBal = safeTr('users.balance', 'موجودی');
    // Prefer specific loan remaining; fallback to generic remaining
    final String hLoanRem = () {
      final v = tr('transactions.loan_remaining');
      if (v == 'transactions.loan_remaining' || v.trim().isEmpty) {
        final v2 = tr('loans.remaining');
        return (v2 == 'loans.remaining' || v2.trim().isEmpty)
            ? 'باقیمانده وام'
            : v2;
      }
      return v;
    }();
    final String hRow = safeTr('transactions.row', 'ردیف');
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
                  tr('users_report.title_pdf'),
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
                  // Table columns paint LTR; last child is on the RIGHT.
                  // Desired RTL visual: ردیف | مبلغ | نوع | موجودی | باقیمانده وام | تاریخ
                  pw.Table(
                    border: pw.TableBorder.all(width: 0.5),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(1.2),
                      1: const pw.FlexColumnWidth(1.3),
                      2: const pw.FlexColumnWidth(1.2),
                      3: const pw.FlexColumnWidth(1.6),
                      4: const pw.FlexColumnWidth(1.2),
                      5: const pw.FlexColumnWidth(0.6),
                    },
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey300,
                        ),
                        children: [
                          pdfCellText(hDate, bold: true),
                          pdfCellText(hLoanRem, bold: true),
                          pdfCellText(hUserBal, bold: true),
                          pdfCellText(hType, bold: true),
                          pdfCellText(hAmount, bold: true),
                          pdfCellText(hRow, bold: true),
                        ],
                      ),
                      ...rows.asMap().entries.map((entry) {
                        final idx = entry.key + 1;
                        final trn = entry.value.transaction;
                        // Newest-first: balance(i) = total - sum(changes of rows 0..i-1)
                        final int userBal = (entry.key == 0)
                            ? totalUserBalance
                            : (totalUserBalance -
                                  computed.userRunning[entry.key - 1]);
                        final int loanRem =
                            computed.loanRemainingByTxId[trn.id] ?? 0;

                        return pw.TableRow(
                          children: [
                            pdfCellText(
                              JalaliUtils.formatJalali(trn.createdAt),
                            ),
                            pdfCellText(
                              formatAmount(loanRem),
                              underline: isLoanRelatedType(trn.type),
                            ),
                            pdfCellText(
                              formatAmount(userBal),
                              underline: isWalletType(trn.type),
                            ),
                            pdfCellText(trn.type),
                            pdfCellText(
                              formatAmount(trn.amount.abs()),
                              color: pdfAmountColor(trn.type),
                            ),
                            pdfCellText(idx.toString()),
                          ],
                        );
                      }),
                    ],
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
    await Share.shareXFiles([
      XFile(file.path),
    ], text: tr('users_report.share_text'));
  }
}

class _UserSheet extends StatefulWidget {
  final UserEntity? user;
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
  late final TextEditingController membershipNumber;

  @override
  void initState() {
    super.initState();
    firstName = TextEditingController(text: widget.user?.firstName ?? '');
    lastName = TextEditingController(text: widget.user?.lastName ?? '');
    fatherName = TextEditingController(text: widget.user?.fatherName ?? '');
    mobile = TextEditingController(text: widget.user?.mobileNumber ?? '');
    membershipNumber = TextEditingController(
      text: widget.user?.membershipNumber ?? '',
    );
  }

  @override
  void dispose() {
    firstName.dispose();
    lastName.dispose();
    fatherName.dispose();
    mobile.dispose();
    membershipNumber.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.user != null;
    return AppSheetBody(
      title: isEdit ? tr('users.edit') : tr('users.add'),
      icon: isEdit ? AppIcons.user : AppIcons.userAdd,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: firstName,
                    decoration: InputDecoration(
                      labelText: tr('users.first_name'),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? tr('common.required') : null,
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
                        (v == null || v.isEmpty) ? tr('common.required') : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: fatherName,
              decoration: InputDecoration(labelText: tr('users.father_name')),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? tr('common.required')
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: mobile,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: tr('users.mobile'),
                suffixIcon: IconButton(
                  tooltip: tr('users_report.pick_from_contacts'),
                  icon: const Icon(AppIcons.contacts),
                  onPressed: _pickContactAndFill,
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? tr('common.required')
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: membershipNumber,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: tr('users.membership_number'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final cubit = context.read<UsersCubit>();
                    final membership = membershipNumber.text.trim();
                    if (isEdit) {
                      await cubit.updateUser(
                        id: widget.user!.id,
                        firstName: firstName.text.trim(),
                        lastName: lastName.text.trim(),
                        fatherName: fatherName.text.trim(),
                        mobile: mobile.text.trim(),
                        membershipNumber: membership.isEmpty
                            ? null
                            : membership,
                      );
                    } else {
                      await cubit.addUser(
                        firstName: firstName.text.trim(),
                        lastName: lastName.text.trim(),
                        fatherName: fatherName.text.trim(),
                        mobile: mobile.text.trim(),
                        membershipNumber: membership.isEmpty
                            ? null
                            : membership,
                      );
                    }
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                icon: Icon(isEdit ? AppIcons.save : AppIcons.add),
                label: Text(isEdit ? tr('users.save') : tr('users.create')),
              ),
            ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: theme.scaffoldBackgroundColor,
      elevation: overlapsContent ? 0.5 : 0,
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: SizedBox(
          height: 52,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (isDark ? AppColors.darkOutline : AppColors.lightOutline)
                    .withValues(alpha: 0.9),
              ),
            ),
            child: TextField(
              controller: searchController,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: hintText,
                prefixIcon: Icon(
                  AppIcons.search,
                  color: theme.colorScheme.primary,
                ),
                suffixIcon: searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(AppIcons.close),
                        onPressed: onClear,
                      ),
                isDense: true,
                filled: true,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
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
  final UserEntity user;
  final VoidCallback onTap;
  final ValueChanged<String> onSelectedAction;

  const _UserTile({
    required this.user,
    required this.onTap,
    required this.onSelectedAction,
  });

  String _initials() {
    final membership = user.membershipNumber?.trim();
    if (membership != null && membership.isNotEmpty) return membership;
    return '#';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = [
      user.fatherName,
      user.mobileNumber,
    ].where((e) => (e ?? '').isNotEmpty).join(' · ');

    return AppSurface(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      radius: 18,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.secondary.withValues(alpha: 0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(),
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user.firstName} ${user.lastName}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    meta,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.55,
                      ),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DefaultTextStyle(
                      style:
                          theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ) ??
                          const TextStyle(),
                      child: _UserBalanceText(userId: user.id),
                    ),
                    const SizedBox(height: 6),
                    DefaultTextStyle(
                      style:
                          theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w700,
                          ) ??
                          const TextStyle(),
                      child: _UserLoansRemainingText(userId: user.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: Icon(
              AppIcons.more,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
            onSelected: onSelectedAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'add_tx',
                child: Text(tr('users.add_transaction')),
              ),
              PopupMenuItem(value: 'edit', child: Text(tr('users.edit'))),
              PopupMenuItem(value: 'delete', child: Text(tr('users.delete'))),
              PopupMenuItem(
                value: 'user_report',
                child: Text(tr('users_report.menu_user_report')),
              ),
            ],
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
            SnackBar(content: Text(tr('users_report.mobile_only'))),
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
            SnackBar(content: Text(tr('users_report.perm_denied'))),
          );
        }
        return;
      }

      // Prefer an in-app picker to include contacts from SIM/phone accounts
      // Some OEM pickers may hide SIM contacts. Our picker lists all visible
      // contacts with at least one phone number via Contacts provider.
      final Contact? picked = await _pickContactInApp();
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(tr('users_report.no_phone'))));
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
        selected = await showAppModalSheet<String>(
          context: context,
          useRootNavigator: true,
          builder: (sheetCtx) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.4,
              minChildSize: 0.25,
              maxChildSize: 0.9,
              builder: (ctx, scrollController) {
                return Column(
                  children: [
                    const AppSheetHandle(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: AppSheetTitle(
                        tr('users_report.choose_number'),
                        icon: AppIcons.phone,
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: numbers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final n = numbers[index];
                          return AppSurface(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            radius: 14,
                            onTap: () => Navigator.of(sheetCtx).pop(n),
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(AppIcons.call),
                              title: Text(n),
                            ),
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

  Future<Contact?> _pickContactInApp() async {
    try {
      // Fetch visible contacts with their phone numbers
      final List<Contact> contacts = await FlutterContacts.getContacts(
        withProperties: true,
      );
      final List<Contact> contactsWithPhone = contacts
          .where((c) => c.phones.isNotEmpty)
          .toList();
      if (contactsWithPhone.isEmpty) return null;

      // Show a simple bottom sheet list to pick a contact
      if (!mounted) return null;
      FocusScope.of(context).unfocus();
      await Future<void>.delayed(const Duration(milliseconds: 16));
      return await showAppModalSheet<Contact>(
        context: context,
        useRootNavigator: true,
        builder: (sheetCtx) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.8,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (ctx, scrollController) {
              return Column(
                children: [
                  const AppSheetHandle(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: AppSheetTitle(
                      tr('users_report.pick_from_contacts'),
                      icon: AppIcons.contacts,
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: contactsWithPhone.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final c = contactsWithPhone[index];
                        final display = (c.displayName).trim();
                        final numPreview = c.phones.isNotEmpty
                            ? c.phones.first.number
                            : '';
                        return AppSurface(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          radius: 14,
                          onTap: () => Navigator.of(sheetCtx).pop(c),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(
                                alpha: 0.12,
                              ),
                              foregroundColor: AppColors.primary,
                              child: const Icon(AppIcons.user),
                            ),
                            title: Text(
                              display.isEmpty
                                  ? tr('common.unknown_user')
                                  : display,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(numPreview),
                          ),
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
              );
            },
          );
        },
      );
    } catch (_) {
      return null;
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
      s = '0${s.substring(3)}';
    } else if (s.startsWith('0098')) {
      s = '0${s.substring(4)}';
    } else if (s.startsWith('98')) {
      s = '0${s.substring(2)}';
    }

    // If starts with 9 (without 0) and looks like mobile, prefix 0
    if (s.startsWith('9') && s.length >= 10) {
      s = '0$s';
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

String _localizedType(BuildContext context, String storedType) {
  if (storedType == 'واریز') return tr('transactions.deposit');
  if (storedType == 'برداشت') return tr('transactions.withdraw');
  if (storedType == 'پرداخت وام به کاربر')
    return tr('transactions.loan_principal');
  if (storedType == 'پرداخت قسط وام')
    return tr('transactions.loan_installment');
  if (storedType == 'جابجایی بین بانکی')
    return tr('transactions.bank_transfer');
  return storedType;
}
