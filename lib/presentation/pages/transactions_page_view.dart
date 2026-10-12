part of 'transactions_page.dart';

class _TransactionsView extends StatelessWidget {
  const _TransactionsView();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      tr('transactions.title'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const _FiltersButton(),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<TransactionsCubit, TransactionsState>(
                builder: (context, state) {
                  if (state.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.items.isEmpty) {
                    return AppEmptyState(
                      message: tr('transactions.not_found'),
                      icon: AppIcons.transactions,
                    );
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
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                        itemCount:
                            state.items.length + (state.loadingMore ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          if (index >= state.items.length) {
                            return const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          context.read<TransactionsCubit>().loadMoreIfNeeded(
                            index,
                          );
                          final it = state.items[index];
                          final trn = it.transaction;
                          final isIncome = trn.amount >= 0;
                          final isFa = context.locale.languageCode == 'fa';
                          final bankName =
                              (isFa
                                  ? BankIcons.persianNames[it.bank.bankKey]
                                  : BankIcons.englishNames[it.bank.bankKey]) ??
                              it.bank.bankKey;

                          String? loanRemainingLine;
                          if (trn.loanId != null ||
                              isLoanRelatedType(trn.type)) {
                            final int remaining =
                                extra.cumulativeLoanRemainingByTxId[trn.id] ??
                                0;
                            loanRemainingLine =
                                '${tr('transactions.loan_remaining')}: ${formatThousands(remaining)} ${tr('banks.rial')}';
                          }
                          final uid = trn.userId;
                          final userBal = extra.userRunningAfter[index];
                          final userBalanceLine = uid == null
                              ? null
                              : '${tr('users.balance')}: ${formatThousands(userBal)} ${tr('banks.rial')}';

                          final title = it.user != null
                              ? '${it.user!.firstName} ${it.user!.lastName}'
                              : bankName;
                          final dateStr = isFa
                              ? JalaliUtils.formatJalali(trn.createdAt)
                              : JalaliUtils.formatGregorian(trn.createdAt);

                          return AppSurface(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                            radius: 18,
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
                                  content: Text(tr('loans.confirm_delete')),
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
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                BankCircleAvatar(
                                  bankKey: it.bank.bankKey,
                                  name: bankName,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              title,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                          ),
                                          AppAmountText(
                                            text:
                                                '${isIncome ? '' : '-'}${formatThousands(trn.amount.abs())}',
                                            positive: isIncome,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${it.bank.accountName} · $dateStr',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.55),
                                            ),
                                      ),
                                      if ((trn.type).isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: (isIncome
                                                    ? AppColors.success
                                                    : AppColors.danger)
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            _localizedType(context, trn.type),
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: isIncome
                                                      ? AppColors.success
                                                      : AppColors.danger,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ),
                                      ],
                                      if (loanRemainingLine != null) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          loanRemainingLine,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ],
                                      if (loanRemainingLine == null &&
                                          userBalanceLine != null) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          userBalanceLine,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await _openTransactionSheet(context);
          if (context.mounted) {
            context.read<TransactionsCubit>().watch();
          }
        },
        icon: const Icon(AppIcons.add),
        label: Text(tr('transactions.create')),
      ),
    );
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
              IconButton.filledTonal(
                icon: const Icon(AppIcons.tune),
                tooltip: tr('transactions.filters'),
                onPressed: () {
                  final parentContext = context;
                  showAppModalSheet(
                    context: context,
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
                  right: 2,
                  top: 2,
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
