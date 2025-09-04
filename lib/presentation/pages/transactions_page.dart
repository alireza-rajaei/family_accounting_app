import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../di/locator.dart';
import '../cubits/transactions_cubit.dart';
import '../cubits/banks_cubit.dart';
import '../cubits/users_cubit.dart';
import '../../data/repositories/transactions_repository.dart';
import '../../app/utils/bank_icons.dart';
import '../../app/utils/jalali_utils.dart';
import '../../app/utils/thousands_input_formatter.dart';

part 'transactions_page_view.dart';
part 'transactions_filters_bar.dart';
part 'transactions_bank_picker.dart';
part 'transactions_user_picker.dart';
part 'transactions_date_range_picker.dart';
part 'sheet/transactions_sheet_helpers.dart';
part 'sheet/transactions_transaction_sheet.dart';
part 'sheet/transactions_transaction_sheet_state.dart';
part 'sheet/transactions_destination_bank_dropdown.dart';
part 'sheet/transactions_searchable_bank_field.dart';
part 'sheet/transactions_searchable_user_field.dart';
part 'sheet/transactions_searchable_destination_bank_field.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => TransactionsCubit(locator())..watch()),
        BlocProvider(create: (_) => BanksCubit(locator())..watch()),
        BlocProvider(create: (_) => UsersCubit(locator())..watch()),
      ],
      child: const _TransactionsView(),
    );
  }
}
