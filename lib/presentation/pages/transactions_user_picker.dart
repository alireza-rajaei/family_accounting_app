part of 'transactions_page.dart';

class _UserPicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UsersCubit, UsersState>(
      builder: (context, state) {
        final items = state.users
            .map(
              (u) => DropdownMenuItem(
                value: u.id,
                child: Text('${u.firstName} ${u.lastName}'),
              ),
            )
            .toList();
        final sel = context.read<TransactionsCubit>().state.filter.userId;
        return SizedBox(
          width: 220,
          child: DropdownButtonFormField<int>(
            value: sel,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: tr('transactions.search_user'),
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
                            userId: null,
                            bankId: c.state.filter.bankId,
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
                  userId: v,
                  bankId: c.state.filter.bankId,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
