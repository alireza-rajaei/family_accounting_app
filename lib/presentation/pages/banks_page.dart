import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/theme/app_ui.dart';
import '../../app/utils/bank_icons.dart';
import '../../app/utils/format.dart';
import '../../di/locator.dart';
import '../../domain/entities/bank.dart';
import '../cubits/banks_cubit.dart';
import '../../app/theme/app_icons.dart';

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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: AppSearchField(
                controller: _search,
                hintText: tr('banks.search_hint'),
                onChanged: (v) {
                  cubit.watch(v);
                  setState(() {});
                },
                onClear: () {
                  cubit.watch('');
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
                    return AppEmptyState(
                      message: tr('banks.not_found'),
                      icon: AppIcons.banks,
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                    itemCount: state.banks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = state.banks[index];
                      final b = item.bank;
                      final colors = BankIcons.gradients[b.bankKey];
                      final isFa = context.locale.languageCode == 'fa';
                      final bankName = isFa
                          ? (BankIcons.persianNames[b.bankKey] ?? b.bankKey)
                          : (BankIcons.englishNames[b.bankKey] ?? b.bankKey);
                      final bankSub = isFa
                          ? (BankIcons.englishNames[b.bankKey] ?? '')
                          : (BankIcons.persianNames[b.bankKey] ?? '');
                      return Container(
                        height: 196,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: (colors?.first ?? Colors.black)
                                  .withValues(alpha: 0.22),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          gradient: colors == null
                              ? LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.secondary,
                                  ],
                                )
                              : LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: colors,
                                ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: 4,
                              top: 4,
                              child: PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                icon: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    AppIcons.more,
                                    color: Colors.white,
                                    size: 20,
                                  ),
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
                                          '${tr('banks.confirm_delete', namedArgs: {'name': '$bankName - ${b.accountName}'})}\n${tr('banks.delete_cascade_note')}',
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
                                        Colors.white.withValues(alpha: 0.28),
                                        Colors.white.withValues(alpha: 0.08),
                                        Colors.white.withValues(alpha: 0.0),
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
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.8,
                                        fontSize: 26,
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
                                    children: [
                                      Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.55,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: SizedBox(
                                            width: 36,
                                            height: 36,
                                            child: BankCircleAvatar(
                                              bankKey: b.bankKey,
                                              name: bankName,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              bankName,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                            ),
                                            Text(
                                              b.accountName.isNotEmpty
                                                  ? b.accountName
                                                  : bankSub,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.9),
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Align(
                                    alignment: AlignmentDirectional.bottomEnd,
                                    child: Text(
                                      '${formatThousands(item.balance)} ${tr('banks.rial')}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                    ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openBankSheet(context),
        icon: const Icon(AppIcons.add),
        label: Text(tr('banks.add')),
      ),
    );
  }

  Future<void> _openBankSheet(BuildContext context, {BankEntity? bank}) async {
    final banksCubit = context.read<BanksCubit>();
    await showAppModalSheet(
      context: context,
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
    accountName = TextEditingController(text: widget.bank?.accountName ?? '');
    accountNumber = TextEditingController(
      text: widget.bank?.accountNumber ?? '',
    );
    bankKey = widget.bank?.bankKey ?? 'melli';
  }

  @override
  void dispose() {
    accountName.dispose();
    accountNumber.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.bank != null;
    return AppSheetBody(
      title: isEdit ? tr('banks.edit') : tr('banks.add'),
      icon: AppIcons.banksFilled,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: bankKey,
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
              child: FilledButton.icon(
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
                icon: Icon(isEdit ? AppIcons.save : AppIcons.add),
                label: Text(isEdit ? tr('banks.save') : tr('banks.create')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
