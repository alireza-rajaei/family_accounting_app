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
                  return FutureBuilder<
                    ({
                      List<int> userRunningAfter,
                      Map<int, int> cumulativeLoanRemainingByTxId,
                    })
                  >(
                    future: _computeExtraData(context, state.items),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final extra = snap.data!;
                      return ListView.separated(
                        itemCount:
                            state.items.length + (state.loadingMore ? 1 : 0),
                        separatorBuilder: (_, __) => const Divider(height: 0),
                        itemBuilder: (context, index) {
                          if (index >= state.items.length) {
                            return const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          // Ask cubit to prefetch if user scrolls near the end
                          context.read<TransactionsCubit>().loadMoreIfNeeded(
                            index,
                          );
                          final it = state.items[index];
                          final trn = it.transaction;
                          final isIncome = trn.amount >= 0;

                          String? loanRemainingLine;
                          if (trn.loanId != null ||
                              isLoanRelatedType(trn.type)) {
                            final int remaining =
                                extra.cumulativeLoanRemainingByTxId[trn.id] ??
                                0;
                            loanRemainingLine =
                                '${tr('transactions.loan_remaining')}: ${_formatCurrency(remaining)} ${tr('banks.rial')}';
                          }
                          final uid = trn.userId;
                          final userBal = extra.userRunningAfter[index];
                          final userBalanceLine = uid == null
                              ? null
                              : '${tr('users.balance')}: ${_formatCurrency(userBal)} ${tr('banks.rial')}';

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
                              it.user != null
                                  ? '${it.user!.firstName} ${it.user!.lastName}'
                                  : ((context.locale.languageCode == 'fa'
                                            ? BankIcons.persianNames[it
                                                  .bank
                                                  .bankKey]
                                            : BankIcons.englishNames[it
                                                  .bank
                                                  .bankKey]) ??
                                        it.bank.bankKey),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${it.bank.accountName} · ${(context.locale.languageCode == 'fa' ? JalaliUtils.formatJalali(trn.createdAt) : JalaliUtils.formatGregorian(trn.createdAt))}',
                                ),
                                if ((trn.type).isNotEmpty)
                                  Text(
                                    '${tr('transactions.type')}: ${_localizedType(context, trn.type)}',
                                  ),
                                if (loanRemainingLine != null)
                                  Text(loanRemainingLine),
                                if (loanRemainingLine == null &&
                                    userBalanceLine != null)
                                  Text(userBalanceLine),
                              ],
                            ),
                            trailing: Text(
                              '${_formatCurrency(trn.amount.abs() * (isIncome ? 1 : -1))} ${tr('banks.rial')}',
                              style: TextStyle(
                                color: isIncome ? Colors.green : Colors.red,
                              ),
                            ),
                            onTap: () async {
                              await _openTransactionSheet(context, data: it);
                              if (context.mounted) {
                                context.read<TransactionsCubit>().watch();
                              }
                            },
                            onLongPress: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(tr('transactions.delete')),
                                  content: const Text(
                                    // Consider adding a translation key if needed
                                    'آیا از حذف این تراکنش مطمئن هستید؟',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: Text(tr('common.cancel')),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: Text(tr('transactions.delete')),
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _openTransactionSheet(context);
          if (context.mounted) {
            context.read<TransactionsCubit>().watch();
          }
        },
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

  String _localizedType(BuildContext context, String storedType) {
    // Types are stored unified in Persian in DB; map to current locale for UI
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

  Future<
    ({
      List<int> userRunningAfter,
      Map<int, int> cumulativeLoanRemainingByTxId,
    })
  >
  _computeExtraData(
    BuildContext context,
    List<TransactionAggregate> items,
  ) async {
    // Build user balance "after this transaction" for each list item.
    // List is newest-first, so after(i) = totalUserBalance - sum(delta of newer items for that user).
    final String depositLabel = tr('transactions.deposit');
    final String withdrawLabel = tr('transactions.withdraw');
    final List<int> userRunningAfter = List<int>.filled(items.length, 0);

    // Fetch total balance per user (excludes loan-linked transactions per repo rule)
    final Set<int> userIds = items
        .map((e) => e.transaction.userId)
        .whereType<int>()
        .toSet();
    final Map<int, int> totalByUserId = <int, int>{};
    for (final uid in userIds) {
      totalByUserId[uid] = await context.read<UsersCubit>().getUserBalance(uid);
    }

    // Track cumulative delta of items that are NEWER than current per user
    final Map<int, int> newerDeltaByUserId = <int, int>{};
    for (int i = 0; i < items.length; i++) {
      final trn = items[i].transaction;
      final int? uid = trn.userId;
      if (uid == null) {
        userRunningAfter[i] = 0;
        continue;
      }

      final int total = totalByUserId[uid] ?? 0;
      final int newerDelta = newerDeltaByUserId[uid] ?? 0;
      // Balance immediately after this transaction happened
      userRunningAfter[i] = total - newerDelta;

      // Update delta for subsequent (older) rows only for cash deposit/withdraw
      if (trn.type == depositLabel) {
        newerDeltaByUserId[uid] = newerDelta + trn.amount.abs();
      } else if (trn.type == withdrawLabel) {
        newerDeltaByUserId[uid] = newerDelta - trn.amount.abs();
      }
    }

    // Cumulative remaining across ALL of each user's loans (oldest → newest).
    // e.g. 80M then 45M principal ⇒ second row shows 125M, not 45M.
    final Map<int, int> cumulativeLoanRemainingByTxId = <int, int>{};
    final fetchTx = locator<FetchTransactionsUseCase>();
    for (final uid in userIds) {
      final allTx = await fetchTx(
        TransactionsFilterEntity(userId: uid),
        limit: 100000,
        offset: 0,
      );
      final chronological = allTx
          .map((e) => e.transaction)
          .where((t) => isLoanRelatedType(t.type))
          .toList()
        ..sort((a, b) {
          final byDate = a.createdAt.compareTo(b.createdAt);
          return byDate != 0 ? byDate : a.id.compareTo(b.id);
        });

      int remaining = 0;
      for (final trn in chronological) {
        if (isLoanPrincipalType(trn.type)) {
          remaining += trn.amount.abs();
        } else if (isLoanInstallmentType(trn.type)) {
          remaining -= trn.amount.abs();
        }
        cumulativeLoanRemainingByTxId[trn.id] = remaining;
      }
    }

    return (
      userRunningAfter: userRunningAfter,
      cumulativeLoanRemainingByTxId: cumulativeLoanRemainingByTxId,
    );
  }
}

class _FiltersButton extends StatelessWidget {
  const _FiltersButton();
  int _activeFiltersCount(TransactionsFilterEntity f) {
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
