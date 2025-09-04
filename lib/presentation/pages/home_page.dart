import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../di/locator.dart';
import '../cubits/banks_cubit.dart';
import '../../app/utils/bank_icons.dart';
import '../cubits/users_cubit.dart';
import '../cubits/transactions_cubit.dart';
import '../../data/repositories/transactions_repository.dart';
part 'home_page_view.dart';
part 'home_page_stat_tile.dart';

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
