part of 'transactions_page.dart';

class _FiltersBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TransactionsCubit>();
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          DropdownButton<String>(
            value: cubit.state.filter.type,
            hint: Text(tr('transactions.type')),
            items: const [
              DropdownMenuItem(value: 'واریز', child: Text('واریز')),
              DropdownMenuItem(value: 'برداشت', child: Text('برداشت')),
              DropdownMenuItem(
                value: 'پرداخت وام به کاربر',
                child: Text('پرداخت وام به کاربر'),
              ),
              DropdownMenuItem(
                value: 'پرداخت قسط وام',
                child: Text('پرداخت قسط وام'),
              ),
              DropdownMenuItem(
                value: 'جابجایی بین بانکی',
                child: Text('جابجایی بین بانکی'),
              ),
            ],
            onChanged: (v) {
              cubit.updateFilter(
                TransactionsFilter(
                  from: cubit.state.filter.from,
                  to: cubit.state.filter.to,
                  type: v,
                  userId: cubit.state.filter.userId,
                  bankId: cubit.state.filter.bankId,
                ),
              );
            },
          ),
          _BankPicker(),
          _UserPicker(),
          _DateRangePicker(),
        ],
      ),
    );
  }
}
