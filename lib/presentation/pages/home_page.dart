import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../di/locator.dart';
import '../cubits/banks_cubit.dart';
import '../cubits/users_cubit.dart';
import '../cubits/transactions_cubit.dart';
import '../../data/repositories/transactions_repository.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => BanksCubit(locator())..watch()),
        BlocProvider(create: (_) => UsersCubit(locator())..watch()),
        BlocProvider(create: (_) => TransactionsCubit(locator())..watch()),
      ],
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();
  @override
  Widget build(BuildContext context) {
    final repo = locator<TransactionsRepository>();
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Chart card with fl_chart: per-bank deposit/withdraw
          StreamBuilder<List<(String bankName, int deposit, int withdraw)>>(
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
                        height: 220,
                        child: BarChart(
                          BarChartData(
                            barGroups: [
                              for (int i = 0; i < data.length; i++)
                                BarChartGroupData(
                                  x: i,
                                  barsSpace: 6,
                                  showingTooltipIndicators: const [0, 1],
                                  barRods: [
                                    BarChartRodData(
                                      toY: data[i].$2.toDouble(),
                                      color: const Color(0xFF10B981),
                                      borderRadius: BorderRadius.circular(2),
                                      width: 7,
                                    ),
                                    BarChartRodData(
                                      toY: data[i].$3.toDouble(),
                                      color: const Color(0xFFEF4444),
                                      borderRadius: BorderRadius.circular(2),
                                      width: 7,
                                    ),
                                  ],
                                ),
                            ],
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 36,
                                ),
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
                            gridData: const FlGridData(show: true),
                            barTouchData: BarTouchData(enabled: true),
                          ),
                          swapAnimationDuration: const Duration(
                            milliseconds: 600,
                          ),
                          swapAnimationCurve: Curves.easeOutCubic,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          // Balances per bank
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
                              Expanded(
                                child: Text(
                                  '${b.bank.bankName} · ${b.bank.accountName}',
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
          // Stats: users count and unsettled loans
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: BlocBuilder<UsersCubit, UsersState>(
                      builder: (context, state) => _StatTile(
                        label: 'کاربران',
                        value: state.users.length.toString(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: BlocBuilder<TransactionsCubit, TransactionsState>(
                      builder: (context, state) => _StatTile(
                        label: 'تعداد تراکنش',
                        value: state.items.length.toString(),
                      ),
                    ),
                  ),
                ],
              ),
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

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
      ],
    );
  }
}
