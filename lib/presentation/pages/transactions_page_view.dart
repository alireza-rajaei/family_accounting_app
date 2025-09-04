part of 'transactions_page.dart';

class _TransactionsView extends StatelessWidget {
  const _TransactionsView();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('transactions.title')),
        actions: const [_FiltersButton()],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Optionally keep inline filters hidden; only the button opens the sheet
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
                      final isIncome = trn.amount >= 0;
                      return ListTile(
                        leading: BankCircleAvatar(
                          bankKey: it.bank.bankKey,
                          name:
                              BankIcons.persianNames[it.bank.bankKey] ??
                              it.bank.bankKey,
                        ),
                        title: Text(
                          it.user != null
                              ? '${it.user!.firstName} ${it.user!.lastName}'
                              : (BankIcons.persianNames[it.bank.bankKey] ??
                                    it.bank.bankKey),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${it.bank.accountName} · ${JalaliUtils.formatJalali(trn.createdAt)}',
                            ),
                            if ((trn.type).isNotEmpty) Text('نوع: ${trn.type}'),
                          ],
                        ),
                        trailing: Text(
                          '${_formatCurrency(trn.amount.abs() * (isIncome ? 1 : -1))} ${tr('banks.rial')}',
                          style: TextStyle(
                            color: isIncome ? Colors.green : Colors.red,
                          ),
                        ),
                        onTap: () => _openTransactionSheet(context, data: it),
                        onLongPress: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('حذف تراکنش'),
                              content: const Text(
                                'آیا از حذف این تراکنش مطمئن هستید؟',
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
                          if (ok == true && context.mounted) {
                            await context.read<TransactionsCubit>().delete(
                              trn.id,
                            );
                          }
                        },
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

class _FiltersButton extends StatelessWidget {
  const _FiltersButton();
  int _activeFiltersCount(TransactionsFilter f) {
    int c = 0;
    if (f.type != null) c++;
    if (f.bankId != null) c++;
    if (f.userId != null) c++;
    if (f.from != null || f.to != null) c++;
    return c;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionsCubit, TransactionsState>(
      builder: (context, state) {
        final count = _activeFiltersCount(state.filter);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                tooltip: tr('transactions.filters'),
                onPressed: () {
                  final parentContext = context;
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useRootNavigator: false,
                    useSafeArea: true,
                    // Use default bottom sheet styling like other sheets
                    builder: (ctx) => MultiBlocProvider(
                      providers: [
                        BlocProvider.value(
                          value: parentContext.read<TransactionsCubit>(),
                        ),
                        BlocProvider.value(
                          value: parentContext.read<BanksCubit>(),
                        ),
                        BlocProvider.value(
                          value: parentContext.read<UsersCubit>(),
                        ),
                      ],
                      child: const _FiltersSheet(),
                    ),
                  );
                },
              ),
              if (count > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _FiltersSheet extends StatelessWidget {
  const _FiltersSheet();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Builder(builder: (inner) => _FiltersBar()),
      ),
    );
  }
}
