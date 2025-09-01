import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../data/local/db/app_database.dart';
import '../../di/locator.dart';
import '../cubits/loans_cubit.dart';
import '../cubits/users_cubit.dart';
import '../cubits/banks_cubit.dart';

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
            if (state.loading) return const Center(child: CircularProgressIndicator());
            if (state.items.isEmpty) return Center(child: Text(tr('transactions.not_found')));
            return ListView.separated(
              itemCount: state.items.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (context, index) {
                final it = state.items[index];
                return ListTile(
                  title: Text('ID ${it.loan.id} · ${it.loan.principalAmount}'),
                  subtitle: Text('${tr('loans.remaining')}: ${it.remaining}'),
                  trailing: Icon(it.settled ? Icons.check_circle : Icons.pending, color: it.settled ? Colors.green : Colors.orange),
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

Future<void> _openLoanDetails(BuildContext context, Loan loan) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _LoanDetailsSheet(loan: loan),
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
          Text(tr('loans.payments'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          StreamBuilder<List<(LoanPayment, Transaction, Bank)>>(
            stream: cubit.watchPayments(loan.id),
            builder: (context, snapshot) {
              final items = snapshot.data ?? [];
              if (items.isEmpty) return Center(child: Text(tr('transactions.not_found')));
              return SizedBox(
                height: 300,
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 0),
                  itemBuilder: (context, index) {
                    final (lp, trn, bank) = items[index];
                    return ListTile(
                      title: Text('${bank.bankName} · ${bank.accountName}'),
                      subtitle: Text(trn.note ?? ''),
                      trailing: Text(lp.amount.toString()),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _AddPaymentRow(loanId: loan.id),
        ],
      ),
    );
  }
}

class _AddPaymentRow extends StatefulWidget {
  final int loanId;
  const _AddPaymentRow({required this.loanId});
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
        Row(children: [
          Expanded(child: _BankDropdown(value: bankId, onChanged: (v) => setState(() => bankId = v))),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: tr('loans.amount')),
            ),
          ),
        ]),
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
              final amount = int.tryParse(amountCtrl.text);
              if (bankId != null && amount != null) {
                await context.read<LoansCubit>().addPayment(
                      loanId: widget.loanId,
                      bankId: bankId!,
                      amount: amount,
                      note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
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
}

class _BankDropdown extends StatelessWidget {
  final int? value;
  final ValueChanged<int?> onChanged;
  const _BankDropdown({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BanksCubit, BanksState>(builder: (context, state) {
      return DropdownButtonFormField<int>(
        value: value,
        items: state.banks.map((e) => DropdownMenuItem(value: e.bank.id, child: Text('${e.bank.bankName} · ${e.bank.accountName}'))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(labelText: tr('banks.bank')),
      );
    });
  }
}

Future<void> _openLoanSheet(BuildContext context, {Loan? loan}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _LoanSheet(loan: loan),
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
    final padding = MediaQuery.of(context).viewInsets + const EdgeInsets.all(16);
    return Padding(
      padding: padding,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isEdit ? tr('loans.edit') : tr('loans.add'), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _UserDropdown(value: userId, onChanged: (v) => setState(() => userId = v)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: principalCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: tr('loans.principal')),
                  validator: (v) => (int.tryParse(v ?? '') == null) ? 'الزامی' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: installmentsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: tr('loans.installments')),
                  validator: (v) => (int.tryParse(v ?? '') == null) ? 'الزامی' : null,
                ),
              ),
            ]),
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
                    final principal = int.parse(principalCtrl.text);
                    final inst = int.parse(installmentsCtrl.text);
                    if (isEdit) {
                      await c.updateLoan(
                        id: widget.loan!.id,
                        userId: userId!,
                        principalAmount: principal,
                        installments: inst,
                        note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                      );
                    } else {
                      await c.addLoan(
                        userId: userId!,
                        principalAmount: principal,
                        installments: inst,
                        note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
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
    );
  }
}

class _UserDropdown extends StatelessWidget {
  final int? value;
  final ValueChanged<int?> onChanged;
  const _UserDropdown({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UsersCubit, UsersState>(builder: (context, state) {
      return DropdownButtonFormField<int>(
        value: value,
        items: state.users.map((u) => DropdownMenuItem(value: u.id, child: Text('${u.firstName} ${u.lastName}'))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(labelText: tr('loans.user')),
      );
    });
  }
}


