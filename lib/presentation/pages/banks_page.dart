import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../di/locator.dart';
import '../../data/local/db/app_database.dart';
import '../cubits/banks_cubit.dart';

class BanksPage extends StatelessWidget {
  const BanksPage({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BanksCubit(locator())..watch(),
      child: const _BanksView(),
    );
  }
}

class _BanksView extends StatefulWidget {
  const _BanksView();
  @override
  State<_BanksView> createState() => _BanksViewState();
}

class _BanksViewState extends State<_BanksView> {
  final TextEditingController _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BanksCubit>();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: tr('banks.search_hint'),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _search.clear();
                            cubit.watch('');
                            setState(() {});
                          },
                        ),
                ),
                onChanged: (v) {
                  cubit.watch(v);
                  setState(() {});
                },
              ),
            ),
            Expanded(
              child: BlocBuilder<BanksCubit, BanksState>(
                builder: (context, state) {
                  if (state.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.banks.isEmpty) {
                    return Center(child: Text(tr('banks.not_found')));
                  }
                  return ListView.separated(
                    itemCount: state.banks.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (context, index) {
                      final item = state.banks[index];
                      final b = item.bank;
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(b.bankName.characters.first),
                        ),
                        title: Text('${b.bankName} · ${b.accountName}'),
                        subtitle: Text('شماره حساب: ${b.accountNumber}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatCurrency(item.balance),
                              style: TextStyle(
                                color: item.balance >= 0 ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _openBankSheet(context, bank: b),
                        onLongPress: () => _openBankMenu(context, b),
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
        onPressed: () => _openBankSheet(context),
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

  Future<void> _openBankMenu(BuildContext context, Bank bank) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(tr('banks.edit')),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(tr('banks.delete')),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || action == null) return;
    if (action == 'edit') {
      _openBankSheet(context, bank: bank);
    } else if (action == 'delete') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(tr('banks.delete')),
          content: Text(tr('banks.confirm_delete', args: ['${bank.bankName} - ${bank.accountName}'])),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('انصراف'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(tr('banks.delete')),
            ),
          ],
        ),
      );
      if (ok == true && context.mounted) {
        await context.read<BanksCubit>().deleteBank(bank.id);
      }
    }
  }

  Future<void> _openBankSheet(BuildContext context, {Bank? bank}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _BankSheet(bank: bank),
    );
  }
}

class _BankSheet extends StatefulWidget {
  final Bank? bank;
  const _BankSheet({this.bank});
  @override
  State<_BankSheet> createState() => _BankSheetState();
}

class _BankSheetState extends State<_BankSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController bankName;
  late final TextEditingController accountName;
  late final TextEditingController accountNumber;
  String bankKey = 'melli';

  static const iranianBanks = [
    {'key': 'melli', 'name': 'بانک ملی'},
    {'key': 'sepah', 'name': 'بانک سپه'},
    {'key': 'mellat', 'name': 'بانک ملت'},
    {'key': 'tejarat', 'name': 'بانک تجارت'},
    {'key': 'saman', 'name': 'بانک سامان'},
    {'key': 'pasargad', 'name': 'بانک پاسارگاد'},
    {'key': 'saderat', 'name': 'بانک صادرات'},
    {'key': 'refah', 'name': 'بانک رفاه'},
    {'key': 'keshavarzi', 'name': 'بانک کشاورزی'},
    {'key': 'ayandeh', 'name': 'بانک آینده'},
  ];

  @override
  void initState() {
    super.initState();
    bankName = TextEditingController(text: widget.bank?.bankName ?? '');
    accountName = TextEditingController(text: widget.bank?.accountName ?? '');
    accountNumber = TextEditingController(
      text: widget.bank?.accountNumber ?? '',
    );
    bankKey = widget.bank?.bankKey ?? 'melli';
  }

  @override
  void dispose() {
    bankName.dispose();
    accountName.dispose();
    accountNumber.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.bank != null;
    final padding =
        MediaQuery.of(context).viewInsets + const EdgeInsets.all(16);
    return Padding(
      padding: padding,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isEdit ? tr('banks.edit') : tr('banks.add'), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: bankKey,
              items: iranianBanks
                  .map(
                    (e) => DropdownMenuItem(
                      value: e['key']!,
                      child: Text(e['name']!),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => bankKey = v ?? 'melli'),
              decoration: InputDecoration(labelText: tr('banks.bank')),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: bankName,
              decoration: InputDecoration(labelText: tr('banks.display_name')),
              validator: (v) => (v == null || v.isEmpty) ? 'الزامی' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: accountName,
              decoration: InputDecoration(labelText: tr('banks.account_name')),
              validator: (v) => (v == null || v.isEmpty) ? 'الزامی' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: accountNumber,
              decoration: InputDecoration(labelText: tr('banks.account_number')),
              validator: (v) => (v == null || v.isEmpty) ? 'الزامی' : null,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final cubit = context.read<BanksCubit>();
                    if (isEdit) {
                      await cubit.updateBank(
                        id: widget.bank!.id,
                        bankKey: bankKey,
                        bankName: bankName.text.trim(),
                        accountName: accountName.text.trim(),
                        accountNumber: accountNumber.text.trim(),
                      );
                    } else {
                      await cubit.addBank(
                        bankKey: bankKey,
                        bankName: bankName.text.trim(),
                        accountName: accountName.text.trim(),
                        accountNumber: accountNumber.text.trim(),
                      );
                    }
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                child: Text(isEdit ? tr('banks.save') : tr('banks.create')),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
