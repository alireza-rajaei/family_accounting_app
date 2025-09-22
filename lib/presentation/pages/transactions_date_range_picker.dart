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
    final hasRange = f.from != null || f.to != null;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.date_range),
            label: Text(label),
            onPressed: () async {
              final range = await _showJalaliRangePicker(context);
              if (range != null) {
                final c = context.read<TransactionsCubit>();
                c.updateFilter(
                  TransactionsFilterEntity(
                    from: range.$1,
                    to: range.$2,
                    type: c.state.filter.type,
                    userId: c.state.filter.userId,
                    bankId: c.state.filter.bankId,
                  ),
                );
              }
            },
          ),
        ),
        if (hasRange) const SizedBox(width: 8),
        if (hasRange)
          SizedBox(
            height: 48,
            width: 48,
            child: IconButton(
              tooltip: 'حذف',
              onPressed: () {
                final c = context.read<TransactionsCubit>();
                c.updateFilter(
                  TransactionsFilterEntity(
                    from: null,
                    to: null,
                    type: c.state.filter.type,
                    userId: c.state.filter.userId,
                    bankId: c.state.filter.bankId,
                  ),
                );
              },
              icon: const Icon(Icons.close),
            ),
          ),
      ],
    );
  }
}

Future<(DateTime, DateTime)?> _showJalaliRangePicker(
  BuildContext context,
) async {
  // Lightweight custom sheet using shamsi_date
  return showModalBottomSheet<(DateTime, DateTime)>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return _JalaliRangeSheet();
    },
  );
}

class _JalaliRangeSheet extends StatefulWidget {
  @override
  State<_JalaliRangeSheet> createState() => _JalaliRangeSheetState();
}

class _JalaliRangeSheetState extends State<_JalaliRangeSheet> {
  // Using shamsi_date for validation and conversion
  int fromYear = 1400, fromMonth = 1, fromDay = 1;
  int toYear = 1400, toMonth = 1, toDay = 1;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final j = JalaliUtils.fromDateTime(now);
    fromYear = j.year;
    fromMonth = j.month;
    fromDay = j.day;
    toYear = j.year;
    toMonth = j.month;
    toDay = j.day;
  }

  @override
  Widget build(BuildContext context) {
    List<int> months = List.generate(12, (i) => i + 1);
    List<int> daysFrom = List.generate(
      _daysInJalaliMonth(fromYear, fromMonth),
      (i) => i + 1,
    );
    List<int> daysTo = List.generate(
      _daysInJalaliMonth(toYear, toMonth),
      (i) => i + 1,
    );
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'انتخاب بازه تاریخ (شمسی)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          // Show 'from' and 'to' on separate rows for clarity
          _ymdPicker(
            'از',
            fromYear,
            fromMonth,
            fromDay,
            months,
            daysFrom,
            onYear: (v) => setState(() => fromYear = v),
            onMonth: (v) => setState(() => fromMonth = v),
            onDay: (v) => setState(() => fromDay = v),
          ),
          const SizedBox(height: 12),
          _ymdPicker(
            'تا',
            toYear,
            toMonth,
            toDay,
            months,
            daysTo,
            onYear: (v) => setState(() => toYear = v),
            onMonth: (v) => setState(() => toMonth = v),
            onDay: (v) => setState(() => toDay = v),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('انصراف'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    final fromDt = _jalaliToDateTime(
                      fromYear,
                      fromMonth,
                      fromDay,
                    );
                    final toDt = _jalaliToDateTime(toYear, toMonth, toDay);
                    if (fromDt.isAfter(toDt)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تاریخ شروع نباید بعد از پایان باشد'),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(context, (fromDt, toDt));
                  },
                  child: const Text('تایید'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _daysInJalaliMonth(int y, int m) {
    final date = shamsi.Jalali(y, m, 1);
    return date.monthLength;
  }

  DateTime _jalaliToDateTime(int y, int m, int d) {
    final j = shamsi.Jalali(y, m, d);
    return j.toDateTime();
  }
}

Widget _ymdPicker(
  String label,
  int year,
  int month,
  int day,
  List<int> months,
  List<int> days, {
  required ValueChanged<int> onYear,
  required ValueChanged<int> onMonth,
  required ValueChanged<int> onDay,
}) {
  final years = List.generate(70, (i) => 1360 + i);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              value: year,
              isExpanded: true,
              alignment: Alignment.center,
              items: years
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Center(
                        child: Text(e.toString(), textAlign: TextAlign.center),
                      ),
                    ),
                  )
                  .toList(),
              selectedItemBuilder: (ctx) => years
                  .map(
                    (e) => Center(
                      child: Text(e.toString(), textAlign: TextAlign.center),
                    ),
                  )
                  .toList(),
              onChanged: (v) => onYear(v ?? year),
              decoration: const InputDecoration(
                labelText: 'سال',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<int>(
              value: month,
              isExpanded: true,
              alignment: Alignment.center,
              items: months
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Center(
                        child: Text(e.toString(), textAlign: TextAlign.center),
                      ),
                    ),
                  )
                  .toList(),
              selectedItemBuilder: (ctx) => months
                  .map(
                    (e) => Center(
                      child: Text(e.toString(), textAlign: TextAlign.center),
                    ),
                  )
                  .toList(),
              onChanged: (v) => onMonth(v ?? month),
              decoration: const InputDecoration(
                labelText: 'ماه',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<int>(
              value: day,
              isExpanded: true,
              alignment: Alignment.center,
              items: days
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Center(
                        child: Text(e.toString(), textAlign: TextAlign.center),
                      ),
                    ),
                  )
                  .toList(),
              selectedItemBuilder: (ctx) => days
                  .map(
                    (e) => Center(
                      child: Text(e.toString(), textAlign: TextAlign.center),
                    ),
                  )
                  .toList(),
              onChanged: (v) => onDay(v ?? day),
              decoration: const InputDecoration(
                labelText: 'روز',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}
