import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../di/locator.dart';
import '../cubits/transactions_cubit.dart';
import '../cubits/banks_cubit.dart';
import '../cubits/users_cubit.dart';
import '../../data/repositories/transactions_repository.dart';
import '../../app/utils/bank_icons.dart';
import '../../app/utils/jalali_utils.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => TransactionsCubit(locator())..watch()),
        BlocProvider(create: (_) => BanksCubit(locator())..watch()),
        BlocProvider(create: (_) => UsersCubit(locator())..watch()),
      ],
      child: const _TransactionsView(),
    );
  }
}

class _TransactionsView extends StatelessWidget {
  const _TransactionsView();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _FiltersBar(),
            Expanded(
              child: BlocBuilder<TransactionsCubit, TransactionsState>(
                builder: (context, state) {
                  if (state.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.items.isEmpty) {
                    return Center(child: Text(tr('transactions.not_found')));
                  }
                  return ListView.separated(
                    itemCount: state.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (context, index) {
                      final it = state.items[index];
                      final trn = it.transaction;
                      final isDeposit = trn.type == 'deposit';
                      return ListTile(
                        leading: BankCircleAvatar(
                          bankKey: it.bank.bankKey,
                          name: it.bank.bankName,
                        ),
                        title: Text(
                          it.user != null
                              ? '${it.user!.firstName} ${it.user!.lastName}'
                              : it.bank.bankName,
                        ),
                        subtitle: Text(
                          '${it.bank.accountName} · ${JalaliUtils.formatJalali(trn.createdAt)}',
                        ),
                        trailing: Text(
                          _formatCurrency(trn.amount),
                          style: TextStyle(
                            color: isDeposit ? Colors.green : Colors.red,
                          ),
                        ),
                        onTap: () => _openTransactionSheet(context, data: it),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openTransactionSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatCurrency(int v) {
    final s = v.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idx = s.length - i - 1;
      buf.write(s[idx]);
      if (i % 3 == 2 && idx != 0) buf.write(',');
    }
    final str = buf.toString().split('').reversed.join();
    return (v < 0 ? '-' : '') + str;
  }
}

class _FiltersBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TransactionsCubit>();
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          DropdownButton<String>(
            value: cubit.state.filter.type,
            hint: Text(tr('transactions.type')),
            items: [
              DropdownMenuItem(
                value: 'deposit',
                child: Text(tr('transactions.deposit')),
              ),
              DropdownMenuItem(
                value: 'withdraw',
                child: Text(tr('transactions.withdraw')),
              ),
            ],
            onChanged: (v) {
              cubit.updateFilter(
                TransactionsFilter(
                  from: cubit.state.filter.from,
                  to: cubit.state.filter.to,
                  type: v,
                  userId: cubit.state.filter.userId,
                  bankId: cubit.state.filter.bankId,
                ),
              );
            },
          ),
          _BankPicker(),
          _UserPicker(),
          _DateRangePicker(),
        ],
      ),
    );
  }
}

class _BankPicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BanksCubit, BanksState>(
      builder: (context, state) {
        final items = state.banks
            .map(
              (e) => DropdownMenuItem(
                value: e.bank.id,
                child: Text('${e.bank.bankName} · ${e.bank.accountName}'),
              ),
            )
            .toList();
        final sel = context.read<TransactionsCubit>().state.filter.bankId;
        return DropdownButton<int>(
          value: sel,
          hint: Text(tr('transactions.search_bank')),
          items: items,
          onChanged: (v) {
            final c = context.read<TransactionsCubit>();
            c.updateFilter(
              TransactionsFilter(
                from: c.state.filter.from,
                to: c.state.filter.to,
                type: c.state.filter.type,
                userId: c.state.filter.userId,
                bankId: v,
              ),
            );
          },
        );
      },
    );
  }
}

class _UserPicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UsersCubit, UsersState>(
      builder: (context, state) {
        final items = state.users
            .map(
              (u) => DropdownMenuItem(
                value: u.id,
                child: Text('${u.firstName} ${u.lastName}'),
              ),
            )
            .toList();
        final sel = context.read<TransactionsCubit>().state.filter.userId;
        return DropdownButton<int>(
          value: sel,
          hint: Text(tr('transactions.search_user')),
          items: items,
          onChanged: (v) {
            final c = context.read<TransactionsCubit>();
            c.updateFilter(
              TransactionsFilter(
                from: c.state.filter.from,
                to: c.state.filter.to,
                type: c.state.filter.type,
                userId: v,
                bankId: c.state.filter.bankId,
              ),
            );
          },
        );
      },
    );
  }
}

class _DateRangePicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final f = context.watch<TransactionsCubit>().state.filter;
    String label;
    if (f.from != null && f.to != null) {
      label =
          '${JalaliUtils.formatJalali(f.from!)} تا ${JalaliUtils.formatJalali(f.to!)}';
    } else {
      label = 'تاریخ';
    }
    return OutlinedButton.icon(
      icon: const Icon(Icons.date_range),
      label: Text(label),
      onPressed: () async {
        final now = DateTime.now();
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(now.year - 5),
          lastDate: DateTime(now.year + 1),
          helpText: 'انتخاب بازه تاریخ (میلادی)',
        );
        if (picked != null) {
          final c = context.read<TransactionsCubit>();
          c.updateFilter(
            TransactionsFilter(
              from: picked.start,
              to: picked.end,
              type: c.state.filter.type,
              userId: c.state.filter.userId,
              bankId: c.state.filter.bankId,
            ),
          );
        }
      },
    );
  }
}

Future<void> _openTransactionSheet(
  BuildContext context, {
  TransactionWithJoins? data,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _TransactionSheet(data: data),
  );
}

class _TransactionSheet extends StatefulWidget {
  final TransactionWithJoins? data;
  const _TransactionSheet({this.data});
  @override
  State<_TransactionSheet> createState() => _TransactionSheetState();
}

class _TransactionSheetState extends State<_TransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  int? bankId;
  int? userId;
  String type = 'deposit';
  String? depositKind;
  String? withdrawKind;
  final amountCtrl = TextEditingController();
  final noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    if (d != null) {
      bankId = d.bank.id;
      userId = d.user?.id;
      type = d.transaction.type;
      depositKind = d.transaction.depositKind;
      withdrawKind = d.transaction.withdrawKind;
      amountCtrl.text = d.transaction.amount.toString();
      noteCtrl.text = d.transaction.note ?? '';
    }
  }

  @override
  void dispose() {
    amountCtrl.dispose();
    noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.data != null;
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
              isEdit ? tr('transactions.save') : tr('transactions.create'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SearchableBankField(
                    value: bankId,
                    onChanged: (v) => setState(() => bankId = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SearchableUserField(
                    value: userId,
                    onChanged: (v) => setState(() => userId = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: type,
                    items: [
                      DropdownMenuItem(
                        value: 'deposit',
                        child: Text(tr('transactions.deposit')),
                      ),
                      DropdownMenuItem(
                        value: 'withdraw',
                        child: Text(tr('transactions.withdraw')),
                      ),
                    ],
                    onChanged: (v) => setState(() => type = v ?? 'deposit'),
                    decoration: InputDecoration(
                      labelText: tr('transactions.type'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: tr('transactions.amount'),
                    ),
                    validator: (v) =>
                        (int.tryParse(v ?? '') == null) ? 'الزامی' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (type == 'deposit')
              TextFormField(
                initialValue: depositKind,
                onChanged: (v) => depositKind = v,
                decoration: InputDecoration(
                  labelText: tr('transactions.deposit_kind'),
                ),
              ),
            if (type == 'withdraw')
              TextFormField(
                initialValue: withdrawKind,
                onChanged: (v) => withdrawKind = v,
                decoration: InputDecoration(
                  labelText: tr('transactions.withdraw_kind'),
                ),
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: noteCtrl,
              decoration: InputDecoration(labelText: tr('transactions.note')),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate() && bankId != null) {
                    final c = context.read<TransactionsCubit>();
                    final amount = int.parse(amountCtrl.text);
                    if (isEdit) {
                      await c.update(
                        id: widget.data!.transaction.id,
                        bankId: bankId!,
                        userId: userId,
                        amount: amount,
                        type: type,
                        depositKind: depositKind,
                        withdrawKind: withdrawKind,
                        note: noteCtrl.text.trim().isEmpty
                            ? null
                            : noteCtrl.text.trim(),
                      );
                    } else {
                      await c.add(
                        bankId: bankId!,
                        userId: userId,
                        amount: amount,
                        type: type,
                        depositKind: depositKind,
                        withdrawKind: withdrawKind,
                        note: noteCtrl.text.trim().isEmpty
                            ? null
                            : noteCtrl.text.trim(),
                      );
                    }
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                child: Text(
                  isEdit ? tr('transactions.save') : tr('transactions.create'),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _SearchableBankField extends StatelessWidget {
  final int? value;
  final ValueChanged<int?> onChanged;
  const _SearchableBankField({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BanksCubit, BanksState>(
      builder: (context, state) {
        String label = tr('banks.bank');
        final selected = state.banks.firstWhere(
          (e) => e.bank.id == value,
          orElse: () => state.banks.isEmpty ? (throw '') : state.banks.first,
        );
        if (value != null &&
            state.banks.isNotEmpty &&
            selected.bank.id == value) {
          label = '${selected.bank.bankName} · ${selected.bank.accountName}';
        }
        return TextFormField(
          readOnly: true,
          decoration: InputDecoration(
            labelText: tr('banks.bank'),
            hintText: label,
            suffixIcon: const Icon(Icons.search),
          ),
          onTap: () async {
            final picked = await _showBankPicker(context, state);
            if (picked != null) onChanged(picked);
          },
        );
      },
    );
  }
}

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
            final picked = await _showUserPicker(context, state);
            if (picked != null) onChanged(picked);
          },
        );
      },
    );
  }
}

Future<int?> _showBankPicker(BuildContext context, BanksState state) async {
  final controller = TextEditingController();
  List<int> filtered = state.banks.map((e) => e.bank.id).toList();
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
                filtered = state.banks
                    .where(
                      (b) => '${b.bank.bankName} ${b.bank.accountName}'
                          .contains(pat),
                    )
                    .map((e) => e.bank.id)
                    .toList();
              });
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: tr('transactions.search_bank'),
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
                      final b = state.banks.firstWhere((e) => e.bank.id == id);
                      return ListTile(
                        title: Text(
                          '${b.bank.bankName} · ${b.bank.accountName}',
                        ),
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

Future<int?> _showUserPicker(BuildContext context, UsersState state) async {
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
