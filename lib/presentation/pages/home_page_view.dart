part of 'home_page.dart';

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final loansRepo = locator<WatchLoansUseCase>();

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _FundOverviewCard(loansRepo: loansRepo),
          const SizedBox(height: 16),
          _BankBalancesSection(),
          const SizedBox(height: 16),
          _FlowChartCard(repo: locator<WatchDailyFlowSumsUseCase>()),
          const SizedBox(height: 16),
          _ActivityStatsCard(
            loansRepo: loansRepo,
            transactionsRepo: locator<WatchTransactionsUseCase>(),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _HomeSurface extends StatelessWidget {
  const _HomeSurface({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return AppSurface(padding: padding, child: child);
  }
}

class _BankBalancesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _HomeSurface(
      child: BlocBuilder<BanksCubit, BanksState>(
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(title: tr('home.balances_card')),
              const SizedBox(height: 14),
              if (state.banks.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      tr('transactions.not_found'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.55,
                        ),
                      ),
                    ),
                  ),
                )
              else
                for (int i = 0; i < state.banks.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _BankBalanceRow(item: state.banks[i]),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _BankBalanceRow extends StatelessWidget {
  const _BankBalanceRow({required this.item});

  final BankWithBalanceEntity item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFa = context.locale.languageCode == 'fa';
    final bankKey = item.bank.bankKey;
    final bankName = isFa
        ? (BankIcons.persianNames[bankKey] ?? bankKey)
        : (BankIcons.englishNames[bankKey] ?? bankKey);
    final isNegative = item.balance < 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            alignment: Alignment.center,
            child: BankIcons.logo(bankKey, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bankName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.bank.accountName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatAmount(item.balance),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: isNegative ? AppColors.danger : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowChartCard extends StatelessWidget {
  const _FlowChartCard({required this.repo});

  final WatchDailyFlowSumsUseCase repo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gridColor = theme.colorScheme.onSurface.withValues(alpha: 0.08);
    final isFa = context.locale.languageCode == 'fa';

    final jNow = DateTime.now().toJalali();
    final monthStart = Jalali(jNow.year, jNow.month, 1).toDateTime();
    final monthEnd = (jNow.month == 12
            ? Jalali(jNow.year + 1, 1, 1)
            : Jalali(jNow.year, jNow.month + 1, 1))
        .toDateTime();
    final daysInMonth = monthEnd.difference(monthStart).inDays;

    return _HomeSurface(
      child: StreamBuilder<List<(DateTime day, int deposit, int withdraw)>>(
        stream: repo(from: monthStart, to: monthEnd),
        builder: (context, snapshot) {
          final byDay = <String, (int, int)>{};
          for (final row in snapshot.data ?? const []) {
            final key =
                '${row.$1.year}-${row.$1.month.toString().padLeft(2, '0')}-${row.$1.day.toString().padLeft(2, '0')}';
            byDay[key] = (row.$2, row.$3);
          }

          final depositSpots = <FlSpot>[];
          final withdrawSpots = <FlSpot>[];
          var hasAny = false;
          for (int i = 0; i < daysInMonth; i++) {
            final day = monthStart.add(Duration(days: i));
            final key =
                '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
            final values = byDay[key] ?? (0, 0);
            if (values.$1 > 0 || values.$2 > 0) hasAny = true;
            depositSpots.add(FlSpot(i.toDouble(), values.$1.toDouble()));
            withdrawSpots.add(FlSpot(i.toDouble(), values.$2.toDouble()));
          }

          String dayLabel(int index) {
            final day = monthStart.add(Duration(days: index));
            return isFa
                ? day.toJalali().day.toString()
                : day.day.toString();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(title: tr('home.chart_card')),
              const SizedBox(height: 8),
              const Row(
                children: [
                  _Legend(
                    color: AppColors.success,
                    label: 'transactions.deposit',
                  ),
                  SizedBox(width: 12),
                  _Legend(
                    color: AppColors.danger,
                    label: 'transactions.withdraw',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 240,
                child: !hasAny
                    ? Center(
                        child: Text(
                          tr('transactions.not_found'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.55,
                            ),
                          ),
                        ),
                      )
                    : LineChart(
                        LineChartData(
                          minX: 0,
                          maxX: (daysInMonth - 1).toDouble(),
                          minY: 0,
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: gridColor,
                              strokeWidth: 1,
                              dashArray: const [4, 4],
                            ),
                          ),
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
                                reservedSize: 28,
                                interval: _bottomInterval(daysInMonth),
                                getTitlesWidget: (value, meta) {
                                  final idx = value.round();
                                  if (idx < 0 || idx >= daysInMonth) {
                                    return const SizedBox();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      dayLabel(idx),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.65),
                                          ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          lineTouchData: LineTouchData(
                            handleBuiltInTouches: true,
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipColor: (touchedSpot) =>
                                  const Color(0xE0111827),
                              tooltipRoundedRadius: 10,
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) {
                                  final isDeposit =
                                      spot.barIndex == 0;
                                  final label = isDeposit
                                      ? tr('transactions.deposit')
                                      : tr('transactions.withdraw');
                                  final day = dayLabel(spot.x.round());
                                  return LineTooltipItem(
                                    '$day\n$label: ${formatAmount(spot.y.toInt())}',
                                    TextStyle(
                                      color: spot.bar.color ?? Colors.white,
                                      fontWeight: FontWeight.w600,
                                      height: 1.35,
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: depositSpots,
                              isCurved: true,
                              curveSmoothness: 0.28,
                              color: AppColors.success,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                checkToShowDot: (spot, barData) => spot.y > 0,
                                getDotPainter: (spot, percent, bar, index) =>
                                    FlDotCirclePainter(
                                      radius: 3.5,
                                      color: AppColors.success,
                                      strokeWidth: 1.5,
                                      strokeColor: theme.colorScheme.surface,
                                    ),
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppColors.success.withValues(
                                  alpha: 0.12,
                                ),
                              ),
                            ),
                            LineChartBarData(
                              spots: withdrawSpots,
                              isCurved: true,
                              curveSmoothness: 0.28,
                              color: AppColors.danger,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                checkToShowDot: (spot, barData) => spot.y > 0,
                                getDotPainter: (spot, percent, bar, index) =>
                                    FlDotCirclePainter(
                                      radius: 3.5,
                                      color: AppColors.danger,
                                      strokeWidth: 1.5,
                                      strokeColor: theme.colorScheme.surface,
                                    ),
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppColors.danger.withValues(alpha: 0.10),
                              ),
                            ),
                          ],
                        ),
                        duration: const Duration(milliseconds: 650),
                        curve: Curves.easeOutCubic,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  double _bottomInterval(int daysInMonth) {
    if (daysInMonth <= 10) return 1;
    if (daysInMonth <= 20) return 2;
    return 5;
  }
}

class _ActivityStatsCard extends StatelessWidget {
  const _ActivityStatsCard({
    required this.loansRepo,
    required this.transactionsRepo,
  });

  final WatchLoansUseCase loansRepo;
  final WatchTransactionsUseCase transactionsRepo;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final jNow = now.toJalali();
    final from = Jalali(jNow.year, 1, 1).toDateTime();
    final to = Jalali(jNow.year + 1, 1, 1).toDateTime();

    return _HomeSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: tr('home.year_title', namedArgs: {'year': '${jNow.year}'}),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: BlocBuilder<UsersCubit, UsersState>(
                  builder: (context, state) => _StatTile(
                    label: tr('home.stats_users'),
                    value: state.users.length.toString(),
                    icon: AppIcons.users,
                    accent: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: BlocBuilder<TransactionsCubit, TransactionsState>(
                  builder: (context, state) => _StatTile(
                    label: tr('home.stats_transactions'),
                    value: state.items.length.toString(),
                    icon: AppIcons.transactions,
                    accent: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<TransactionAggregate>>(
            stream: transactionsRepo(
              TransactionsFilterEntity(from: from, to: to),
            ),
            builder: (context, snapshot) {
              final trCount = snapshot.data?.length ?? 0;
              return StreamBuilder<List<LoanWithStatsEntity>>(
                stream: loansRepo(),
                builder: (context, snap) {
                  final loansCount = (snap.data ?? const <LoanWithStatsEntity>[])
                      .where(
                        (l) =>
                            !l.loan.createdAt.isBefore(from) &&
                            l.loan.createdAt.isBefore(to),
                      )
                      .length;
                  return Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          label: tr('home.year_transactions'),
                          value: trCount.toString(),
                          icon: AppIcons.receipt,
                          accent: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatTile(
                          label: tr('home.year_loans'),
                          value: loansCount.toString(),
                          icon: AppIcons.loans,
                          accent: AppColors.warning,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
