import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../data/local/db/app_database.dart';
import '../../di/locator.dart';
import '../cubits/loans_cubit.dart';
import '../cubits/users_cubit.dart';
import '../cubits/banks_cubit.dart';
import '../../app/utils/bank_icons.dart';
import '../../app/utils/format.dart';
import '../../app/utils/jalali_utils.dart';
import '../../app/utils/thousands_input_formatter.dart';
import 'transactions_page.dart' show showTransactionSheet;

class LoansPage extends StatelessWidget {
  const LoansPage({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => LoansCubit(locator())..watch()),
        BlocProvider(create: (_) => UsersCubit(locator())..watch()),
        BlocProvider(create: (_) => BanksCubit(locator())..watch()),
      ],
      child: const _LoansView(),
    );
  }
}

class _LoansView extends StatelessWidget {
  const _LoansView();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<LoansCubit, LoansState>(
          builder: (context, state) {
            if (state.loading)
              return const Center(child: CircularProgressIndicator());
            if (state.items.isEmpty)
              return Center(child: Text(tr('transactions.not_found')));
            return ListView.separated(
              itemCount: state.items.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (context, index) {
                final it = state.items[index];
                final usersState = context.read<UsersCubit>().state;
                final us = usersState.users
                    .where((x) => x.id == it.loan.userId)
                    .toList();
                final userName = us.isNotEmpty
                    ? '${us.first.firstName} ${us.first.lastName}'
                    : 'کاربر نامشخص';
                final dateFa = JalaliUtils.formatJalali(it.loan.createdAt);
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
                      final usersState = context.read<UsersCubit>().state;
                      final user = usersState.users.firstWhere(
                        (u) => u.id == it.loan.userId,
                        orElse: () => usersState.users.first,
                      );
                      await showTransactionSheet(
                        context,
                        initialUserId: user.id,
                        initialType: 'پرداخت قسط وام',
                        initialLoanId: it.loan.id,
                      );
                    },
                    onEdit: () => _openLoanSheet(context, loan: it.loan),
                    onDelete: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('حذف وام'),
                          content: const Text(
                            'آیا از حذف این وام مطمئن هستید؟ این کار تمام اقساط و تراکنش‌های مرتبط را نیز حذف می‌کند.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('انصراف'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('حذف'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) {
                        await context.read<LoansCubit>().deleteLoan(it.loan.id);
                      }
                    },
                  ),
                  onTap: () => _openLoanDetails(context, it.loan),
                  onLongPress: () => _openLoanSheet(context, loan: it.loan),
                );
              },
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
  const _LoanActionsMenu({
    required this.settled,
    required this.onEdit,
    required this.onDelete,
    required this.onPayInstallment,
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
      },
      itemBuilder: (ctx) => const [
        PopupMenuItem<String>(value: 'pay', child: Text('پرداخت قسط')),
        PopupMenuItem<String>(value: 'edit', child: Text('ویرایش')),
        PopupMenuItem<String>(value: 'delete', child: Text('حذف')),
      ],
    );
  }
}

Future<void> _openLoanDetails(BuildContext context, Loan loan) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.read<LoansCubit>()),
        BlocProvider.value(value: context.read<UsersCubit>()),
        BlocProvider.value(value: context.read<BanksCubit>()),
      ],
      child: _LoanDetailsSheet(loan: loan),
    ),
  );
}

class _LoanDetailsSheet extends StatelessWidget {
  final Loan loan;
  const _LoanDetailsSheet({required this.loan});
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LoansCubit>();
    return Padding(
      padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tr('loans.payments'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<(LoanPayment, Transaction, Bank)>>(
            stream: cubit.watchPayments(loan.id),
            builder: (context, snapshot) {
              final items = snapshot.data ?? [];
              if (items.isEmpty)
                return Center(child: Text(tr('transactions.not_found')));
              return SizedBox(
                height: 300,
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 0),
                  itemBuilder: (context, index) {
                    final (lp, trn, bank) = items[index];
                    return ListTile(
                      leading: BankCircleAvatar(
                        bankKey: bank.bankKey,
                        name:
                            BankIcons.persianNames[bank.bankKey] ??
                            bank.bankKey,
                      ),
                      title: Text(
                        '${BankIcons.persianNames[bank.bankKey] ?? bank.bankKey} · ${bank.accountName}',
                      ),
                      subtitle: Text(trn.note ?? ''),
                      trailing: Text(formatThousands(lp.amount)),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _AddPaymentRow(loan: loan),
        ],
      ),
    );
  }
}

class _AddPaymentRow extends StatefulWidget {
  final Loan loan;
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
                      const SnackBar(
                        content: Text('مبلغ پرداختی از باقیمانده بیشتر است'),
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

Future<void> _openLoanSheet(BuildContext context, {Loan? loan}) async {
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
  final Loan? loan;
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
                              const SnackBar(
                                content: Text(
                                  'مبلغ درخواست از موجودی بانک بیشتر است',
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
