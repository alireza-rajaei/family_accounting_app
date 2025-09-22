part of '../transactions_page.dart';

class TransactionSheet extends StatefulWidget {
  final TransactionAggregate? data;
  final int? initialUserId;
  final String? initialType;
  final int? initialLoanId;
  const TransactionSheet({
    this.data,
    this.initialUserId,
    this.initialType,
    this.initialLoanId,
  });
  @override
  State<TransactionSheet> createState() => _TransactionSheetState();
}

class _UnsettledLoanField extends StatelessWidget {
  final int? selectedUserId;
  final int? selectedLoanId;
  final bool requiredSelection;
  final ValueChanged<int?>? onSelected;
  const _UnsettledLoanField({
    this.selectedUserId,
    this.selectedLoanId,
    this.requiredSelection = false,
    this.onSelected,
  });
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UsersCubit, UsersState>(
      builder: (context, uState) {
        return BlocBuilder<TransactionsCubit, TransactionsState>(
          builder: (context, tState) {
            return BlocBuilder<LoansCubit, LoansState>(
              builder: (context, lState) {
                // We may not have a LoansCubit; fallback to use case stream in UI
                final stream = locator<WatchLoansUseCase>()();
                return StreamBuilder<List<LoanWithStatsEntity>>(
                  stream: stream,
                  builder: (context, snapshot) {
                    final loans = (snapshot.data ?? [])
                        .where((l) => (!l.settled))
                        .where(
                          (l) =>
                              selectedUserId == null ||
                              l.loan.userId == selectedUserId,
                        )
                        .toList();
                    return DropdownButtonFormField<int>(
                      isExpanded: true,
                      value: selectedLoanId,
                      decoration: InputDecoration(
                        labelText: tr('loans.select'),
                      ),
                      items: loans.map((e) {
                        final user = context
                            .read<UsersCubit>()
                            .state
                            .users
                            .firstWhere((u) => u.id == e.loan.userId);
                        final dateFa = JalaliUtils.formatJalali(
                          e.loan.createdAt,
                        );
                        final title =
                            '${user.firstName} ${user.lastName} · ${dateFa}';
                        final subtitle =
                            '${tr('loans.remaining')}: ${e.remaining}';
                        return DropdownMenuItem(
                          value: e.loan.id,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title),
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      selectedItemBuilder: (ctx) => loans.map((e) {
                        final user = context
                            .read<UsersCubit>()
                            .state
                            .users
                            .firstWhere((u) => u.id == e.loan.userId);
                        final dateFa = JalaliUtils.formatJalali(
                          e.loan.createdAt,
                        );
                        final text =
                            '${user.firstName} ${user.lastName} · ${dateFa} · ${tr('loans.remaining')}: ${e.remaining}';
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: onSelected,
                      validator: (v) {
                        if (requiredSelection && v == null) return 'الزامی';
                        return null;
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
