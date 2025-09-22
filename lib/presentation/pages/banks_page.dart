import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../di/locator.dart';
import '../../domain/entities/bank.dart';
import '../cubits/banks_cubit.dart';
import '../../app/utils/bank_icons.dart';

class BanksPage extends StatelessWidget {
  const BanksPage({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          BanksCubit(locator(), locator(), locator(), locator())..watch(),
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
                    padding: const EdgeInsets.only(top: 12),
                    itemCount: state.banks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 24),
                    itemBuilder: (context, index) {
                      final item = state.banks[index];
                      final b = item.bank;
                      final colors = BankIcons.gradients[b.bankKey];
                      return Container(
                        height: 200,
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: colors == null
                              ? null
                              : LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: colors,
                                ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: 8,
                              top: 8,
                              child: PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: Colors.white,
                                ),
                                onSelected: (action) async {
                                  if (action == 'edit') {
                                    _openBankSheet(context, bank: b);
                                  } else if (action == 'delete') {
                                    final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text(tr('banks.delete')),
                                        content: Text(
                                          '${tr('banks.confirm_delete', namedArgs: {'name': '${BankIcons.persianNames[b.bankKey] ?? b.bankKey} - ${b.accountName}'})}\n${tr('banks.delete_cascade_note')}',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: Text(tr('common.cancel')),
                                          ),
                                          FilledButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: Text(tr('banks.delete')),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (ok == true && context.mounted) {
                                      await context
                                          .read<BanksCubit>()
                                          .deleteBank(b.id);
                                    }
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text(tr('banks.edit')),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text(tr('banks.delete')),
                                  ),
                                ],
                              ),
                            ),
                            Positioned.fill(
                              child: IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      center: Alignment.center,
                                      radius: 0.72,
                                      colors: [
                                        Colors.white.withOpacity(0.32),
                                        Colors.white.withOpacity(0.10),
                                        Colors.white.withOpacity(0.0),
                                      ],
                                      stops: const [0.0, 0.55, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            IgnorePointer(
                              child: Align(
                                alignment: Alignment.center,
                                child: Opacity(
                                  opacity: 0.12,
                                  child: BankIcons.logo(
                                    b.bankKey,
                                    size: 140,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.center,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  b.accountNumber,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.8,
                                        fontSize: 28,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      // Bank logo (left) with white translucent circle behind
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: SizedBox(
                                            width: 40,
                                            height: 40,
                                            child: BankCircleAvatar(
                                              bankKey: b.bankKey,
                                              name:
                                                  (context
                                                          .locale
                                                          .languageCode ==
                                                      'fa'
                                                  ? (BankIcons.persianNames[b
                                                            .bankKey] ??
                                                        b.bankKey)
                                                  : (BankIcons.englishNames[b
                                                            .bankKey] ??
                                                        b.bankKey)),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Bank title + english subtitle (similar to sample)
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              (context.locale.languageCode ==
                                                      'fa'
                                                  ? (BankIcons.persianNames[b
                                                            .bankKey] ??
                                                        b.bankKey)
                                                  : (BankIcons.englishNames[b
                                                            .bankKey] ??
                                                        b.bankKey)),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge
                                                  ?.copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                            Text(
                                              (context.locale.languageCode ==
                                                      'fa'
                                                  ? (BankIcons.englishNames[b
                                                            .bankKey] ??
                                                        '')
                                                  : (BankIcons.persianNames[b
                                                            .bankKey] ??
                                                        '')),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: Colors.white
                                                        .withOpacity(0.9),
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  // Card number and balance footer
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Expanded(child: SizedBox()),
                                      const SizedBox(width: 12),
                                      Text(
                                        '${_formatCurrency(item.balance)} ${tr('banks.rial')}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
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

  Future<void> _openBankSheet(BuildContext context, {BankEntity? bank}) async {
    final banksCubit = context.read<BanksCubit>();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => BlocProvider.value(
        value: banksCubit,
        child: _BankSheet(bank: bank),
      ),
    );
  }
}

class _BankSheet extends StatefulWidget {
  final BankEntity? bank;
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
    {'key': 'sandogh', 'name': 'صندوق'},
  ];

  @override
  void initState() {
    super.initState();
    bankName = TextEditingController(
      text: BankIcons.persianNames[widget.bank?.bankKey ?? ''] ?? '',
    );
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
            Text(
              isEdit ? tr('banks.edit') : tr('banks.add'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: bankKey,
              items: iranianBanks
                  .map(
                    (e) => DropdownMenuItem(
                      value: e['key']!,
                      child: Text(
                        context.locale.languageCode == 'fa'
                            ? (BankIcons.persianNames[e['key']!] ?? e['key']!)
                            : (BankIcons.englishNames[e['key']!] ?? e['key']!),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => bankKey = v ?? 'melli'),
              decoration: InputDecoration(labelText: tr('banks.bank')),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: accountName,
              decoration: InputDecoration(labelText: tr('banks.account_name')),
              validator: (v) =>
                  (v == null || v.isEmpty) ? tr('common.required') : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: accountNumber,
              decoration: InputDecoration(
                labelText: tr('banks.account_number'),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? tr('common.required') : null,
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
                        accountName: accountName.text.trim(),
                        accountNumber: accountNumber.text.trim(),
                      );
                    } else {
                      await cubit.addBank(
                        bankKey: bankKey,
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
