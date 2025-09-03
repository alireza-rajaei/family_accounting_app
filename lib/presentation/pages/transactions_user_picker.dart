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
        return DropdownButton<int>(
          value: sel,
          hint: Text(tr('transactions.search_user')),
          items: items,
          onChanged: (v) {
            final c = context.read<TransactionsCubit>();
            c.updateFilter(
              TransactionsFilter(
                from: c.state.filter.from,
                to: c.state.filter.to,
                type: c.state.filter.type,
                userId: v,
                bankId: c.state.filter.bankId,
              ),
            );
          },
        );
      },
    );
  }
}
