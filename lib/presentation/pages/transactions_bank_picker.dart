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
                child: Text(
                  '${(context.locale.languageCode == 'fa' ? (BankIcons.persianNames[e.bank.bankKey] ?? e.bank.bankKey) : (BankIcons.englishNames[e.bank.bankKey] ?? e.bank.bankKey))} · ${e.bank.accountName}',
                ),
              ),
            )
            .toList();
        final sel = context.read<TransactionsCubit>().state.filter.bankId;
        return SizedBox(
          width: 220,
          child: DropdownButtonFormField<int>(
            value: sel,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: tr('transactions.search_bank'),
              suffixIcon: sel == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: tr('common.clear'),
                      onPressed: () {
                        final c = context.read<TransactionsCubit>();
                        c.updateFilter(
                          TransactionsFilterEntity(
                            from: c.state.filter.from,
                            to: c.state.filter.to,
                            type: c.state.filter.type,
                            userId: c.state.filter.userId,
                            bankId: null,
                          ),
                        );
                      },
                    ),
            ),
            items: items,
            onChanged: (v) {
              final c = context.read<TransactionsCubit>();
              c.updateFilter(
                TransactionsFilterEntity(
                  from: c.state.filter.from,
                  to: c.state.filter.to,
                  type: c.state.filter.type,
                  userId: c.state.filter.userId,
                  bankId: v,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
