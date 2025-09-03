part of 'transactions_page.dart';

class _BankPicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BanksCubit, BanksState>(
      builder: (context, state) {
        final items = state.banks
            .map(
              (e) => DropdownMenuItem(
                value: e.bank.id,
                child: Text('${e.bank.bankName} · ${e.bank.accountName}'),
              ),
            )
            .toList();
        final sel = context.read<TransactionsCubit>().state.filter.bankId;
        return DropdownButton<int>(
          value: sel,
          hint: Text(tr('transactions.search_bank')),
          items: items,
          onChanged: (v) {
            final c = context.read<TransactionsCubit>();
            c.updateFilter(
              TransactionsFilter(
                from: c.state.filter.from,
                to: c.state.filter.to,
                type: c.state.filter.type,
                userId: c.state.filter.userId,
                bankId: v,
              ),
            );
          },
        );
      },
    );
  }
}
