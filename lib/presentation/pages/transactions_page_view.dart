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
                      Map<int, int> principalByLoanId,
                      Map<int, Map<int, int>> loanRemainingByTxId,
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
                          final loanId = trn.loanId;
                          if (loanId != null) {
                            final bool isPrincipal = trn.amount < 0;
                            final int remaining = isPrincipal
                                ? (extra.principalByLoanId[loanId] ?? 0)
                                : (extra.loanRemainingByTxId[loanId]?[trn.id] ??
                                      0);
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
                                if ((trn.type).isNotEmpty)
                                  Text(
                                    '${tr('transactions.type')}: ${trn.type}',
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

  Future<
    ({
      List<int> userRunningAfter,
      Map<int, int> principalByLoanId,
      Map<int, Map<int, int>> loanRemainingByTxId,
    })
  >
  _computeExtraData(
    BuildContext context,
    List<TransactionAggregate> items,
  ) async {
    // Build user balances after each item (running per user in current list)
    final String depositLabel = tr('transactions.deposit');
    final String withdrawLabel = tr('transactions.withdraw');
    final List<int> userRunningAfter = List<int>.filled(items.length, 0);
    final Map<int, int> cumulativeByUserId = <int, int>{};
    for (int i = 0; i < items.length; i++) {
      final trn = items[i].transaction;
      final int? userId = trn.userId;
      if (userId == null) {
        userRunningAfter[i] = 0;
        continue;
      }
      final prev = cumulativeByUserId[userId] ?? 0;
      int next = prev;
      if (trn.type == depositLabel) {
        next = prev + trn.amount.abs();
      } else if (trn.type == withdrawLabel) {
        next = prev - trn.amount.abs();
      }
      userRunningAfter[i] = next;
      cumulativeByUserId[userId] = next;
    }

    // Compute loan stats for only loans referenced in this list
    final Set<int> loanIds = items
        .map((e) => e.transaction.loanId)
        .whereType<int>()
        .toSet();
    final Map<int, int> principalByLoanId = <int, int>{};
    final Map<int, Map<int, int>> loanRemainingByTxId = <int, Map<int, int>>{};
    if (loanIds.isNotEmpty) {
      final loansSnapshot = await context.read<LoansCubit>().watchLoans().first;
      for (final loanId in loanIds) {
        final stats = loansSnapshot.firstWhere(
          (e) => e.loan.id == loanId,
          orElse: () => LoanWithStatsEntity(
            loan: LoanEntity(
              id: loanId,
              userId: 0,
              principalAmount: 0,
              installments: 0,
              note: null,
              createdAt: DateTime.fromMillisecondsSinceEpoch(0),
              updatedAt: null,
            ),
            paidAmount: 0,
          ),
        );
        principalByLoanId[loanId] = stats.loan.principalAmount;

        final payments = await context
            .read<LoansCubit>()
            .watchPayments(loanId)
            .first;
        int remaining = stats.loan.principalAmount;
        final Map<int, int> mapForLoan = <int, int>{};
        for (final (lp, trn, _) in payments) {
          remaining = remaining - lp.amount;
          mapForLoan[trn.id] = remaining;
        }
        loanRemainingByTxId[loanId] = mapForLoan;
      }
    }

    return (
      userRunningAfter: userRunningAfter,
      principalByLoanId: principalByLoanId,
      loanRemainingByTxId: loanRemainingByTxId,
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
