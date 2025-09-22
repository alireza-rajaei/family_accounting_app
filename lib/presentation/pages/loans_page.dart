import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../domain/entities/loan.dart';
import '../../di/locator.dart';
import '../cubits/loans_cubit.dart';
import '../cubits/users_cubit.dart';
import '../cubits/banks_cubit.dart';
import '../../app/utils/bank_icons.dart';
import '../../app/utils/format.dart';
import '../../app/utils/jalali_utils.dart';
import '../../app/utils/thousands_input_formatter.dart';
import 'transactions_page.dart' show showTransactionSheet;
import '../../domain/entities/transaction.dart';
import '../../domain/entities/bank.dart';
import '../../domain/usecases/transactions_usecases.dart';
import '../../domain/entities/user.dart';
 
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
// Using custom TTF fonts from assets instead of google fonts package
import 'package:flutter/services.dart' show rootBundle;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class LoansPage extends StatelessWidget {
  const LoansPage({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => LoansCubit(
          locator(),
          locator(),
          locator(),
          locator(),
          locator(),
          locator(),
          locator(),
          locator(),
        )..watch()),
        BlocProvider(create: (_) => UsersCubit(
          locator(),
          locator(),
          locator(),
          locator(),
          locator(),
        )..watch()),
        BlocProvider(create: (_) => BanksCubit(
          locator(),
          locator(),
          locator(),
          locator(),
        )..watch()),
      ],
      child: const _LoansView(),
    );
  }
}

Future<void> _openLoanReportSheet(BuildContext context, LoanEntity loan) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
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

    final dateFa = JalaliUtils.formatJalali(loan.createdAt);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, controller) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('loans.report_title'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _LoanAvatar(),
                title: Text('${user.firstName} ${user.lastName}'),
                subtitle: Text(
                  '${tr('loans.principal')}: ${formatThousands(loan.principalAmount)} · ${tr('loans.installments')}: ${loan.installments}',
                ),
                trailing: Text(dateFa),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: () => _exportLoanReportPdf(context, loan),
                  icon: const Icon(Icons.picture_as_pdf),
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
                      '${tr('loans.remaining')}: ${formatThousands(remaining)} ${tr('banks.rial')}',
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
                  stream: context.read<LoansCubit>().watchLoanTransactions(loan.id),
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
                                  BankIcons.persianNames[bank.bankKey] ??
                                  bank.bankKey,
                            ),
                            title: Text(payer),
                            subtitle: Text(
                              '${JalaliUtils.formatJalali(trn.createdAt)} · ${trn.type}',
                            ),
                            trailing: Text(formatThousands(trn.amount.abs())),
                          );
                        },
                      );
                    }
                    // Fallback: watch all transactions of the principal bank for this loan (legacy data without loan_id)
                    return FutureBuilder<int?>(
                      future: context.read<LoansCubit>().getPrincipalBankIdForLoan(loan.id),
                      builder: (context, bankSnap) {
                        final bankId = bankSnap.data;
                        if (bankId == null) {
                          return Center(
                            child: Text(tr('transactions.not_found')),
                          );
                        }
                        final watchTx = locator<WatchTransactionsUseCase>();
                        return StreamBuilder<List<TransactionAggregate>>(
                          stream: watchTx(TransactionsFilterEntity(bankId: bankId)),
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
                                        BankIcons.persianNames[bank.bankKey] ??
                                        bank.bankKey,
                                  ),
                                  title: Text(payer),
                                  subtitle: Text(
                                    '${JalaliUtils.formatJalali(trn.createdAt)} · ${trn.type}',
                                  ),
                                  trailing: Text(
                                    formatThousands(trn.amount.abs()),
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
    'assets/fonts/Vazirmatn-Regular.ttf',
  );
  final boldFontData = await rootBundle.load('assets/fonts/Vazirmatn-Bold.ttf');
  final baseFont = pw.Font.ttf(baseFontData.buffer.asByteData());
  final boldFont = pw.Font.ttf(boldFontData.buffer.asByteData());
  final doc = pw.Document();
  final dateFa = JalaliUtils.formatJalali(loan.createdAt);
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
                '${tr('loans.principal')}: ${formatThousands(loan.principalAmount)}  ·  ${tr('loans.installments')}: ${loan.installments}',
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
                pw.Table.fromTextArray(
                  headers: [
                    tr('transactions.date'),
                    tr('transactions.type'),
                    tr('transactions.amount'),
                    tr('loans.user'),
                  ],
                  cellAlignments: {
                    0: pw.Alignment.centerRight,
                    1: pw.Alignment.centerRight,
                    2: pw.Alignment.centerRight,
                    3: pw.Alignment.centerRight,
                  },
                  data: payments.map((e) {
                    final (lp, trn, bank) = e;
                    final matches = usersState.users
                        .where((u) => u.id == trn.userId)
                        .toList();
                    final userName = matches.isNotEmpty
                        ? '${matches.first.firstName} ${matches.first.lastName}'
                        : tr('common.unknown_user');
                    return [
                      JalaliUtils.formatJalali(trn.createdAt),
                      trn.type,
                      formatThousands(lp.amount),
                      userName,
                    ];
                  }).toList(),
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

            final filteredItems = _filterUserId == null
                ? state.items
                : state.items
                      .where((e) => e.loan.userId == _filterUserId)
                      .toList();

            final usersState = context.watch<UsersCubit>().state;

            if (filteredItems.isEmpty)
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: _UserFilterField(
                      value: _filterUserId,
                      onChanged: (v) => setState(() => _filterUserId = v),
                      onClear: () => setState(() => _filterUserId = null),
                    ),
                  ),
                  Expanded(
                    child: Center(child: Text(tr('transactions.not_found'))),
                  ),
                ],
              );

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: _UserFilterField(
                    value: _filterUserId,
                    onChanged: (v) => setState(() => _filterUserId = v),
                    onClear: () => setState(() => _filterUserId = null),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: filteredItems.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (context, index) {
                      final it = filteredItems[index];
                      final us = usersState.users
                          .where((x) => x.id == it.loan.userId)
                          .toList();
                      final userName = us.isNotEmpty
                          ? '${us.first.firstName} ${us.first.lastName}'
                          : tr('common.unknown_user');
                      final dateFa = JalaliUtils.formatJalali(
                        it.loan.createdAt,
                      );
                      return ListTile(
                        leading: _LoanAvatar(),
                        title: Text(
                          '$userName · ${formatThousands(it.loan.principalAmount)}',
                        ),
                        subtitle: Text(
                          '${dateFa} · ${tr('loans.remaining')}: ${formatThousands(it.remaining)} ${tr('banks.rial')}',
                        ),
                        trailing: _LoanActionsMenu(
                          settled: it.settled,
                          onPayInstallment: () async {
                            final user = usersState.users.firstWhere(
                              (u) => u.id == it.loan.userId,
                              orElse: () => usersState.users.first,
                            );
                            await showTransactionSheet(
                              context,
                              initialUserId: user.id,
                              initialType: tr('transactions.loan_installment'),
                              initialLoanId: it.loan.id,
                            );
                          },
                          onEdit: () => _openLoanSheet(context, loan: it.loan),
                          onDelete: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(tr('loans.delete')),
                                content: Text('${tr('loans.confirm_delete')}'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: Text(tr('common.cancel')),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
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
                        // Click on loan disabled per request
                        onLongPress: () =>
                            _openLoanSheet(context, loan: it.loan),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openLoanSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _LoanAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.primary.withOpacity(0.12),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.request_quote_rounded, color: scheme.primary, size: 22),
    );
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
    return PopupMenuButton<String>(
      icon: Icon(
        settled ? Icons.check_circle : Icons.more_vert,
        color: settled ? Colors.green : null,
      ),
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
          value: value,
          items: state.banks
              .map(
                (e) => DropdownMenuItem(
                  value: e.bank.id,
                  child: Text(
                    '${BankIcons.persianNames[e.bank.bankKey] ?? e.bank.bankKey} · ${e.bank.accountName}',
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
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
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
    final padding =
        MediaQuery.of(context).viewInsets + const EdgeInsets.all(16);
    return Padding(
      padding: padding,
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEdit ? tr('loans.edit') : tr('loans.add'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 12),
            ],
          ),
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
            suffixIcon: const Icon(Icons.search),
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
                ? const Icon(Icons.search)
                : IconButton(icon: const Icon(Icons.clear), onPressed: onClear),
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
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: StatefulBuilder(
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

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: tr('transactions.search_user'),
                  ),
                  onChanged: apply,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 320,
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final id = filtered[index];
                      final u = state.users.firstWhere((e) => e.id == id);
                      return ListTile(
                        title: Text('${u.firstName} ${u.lastName}'),
                        onTap: () => Navigator.pop(context, id),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}
