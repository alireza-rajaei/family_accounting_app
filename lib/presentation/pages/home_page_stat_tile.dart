part of 'home_page.dart';

class _FundOverviewCard extends StatelessWidget {
  const _FundOverviewCard({required this.loansRepo});
  final WatchLoansUseCase loansRepo;

  @override
  Widget build(BuildContext context) {
    final transactionsRepo = locator<WatchTransactionsUseCase>();
    final bankFlowRepo = locator<WatchBankFlowSumsUseCase>();

    return BlocBuilder<BanksCubit, BanksState>(
      builder: (context, banksState) {
        final totalBalance = banksState.banks.fold<int>(
          0,
          (sum, b) => sum + b.balance,
        );
        return StreamBuilder<List<TransactionAggregate>>(
          stream: transactionsRepo(const TransactionsFilterEntity()),
          builder: (context, txSnap) {
            final fundCapital = (txSnap.data ?? [])
                .where((a) => isDepositType(a.transaction.type))
                .fold<int>(0, (sum, a) => sum + a.transaction.amount.abs());
            return StreamBuilder<
              List<(String bankKey, int deposit, int withdraw)>
            >(
              stream: bankFlowRepo(),
              builder: (context, flowSnap) {
                final flows = flowSnap.data ?? const [];
                final totalDeposits = flows.fold<int>(
                  0,
                  (sum, e) => sum + e.$2,
                );
                final totalWithdrawals = flows.fold<int>(
                  0,
                  (sum, e) => sum + e.$3,
                );
                return StreamBuilder<List<LoanWithStatsEntity>>(
                  stream: loansRepo(),
                  builder: (context, loansSnap) {
                    final loans =
                        loansSnap.data ?? const <LoanWithStatsEntity>[];
                    final disbursed = loans.fold<int>(
                      0,
                      (sum, l) => sum + l.loan.principalAmount,
                    );
                    final remaining = loans.fold<int>(
                      0,
                      (sum, l) => sum + l.remaining,
                    );
                    final repaid = loans.fold<int>(
                      0,
                      (sum, l) => sum + l.paidAmount,
                    );
                    final activeLoans = loans.where((l) => !l.settled).length;

                    return _HomeSurface(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _BalanceHero(
                            label: tr('home.overview_total_balance'),
                            amount: totalBalance,
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr('home.overview_title'),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _MetricChip(
                                        icon: AppIcons.fundCapital,
                                        label: tr('home.overview_fund_capital'),
                                        amount: fundCapital,
                                        color: const Color(0xFF0D9488),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _MetricChip(
                                        icon: AppIcons.deposit,
                                        label: tr(
                                          'home.overview_total_deposits',
                                        ),
                                        amount: totalDeposits,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _MetricChip(
                                        icon: AppIcons.withdraw,
                                        label: tr(
                                          'home.overview_total_withdrawals',
                                        ),
                                        amount: totalWithdrawals,
                                        color: AppColors.danger,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _MetricChip(
                                        icon: AppIcons.pending,
                                        label: tr(
                                          'home.overview_loans_remaining',
                                        ),
                                        amount: remaining,
                                        color: AppColors.warning,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _OverviewMoneyRow(
                                  icon: AppIcons.payments,
                                  label: tr('home.overview_loans_disbursed'),
                                  amount: disbursed,
                                  color: AppColors.danger,
                                ),
                                const SizedBox(height: 10),
                                _OverviewMoneyRow(
                                  icon: AppIcons.check,
                                  label: tr('home.overview_loans_repaid'),
                                  amount: repaid,
                                  color: AppColors.success,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: BlocBuilder<UsersCubit, UsersState>(
                                        builder: (context, usersState) =>
                                            _OverviewCountTile(
                                              label: tr(
                                                'home.overview_users_count',
                                              ),
                                              value: usersState.users.length
                                                  .toString(),
                                              icon: AppIcons.users,
                                            ),
                                      ),
                                    ),
                                    Expanded(
                                      child: _OverviewCountTile(
                                        label: tr('home.overview_banks_count'),
                                        value: banksState.banks.length
                                            .toString(),
                                        icon: AppIcons.banks,
                                      ),
                                    ),
                                    Expanded(
                                      child: _OverviewCountTile(
                                        label: tr('home.overview_active_loans'),
                                        value: activeLoans.toString(),
                                        icon: AppIcons.loans,
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
            );
          },
        );
      },
    );
  }
}

class _BalanceHero extends StatelessWidget {
  const _BalanceHero({required this.label, required this.amount});

  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: isDark
              ? [
                  AppColors.primary.withValues(alpha: 0.35),
                  AppColors.secondary.withValues(alpha: 0.18),
                ]
              : [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.85),
                  AppColors.secondary.withValues(alpha: 0.95),
                ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  AppIcons.wallet,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            formatThousands(amount),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tr('banks.rial'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 10),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              height: 1.25,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            formatThousands(amount),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _OverviewMoneyRow extends StatelessWidget {
  const _OverviewMoneyRow({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        Text(
          '${formatThousands(amount)} ${tr('banks.rial')}',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _OverviewCountTile extends StatelessWidget {
  const _OverviewCountTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color accent;

  const _StatTile({
    required this.label,
    required this.value,
    this.icon,
    this.accent = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 96,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
      ),
      child: Stack(
        children: [
          if (icon != null)
            Positioned(
              left: 0,
              bottom: 0,
              child: Icon(
                icon,
                size: 40,
                color: accent.withValues(alpha: 0.18),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            tr(label),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
