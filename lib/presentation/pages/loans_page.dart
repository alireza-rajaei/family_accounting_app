import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
// Using custom TTF fonts from assets instead of google fonts package
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
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
import '../../app/utils/thousands_input_formatter.dart';
import '../../di/locator.dart';
import '../../domain/entities/bank.dart';
import '../../domain/entities/loan.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/transactions_usecases.dart';
import '../cubits/banks_cubit.dart';
import '../cubits/loans_cubit.dart';
import '../cubits/users_cubit.dart';
import 'transactions_page.dart' show showTransactionSheet;
import '../../app/theme/app_icons.dart';

class LoansPage extends StatelessWidget {
  const LoansPage({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => LoansCubit(
            locator(),
            locator(),
            locator(),
            locator(),
            locator(),
            locator(),
            locator(),
            locator(),
          )..watch(),
        ),
        BlocProvider(
          create: (_) =>
              UsersCubit(locator(), locator(), locator(), locator(), locator(), locator())
                ..watch(),
        ),
        BlocProvider(
          create: (_) =>
              BanksCubit(locator(), locator(), locator(), locator())..watch(),
        ),
      ],
      child: const _LoansView(),
    );
  }
}

Future<void> _openLoanReportSheet(BuildContext context, LoanEntity loan) async {
  await showAppModalSheet(
    context: context,
    builder: (sheetContext) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.read<LoansCubit>()),
        BlocProvider.value(value: context.read<UsersCubit>()),
        BlocProvider.value(value: context.read<BanksCubit>()),
      ],
      child: _LoanReportSheet(loan: loan),
    ),
  );
}

class _LoanReportSheet extends StatelessWidget {
  final LoanEntity loan;
  const _LoanReportSheet({required this.loan});
  @override
  Widget build(BuildContext context) {
    final usersState = context.read<UsersCubit>().state;
    final user = usersState.users.firstWhere(
      (u) => u.id == loan.userId,
      orElse: () => usersState.users.isNotEmpty
          ? usersState.users.first
          : UserEntity(
              id: -1,
              firstName: tr('common.unknown_user'),
              lastName: '',
              fatherName: null,
              mobileNumber: null,
              createdAt: DateTime.now(),
              updatedAt: null,
            ),
    );

    final isFa = context.locale.languageCode == 'fa';
    final dateStr = isFa
        ? JalaliUtils.formatJalali(loan.createdAt)
        : JalaliUtils.formatGregorian(loan.createdAt);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, controller) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppSheetHandle(),
              AppSheetTitle(
                tr('loans.report_title'),
                icon: AppIcons.loansFilled,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _LoanAvatar(),
                title: Text(
                  '${user.firstName} ${user.lastName}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${tr('loans.principal')}: ${formatAmount(loan.principalAmount)} · ${tr('loans.installments')}: ${loan.installments}',
                ),
                trailing: Text(dateStr),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: () => _exportLoanReportPdf(context, loan),
                  icon: const Icon(AppIcons.pdf),
                  label: Text(tr('common.export_pdf')),
                ),
              ),
              StreamBuilder<List<LoanWithStatsEntity>>(
                stream: context.read<LoansCubit>().watchLoans(),
                builder: (context, snap) {
                  final loanStats = (snap.data ?? [])
                      .where((e) => e.loan.id == loan.id)
                      .toList();
                  final remaining = loanStats.isNotEmpty
                      ? loanStats.first.remaining
                      : loan.principalAmount;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '${tr('loans.remaining')}: ${formatAmount(remaining)}',
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Text(
                tr('transactions.title'),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: StreamBuilder<List<(TransactionEntity, BankEntity)>>(
                  stream: context.read<LoansCubit>().watchLoanTransactions(
                    loan.id,
                  ),
                  builder: (context, snapshot) {
                    final items = snapshot.data ?? [];
                    if (items.isNotEmpty) {
                      return ListView.separated(
                        controller: controller,
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 0),
                        itemBuilder: (context, index) {
                          final (trn, bank) = items[index];
                          final uMatch = usersState.users
                              .where((u) => u.id == trn.userId)
                              .toList();
                          final payer = uMatch.isNotEmpty
                              ? '${uMatch.first.firstName} ${uMatch.first.lastName}'
                              : tr('common.unknown_user');
                          return ListTile(
                            leading: BankCircleAvatar(
                              bankKey: bank.bankKey,
                              name:
                                  (context.locale.languageCode == 'fa'
                                      ? BankIcons.persianNames[bank.bankKey]
                                      : BankIcons.englishNames[bank.bankKey]) ??
                                  bank.bankKey,
                            ),
                            title: Text(payer),
                            subtitle: Text(
                              '${(isFa ? JalaliUtils.formatJalali(trn.createdAt) : JalaliUtils.formatGregorian(trn.createdAt))} · ${trn.type}',
                            ),
                            trailing: Text(formatAmount(trn.amount.abs())),
                          );
                        },
                      );
                    }
                    // Fallback: watch all transactions of the principal bank for this loan (legacy data without loan_id)
                    return FutureBuilder<int?>(
                      future: context
                          .read<LoansCubit>()
                          .getPrincipalBankIdForLoan(loan.id),
                      builder: (context, bankSnap) {
                        final bankId = bankSnap.data;
                        if (bankId == null) {
                          return Center(
                            child: Text(tr('transactions.not_found')),
                          );
                        }
                        final watchTx = locator<WatchTransactionsUseCase>();
                        return StreamBuilder<List<TransactionAggregate>>(
                          stream: watchTx(
                            TransactionsFilterEntity(bankId: bankId),
                          ),
                          builder: (context, bankTxSnap) {
                            final txs = bankTxSnap.data ?? [];
                            if (txs.isEmpty) {
                              return Center(
                                child: Text(tr('transactions.not_found')),
                              );
                            }
                            return ListView.separated(
                              controller: controller,
                              itemCount: txs.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 0),
                              itemBuilder: (context, index) {
                                final it = txs[index];
                                final bank = it.bank;
                                final trn = it.transaction;
                                final payer = it.user == null
                                    ? tr('common.unknown_user')
                                    : '${it.user!.firstName} ${it.user!.lastName}';
                                return ListTile(
                                  leading: BankCircleAvatar(
                                    bankKey: bank.bankKey,
                                    name:
                                        (context.locale.languageCode == 'fa'
                                            ? BankIcons.persianNames[bank
                                                  .bankKey]
                                            : BankIcons.englishNames[bank
                                                  .bankKey]) ??
                                        bank.bankKey,
                                  ),
                                  title: Text(payer),
                                  subtitle: Text(
                                    '${(isFa ? JalaliUtils.formatJalali(trn.createdAt) : JalaliUtils.formatGregorian(trn.createdAt))} · ${trn.type}',
                                  ),
                                  trailing: Text(
                                    formatAmount(trn.amount.abs()),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<void> _exportLoanReportPdf(BuildContext context, LoanEntity loan) async {
  final usersState = context.read<UsersCubit>().state;
  final user = usersState.users.firstWhere(
    (u) => u.id == loan.userId,
    orElse: () => usersState.users.first,
  );

  final loansCubit = context.read<LoansCubit>();
  final payments = await loansCubit.watchPayments(loan.id).first;

  // Load local Persian-capable fonts from assets/fonts/
  final baseFontData = await rootBundle.load(
    'assets/fonts/IRANYekanXFaNum-Regular.ttf',
  );
  final boldFontData = await rootBundle.load(
    'assets/fonts/IRANYekanXFaNum-Bold.ttf',
  );
  final baseFont = pw.Font.ttf(baseFontData.buffer.asByteData());
  final boldFont = pw.Font.ttf(boldFontData.buffer.asByteData());
  final doc = pw.Document();
  final dateFa = JalaliUtils.formatJalali(loan.createdAt);

  // payments may not be chronological; compute remaining oldest→newest
  final sortedPayments = [...payments]
    ..sort((a, b) {
      final byDate = a.$2.createdAt.compareTo(b.$2.createdAt);
      return byDate != 0 ? byDate : a.$2.id.compareTo(b.$2.id);
    });
  int remaining = loan.principalAmount;
  final Map<int, int> remainingByTxId = {};
  for (final e in sortedPayments) {
    remaining -= e.$1.amount.abs();
    remainingByTxId[e.$2.id] = remaining;
  }

  final hAmount = tr('transactions.amount');
  final hType = tr('transactions.type');
  final hLoanRem = tr('loans.remaining');
  final hDate = tr('transactions.date');
  final hUser = tr('loans.user');

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
                tr('loans.report_title'),
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('${user.firstName} ${user.lastName}'),
              pw.Text(
                '${tr('loans.principal')}: ${formatAmount(loan.principalAmount)}  ·  ${tr('loans.installments')}: ${loan.installments}',
              ),
              pw.Text('${tr('transactions.date')}: $dateFa'),
              pw.SizedBox(height: 12),
              pw.Text(
                tr('loans.payments'),
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              if (payments.isEmpty)
                pw.Text(tr('transactions.not_found'))
              else
                // Table columns paint LTR; last child is on the RIGHT.
                // Desired RTL visual: ردیف | مبلغ | نوع | باقیمانده وام | تاریخ | کاربر
                pw.Table(
                  border: pw.TableBorder.all(width: 0.5),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1.4),
                    1: const pw.FlexColumnWidth(1.2),
                    2: const pw.FlexColumnWidth(1.3),
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
                        pdfCellText(hUser, bold: true),
                        pdfCellText(hDate, bold: true),
                        pdfCellText(hLoanRem, bold: true),
                        pdfCellText(hType, bold: true),
                        pdfCellText(hAmount, bold: true),
                        pdfCellText(tr('transactions.row'), bold: true),
                      ],
                    ),
                    ...payments.asMap().entries.map((entry) {
                      final idx = entry.key + 1;
                      final (lp, trn, _) = entry.value;
                      final matches = usersState.users
                          .where((u) => u.id == trn.userId)
                          .toList();
                      final userName = matches.isNotEmpty
                          ? '${matches.first.firstName} ${matches.first.lastName}'
                          : tr('common.unknown_user');
                      final loanRem = remainingByTxId[trn.id] ?? 0;
                      return pw.TableRow(
                        children: [
                          pdfCellText(userName),
                          pdfCellText(JalaliUtils.formatJalali(trn.createdAt)),
                          pdfCellText(
                            formatAmount(loanRem),
                            underline: isLoanRelatedType(trn.type),
                          ),
                          pdfCellText(trn.type),
                          pdfCellText(
                            formatAmount(lp.amount.abs()),
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
  final file = File('${dir.path}/loan_${loan.id}_$ts.pdf');
  await file.writeAsBytes(await doc.save());
  try {
    await Share.shareXFiles([XFile(file.path)], text: tr('loans.report_title'));
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Share failed: $e')));
    }
  }
}

class _LoansView extends StatefulWidget {
  const _LoansView();
  @override
  State<_LoansView> createState() => _LoansViewState();
}

class _LoansViewState extends State<_LoansView> {
  int? _filterUserId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<LoansCubit, LoansState>(
          builder: (context, state) {
            if (state.loading)
              return const Center(child: CircularProgressIndicator());

            final filteredItems =
                (_filterUserId == null
                        ? state.items
                        : state.items
                              .where((e) => e.loan.userId == _filterUserId)
                              .toList())
                    .toList()
                  ..sort((a, b) {
                    if (a.settled == b.settled) return 0;
                    return a.settled ? 1 : -1;
                  });

            final usersState = context.watch<UsersCubit>().state;

            if (filteredItems.isEmpty) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: _UserFilterField(
                      value: _filterUserId,
                      onChanged: (v) => setState(() => _filterUserId = v),
                      onClear: () => setState(() => _filterUserId = null),
                    ),
                  ),
                  Expanded(
                    child: AppEmptyState(
                      message: tr('transactions.not_found'),
                      icon: AppIcons.loans,
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: _UserFilterField(
                    value: _filterUserId,
                    onChanged: (v) => setState(() => _filterUserId = v),
                    onClear: () => setState(() => _filterUserId = null),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                    itemCount: filteredItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final isFa = context.locale.languageCode == 'fa';
                      final it = filteredItems[index];
                      final us = usersState.users
                          .where((x) => x.id == it.loan.userId)
                          .toList();
                      final userName = us.isNotEmpty
                          ? '${us.first.firstName} ${us.first.lastName}'
                          : tr('common.unknown_user');
                      final dateStr = isFa
                          ? JalaliUtils.formatJalali(it.loan.createdAt)
                          : JalaliUtils.formatGregorian(it.loan.createdAt);
                      final progress = it.loan.principalAmount <= 0
                          ? 0.0
                          : (it.paidAmount / it.loan.principalAmount).clamp(
                              0.0,
                              1.0,
                            );
                      return AppSurface(
                        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                        radius: 18,
                        onLongPress: it.settled
                            ? null
                            : () => _openLoanSheet(context, loan: it.loan),
                        child: Row(
                          children: [
                            AppIconBadge(
                              icon: it.settled
                                  ? AppIcons.check
                                  : AppIcons.loansFilled,
                              color: it.settled
                                  ? AppColors.success
                                  : AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${formatAmount(it.loan.principalAmount)} · $dateStr',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.55),
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(99),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 6,
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.08),
                                      color: it.settled
                                          ? AppColors.success
                                          : AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${tr('loans.remaining')}: ${formatAmount(it.remaining)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: it.settled
                                              ? AppColors.success
                                              : AppColors.warning,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            _LoanActionsMenu(
                              settled: it.settled,
                              onPayInstallment: () async {
                                final user = usersState.users.firstWhere(
                                  (u) => u.id == it.loan.userId,
                                  orElse: () => usersState.users.first,
                                );
                                await showTransactionSheet(
                                  context,
                                  initialUserId: user.id,
                                  initialType: tr(
                                    'transactions.loan_installment',
                                  ),
                                  initialLoanId: it.loan.id,
                                );
                              },
                              onEdit: () =>
                                  _openLoanSheet(context, loan: it.loan),
                              onDelete: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(tr('loans.delete')),
                                    content: Text(tr('loans.confirm_delete')),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: Text(tr('common.cancel')),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: Text(tr('loans.delete')),
                                      ),
                                    ],
                                  ),
                                );
                                if (ok == true) {
                                  await context.read<LoansCubit>().deleteLoan(
                                    it.loan.id,
                                  );
                                }
                              },
                              onReport: () =>
                                  _openLoanReportSheet(context, it.loan),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openLoanSheet(context),
        icon: const Icon(AppIcons.add),
        label: Text(tr('loans.add')),
      ),
    );
  }
}

class _LoanAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const AppIconBadge(icon: AppIcons.loansFilled);
  }
}

class _LoanActionsMenu extends StatelessWidget {
  final bool settled;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPayInstallment;
  final VoidCallback onReport;
  const _LoanActionsMenu({
    required this.settled,
    required this.onEdit,
    required this.onDelete,
    required this.onPayInstallment,
    required this.onReport,
  });
  @override
  Widget build(BuildContext context) {
    if (settled) {
      return const IconButton(
        icon: Icon(AppIcons.check, color: AppColors.success),
        onPressed: null,
      );
    }
    return PopupMenuButton<String>(
      icon: const Icon(AppIcons.more),
      onSelected: (value) {
        if (value == 'pay') onPayInstallment();
        if (value == 'edit') onEdit();
        if (value == 'delete') onDelete();
        if (value == 'report') onReport();
      },
      itemBuilder: (ctx) => [
        PopupMenuItem<String>(
          value: 'pay',
          child: Text(tr('loans.add_payment')),
        ),
        PopupMenuItem<String>(value: 'edit', child: Text(tr('loans.edit'))),
        PopupMenuItem<String>(value: 'delete', child: Text(tr('loans.delete'))),
        PopupMenuItem<String>(value: 'report', child: Text(tr('loans.report'))),
      ],
    );
  }
}

class _AddPaymentRow extends StatefulWidget {
  final LoanEntity loan;
  const _AddPaymentRow({required this.loan});
  @override
  State<_AddPaymentRow> createState() => _AddPaymentRowState();
}

class _AddPaymentRowState extends State<_AddPaymentRow> {
  int? bankId;
  final amountCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  @override
  void dispose() {
    amountCtrl.dispose();
    noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _BankDropdown(
                value: bankId,
                onChanged: (v) => setState(() => bankId = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                decoration: InputDecoration(labelText: tr('loans.amount')),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: noteCtrl,
          decoration: InputDecoration(labelText: tr('loans.note')),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () async {
              final amount = _parseInt(amountCtrl.text);
              if (bankId != null && amount != null) {
                // Remaining guard: prevent paying more than remaining
                final loansState = context.read<LoansCubit>().state;
                final matches = loansState.items
                    .where((e) => e.loan.id == widget.loan.id)
                    .toList();
                final remaining = matches.isNotEmpty
                    ? matches.first.remaining
                    : widget.loan.principalAmount;
                if (amount > remaining) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          tr('loans.errors.payment_exceeds_remaining'),
                        ),
                      ),
                    );
                  }
                  return;
                }

                await context.read<LoansCubit>().addPayment(
                  loanId: widget.loan.id,
                  bankId: bankId!,
                  amount: amount,
                  note: noteCtrl.text.trim().isEmpty
                      ? null
                      : noteCtrl.text.trim(),
                );
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: Text(tr('loans.add_payment')),
          ),
        ),
      ],
    );
  }

  int? _parseInt(String? v) {
    if (v == null) return null;
    final digits = v.replaceAll(',', '');
    return int.tryParse(digits);
  }
}

class _BankDropdown extends StatelessWidget {
  final int? value;
  final ValueChanged<int?> onChanged;
  const _BankDropdown({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BanksCubit, BanksState>(
      builder: (context, state) {
        return DropdownButtonFormField<int>(
          isExpanded: true,
          initialValue: value,
          items: state.banks
              .map(
                (e) => DropdownMenuItem(
                  value: e.bank.id,
                  child: Text(
                    '${(context.locale.languageCode == 'fa' ? (BankIcons.persianNames[e.bank.bankKey] ?? e.bank.bankKey) : (BankIcons.englishNames[e.bank.bankKey] ?? e.bank.bankKey))} · ${e.bank.accountName}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(labelText: tr('banks.bank')),
        );
      },
    );
  }
}

Future<void> _openLoanSheet(BuildContext context, {LoanEntity? loan}) async {
  await showAppModalSheet(
    context: context,
    builder: (sheetContext) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.read<LoansCubit>()),
        BlocProvider.value(value: context.read<UsersCubit>()),
        BlocProvider.value(value: context.read<BanksCubit>()),
      ],
      child: _LoanSheet(loan: loan),
    ),
  );
}

class _LoanSheet extends StatefulWidget {
  final LoanEntity? loan;
  const _LoanSheet({this.loan});
  @override
  State<_LoanSheet> createState() => _LoanSheetState();
}

class _LoanSheetState extends State<_LoanSheet> {
  final _formKey = GlobalKey<FormState>();
  int? userId;
  int? bankId;
  final principalCtrl = TextEditingController();
  final installmentsCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  @override
  void initState() {
    super.initState();
    if (widget.loan != null) {
      userId = widget.loan!.userId;
      principalCtrl.text = widget.loan!.principalAmount.toString();
      installmentsCtrl.text = widget.loan!.installments.toString();
      noteCtrl.text = widget.loan!.note ?? '';
    }
  }

  @override
  void dispose() {
    principalCtrl.dispose();
    installmentsCtrl.dispose();
    noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.loan != null;
    return AppSheetBody(
      title: isEdit ? tr('loans.edit') : tr('loans.add'),
      icon: AppIcons.loansFilled,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
              _SearchableUserField(
                value: userId,
                onChanged: (v) => setState(() => userId = v),
              ),
              const SizedBox(height: 12),
              _BankDropdown(
                value: bankId,
                onChanged: (v) => setState(() => bankId = v),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: principalCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [ThousandsSeparatorInputFormatter()],
                      decoration: InputDecoration(
                        labelText: tr('loans.principal'),
                      ),
                      validator: (v) =>
                          (_parseInt(v) == null) ? 'الزامی' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: installmentsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: tr('loans.installments'),
                      ),
                      validator: (v) =>
                          (int.tryParse(v ?? '') == null) ? 'الزامی' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: noteCtrl,
                decoration: InputDecoration(labelText: tr('loans.note')),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate() && userId != null) {
                      final c = context.read<LoansCubit>();
                      final principal = _parseInt(principalCtrl.text)!;
                      final inst = int.parse(installmentsCtrl.text);
                      if (isEdit) {
                        await c.updateLoan(
                          id: widget.loan!.id,
                          userId: userId!,
                          principalAmount: principal,
                          installments: inst,
                          note: noteCtrl.text.trim().isEmpty
                              ? null
                              : noteCtrl.text.trim(),
                        );
                      } else {
                        if (bankId == null) return;
                        // Check bank balance before creating the loan & withdraw transaction
                        final banksState = context.read<BanksCubit>().state;
                        final match = banksState.banks.where(
                          (b) => b.bank.id == bankId,
                        );
                        final currentBalance = match.isNotEmpty
                            ? match.first.balance
                            : 0;
                        if (principal > currentBalance) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  tr(
                                    'loans.errors.principal_exceeds_bank_balance',
                                  ),
                                ),
                              ),
                            );
                          }
                          return;
                        }
                        await c.addLoan(
                          userId: userId!,
                          bankId: bankId!,
                          principalAmount: principal,
                          installments: inst,
                          note: noteCtrl.text.trim().isEmpty
                              ? null
                              : noteCtrl.text.trim(),
                        );
                      }
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: Text(isEdit ? tr('loans.save') : tr('loans.create')),
                ),
              ),
            ],
          ),
        ),
    );
  }

  int? _parseInt(String? v) {
    if (v == null) return null;
    final digits = v.replaceAll(',', '');
    return int.tryParse(digits);
  }
}

// removed old unused dropdown

class _SearchableUserField extends StatelessWidget {
  final int? value;
  final ValueChanged<int?> onChanged;
  const _SearchableUserField({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UsersCubit, UsersState>(
      builder: (context, state) {
        String label = tr('loans.user');
        final sel = state.users.where((u) => u.id == value).toList();
        if (sel.isNotEmpty)
          label = '${sel.first.firstName} ${sel.first.lastName}';
        return TextFormField(
          readOnly: true,
          decoration: InputDecoration(
            labelText: tr('loans.user'),
            hintText: label,
            suffixIcon: const Icon(AppIcons.search),
          ),
          onTap: () async {
            final picked = await _showLoanUserPicker(context, state);
            if (picked != null) onChanged(picked);
          },
        );
      },
    );
  }
}

class _UserFilterField extends StatelessWidget {
  final int? value;
  final ValueChanged<int?> onChanged;
  final VoidCallback onClear;
  const _UserFilterField({
    required this.value,
    required this.onChanged,
    required this.onClear,
  });
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UsersCubit, UsersState>(
      builder: (context, state) {
        String hint = tr('transactions.search_user');
        if (value != null) {
          final sel = state.users.where((u) => u.id == value).toList();
          if (sel.isNotEmpty)
            hint = '${sel.first.firstName} ${sel.first.lastName}';
        }
        return TextField(
          readOnly: true,
          decoration: InputDecoration(
            labelText: tr('transactions.search_user'),
            hintText: hint,
            suffixIcon: value == null
                ? const Icon(AppIcons.search)
                : IconButton(icon: const Icon(AppIcons.clear), onPressed: onClear),
          ),
          onTap: () async {
            final picked = await _showLoanUserPicker(context, state);
            if (picked != null) onChanged(picked);
          },
        );
      },
    );
  }
}

Future<int?> _showLoanUserPicker(BuildContext context, UsersState state) async {
  final controller = TextEditingController();
  List<int> filtered = state.users.map((e) => e.id).toList();
  return showAppModalSheet<int>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setStateSB) {
          void apply(String q) {
            setStateSB(() {
              final pat = q.trim();
              filtered = state.users
                  .where((u) => '${u.firstName} ${u.lastName}'.contains(pat))
                  .map((e) => e.id)
                  .toList();
            });
          }

          return AppSheetBody(
            title: tr('transactions.search_user'),
            icon: AppIcons.userSearch,
            scrollable: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: tr('transactions.search_user'),
                    prefixIcon: const Icon(AppIcons.search),
                  ),
                  onChanged: apply,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 320,
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final id = filtered[index];
                      final u = state.users.firstWhere((e) => e.id == id);
                      return AppSurface(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        radius: 14,
                        onTap: () => Navigator.pop(context, id),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.12,
                            ),
                            foregroundColor: AppColors.primary,
                            child: Text(
                              '${u.firstName.isNotEmpty ? u.firstName[0] : ''}${u.lastName.isNotEmpty ? u.lastName[0] : ''}',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          title: Text('${u.firstName} ${u.lastName}'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
