part of 'home_page.dart';

class _FundOverviewCard extends StatelessWidget {
  const _FundOverviewCard({required this.loansRepo});
  final WatchLoansUseCase loansRepo;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('home.overview_title'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            BlocBuilder<BanksCubit, BanksState>(
              builder: (context, banksState) {
                final totalBalance = banksState.banks.fold<int>(
                  0,
                  (sum, b) => sum + b.balance,
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

                    return Column(
                      children: [
                        _OverviewMoneyRow(
                          icon: Icons.account_balance_wallet_outlined,
                          label: tr('home.overview_total_balance'),
                          amount: totalBalance,
                          color: const Color(0xFF2563EB),
                        ),
                        const Divider(height: 20),
                        _OverviewMoneyRow(
                          icon: Icons.payments_outlined,
                          label: tr('home.overview_loans_disbursed'),
                          amount: disbursed,
                          color: const Color(0xFFEF4444),
                        ),
                        const SizedBox(height: 10),
                        _OverviewMoneyRow(
                          icon: Icons.pending_actions_outlined,
                          label: tr('home.overview_loans_remaining'),
                          amount: remaining,
                          color: const Color(0xFFF59E0B),
                        ),
                        const SizedBox(height: 10),
                        _OverviewMoneyRow(
                          icon: Icons.task_alt_outlined,
                          label: tr('home.overview_loans_repaid'),
                          amount: repaid,
                          color: const Color(0xFF10B981),
                        ),
                        const Divider(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: BlocBuilder<UsersCubit, UsersState>(
                                builder: (context, usersState) =>
                                    _OverviewCountTile(
                                      label: tr('home.overview_users_count'),
                                      value: usersState.users.length.toString(),
                                      icon: Icons.people_alt_outlined,
                                    ),
                              ),
                            ),
                            Expanded(
                              child: _OverviewCountTile(
                                label: tr('home.overview_banks_count'),
                                value: banksState.banks.length.toString(),
                                icon: Icons.account_balance_outlined,
                              ),
                            ),
                            Expanded(
                              child: _OverviewCountTile(
                                label: tr('home.overview_active_loans'),
                                value: activeLoans.toString(),
                                icon: Icons.request_quote_outlined,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
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
          '${_formatCurrency(amount)} ${tr('banks.rial')}',
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: theme.colorScheme.primary),
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
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
  const _StatTile({required this.label, required this.value, this.icon});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (icon != null)
            Positioned(
              left: 4,
              top: 4,
              child: Icon(
                icon,
                size: 72,
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.08),
              ),
            ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(tr(label), style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
