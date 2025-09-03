part of 'transactions_page.dart';

class _DateRangePicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final f = context.watch<TransactionsCubit>().state.filter;
    String label;
    if (f.from != null && f.to != null) {
      label =
          '${JalaliUtils.formatJalali(f.from!)} تا ${JalaliUtils.formatJalali(f.to!)}';
    } else {
      label = 'تاریخ';
    }
    return OutlinedButton.icon(
      icon: const Icon(Icons.date_range),
      label: Text(label),
      onPressed: () async {
        final now = DateTime.now();
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(now.year - 5),
          lastDate: DateTime(now.year + 1),
          helpText: 'انتخاب بازه تاریخ (میلادی)',
        );
        if (picked != null) {
          final c = context.read<TransactionsCubit>();
          c.updateFilter(
            TransactionsFilter(
              from: picked.start,
              to: picked.end,
              type: c.state.filter.type,
              userId: c.state.filter.userId,
              bankId: c.state.filter.bankId,
            ),
          );
        }
      },
    );
  }
}
