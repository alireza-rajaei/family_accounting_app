part of 'home_page.dart';

class _HomeView extends StatelessWidget {
  const _HomeView();
  @override
  Widget build(BuildContext context) {
    final repo = locator<TransactionsRepository>();
    final loansRepo = locator<LoansRepository>();
    BankIcons;
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StreamBuilder<List<(String bankKey, int deposit, int withdraw)>>(
            stream: repo.watchBankFlowSums(),
            builder: (context, snapshot) {
              final data = snapshot.data ?? [];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('home.chart_card'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 240,
                        child: BarChart(
                          BarChartData(
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (value) => const FlLine(
                                color: Color(0x22000000),
                                strokeWidth: 1,
                                dashArray: [4, 4],
                              ),
                            ),
                            barGroups: [
                              for (int i = 0; i < data.length; i++)
                                BarChartGroupData(
                                  x: i,
                                  barsSpace: 10,
                                  barRods: [
                                    BarChartRodData(
                                      toY: data[i].$2.toDouble(),
                                      color: const Color(0xFF10B981),
                                      borderRadius: BorderRadius.circular(6),
                                      width: 12,
                                    ),
                                    BarChartRodData(
                                      toY: data[i].$3.toDouble(),
                                      color: const Color(0xFFEF4444),
                                      borderRadius: BorderRadius.circular(6),
                                      width: 12,
                                    ),
                                  ],
                                ),
                            ],
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final idx = value.toInt();
                                    if (idx < 0 || idx >= data.length)
                                      return const SizedBox();
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        BankIcons.persianNames[data[idx].$1] ??
                                            data[idx].$1,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (group) =>
                                    const Color(0xCC111827),
                                tooltipRoundedRadius: 8,
                                tooltipPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                tooltipMargin: 12,
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  final isDeposit = rodIndex == 0;
                                  final label = isDeposit
                                      ? tr('transactions.deposit')
                                      : tr('transactions.withdraw');
                                  return BarTooltipItem(
                                    '$label\n${_formatCurrency(rod.toY.toInt())}',
                                    const TextStyle(color: Colors.white),
                                  );
                                },
                              ),
                            ),
                          ),
                          swapAnimationDuration: const Duration(
                            milliseconds: 600,
                          ),
                          swapAnimationCurve: Curves.easeOutCubic,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: const [
                          _Legend(
                            color: Color(0xFF10B981),
                            label: 'transactions.deposit',
                          ),
                          SizedBox(width: 16),
                          _Legend(
                            color: Color(0xFFEF4444),
                            label: 'transactions.withdraw',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: BlocBuilder<BanksCubit, BanksState>(
                builder: (context, state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('home.balances_card'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      for (final b in state.banks)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: BankIcons.logo(b.bank.bankKey, size: 24),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${BankIcons.persianNames[b.bank.bankKey] ?? b.bank.bankKey} · ${b.bank.accountName}',
                                ),
                              ),
                              Text(
                                _formatCurrency(b.balance) +
                                    ' ${tr('banks.rial')}',
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: BlocBuilder<UsersCubit, UsersState>(
                      builder: (context, state) => _StatTile(
                        label: tr('home.stats_users'),
                        value: state.users.length.toString(),
                        icon: Icons.people_alt_outlined,
                      ),
                    ),
                  ),
                  Expanded(
                    child: BlocBuilder<TransactionsCubit, TransactionsState>(
                      builder: (context, state) => _StatTile(
                        label: tr('home.stats_transactions'),
                        value: state.items.length.toString(),
                        icon: Icons.compare_arrows_outlined,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _YearStats(repo: repo, loansRepo: loansRepo),
            ),
          ),
        ],
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

class _YearStats extends StatelessWidget {
  const _YearStats({required this.repo, required this.loansRepo});
  final TransactionsRepository repo;
  final LoansRepository loansRepo;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final jNow = now.toJalali();
    final jStart = Jalali(jNow.year, 1, 1);
    final jEnd = Jalali(
      jNow.year + 1,
      1,
      1,
    ).toDateTime().subtract(const Duration(days: 1));
    final from = jStart.toDateTime();
    final to = jEnd.add(const Duration(days: 1));

    final trStream = repo.watchTransactions(
      TransactionsFilter(from: from, to: to),
    );
    final loansStream = loansRepo.watchLoans();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('home.year_title', namedArgs: {'year': '${jNow.year}'}),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<TransactionWithJoins>>(
          stream: trStream,
          builder: (context, snapshot) {
            final trCount = snapshot.data?.length ?? 0;
            return Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: tr('home.year_transactions'),
                    value: trCount.toString(),
                    icon: Icons.receipt_long_outlined,
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<LoanWithStats>>(
                    stream: loansStream,
                    builder: (context, snap) {
                      final allLoans = snap.data ?? const <LoanWithStats>[];
                      final loansCount = allLoans
                          .where(
                            (l) =>
                                l.loan.createdAt.isAfter(from) &&
                                l.loan.createdAt.isBefore(to),
                          )
                          .length;
                      return _StatTile(
                        label: tr('home.year_loans'),
                        value: loansCount.toString(),
                        icon: Icons.request_quote_outlined,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
