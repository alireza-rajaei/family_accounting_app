part of 'transactions_page.dart';

class _FiltersBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TransactionsCubit>();
    // This widget is now meant to be shown inside a bottom sheet
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                tr('transactions.filters'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        width: 200,
                        child: DropdownButtonFormField<String>(
                          value: cubit.state.filter.type,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: tr('transactions.type'),
                            suffixIcon: cubit.state.filter.type == null
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.close),
                                    tooltip: tr('common.clear'),
                                    onPressed: () {
                                      cubit.updateFilter(
                                        TransactionsFilter(
                                          from: cubit.state.filter.from,
                                          to: cubit.state.filter.to,
                                          type: null,
                                          userId: cubit.state.filter.userId,
                                          bankId: cubit.state.filter.bankId,
                                        ),
                                      );
                                      // Also reset field UI selection
                                      (FocusManager.instance.primaryFocus)
                                          ?.unfocus();
                                    },
                                  ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'واریز',
                              child: Text('واریز'),
                            ),
                            DropdownMenuItem(
                              value: 'برداشت',
                              child: Text('برداشت'),
                            ),
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
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: const _FilterBankField()),
                  ],
                ),

                const _FilterUserField(),
                _DateRangePicker(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBankField extends StatefulWidget {
  const _FilterBankField();
  @override
  State<_FilterBankField> createState() => _FilterBankFieldState();
}

class _FilterBankFieldState extends State<_FilterBankField> {
  final TextEditingController _controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TransactionsCubit>();
    final filter = context.watch<TransactionsCubit>().state.filter;
    final banksState = context.watch<BanksCubit>().state;
    String? bankKey;
    String label = '';
    if (filter.bankId != null) {
      final match = banksState.banks.where((b) => b.bank.id == filter.bankId);
      if (match.isNotEmpty) {
        bankKey = match.first.bank.bankKey;
        label =
            '${BankIcons.persianNames[match.first.bank.bankKey] ?? match.first.bank.bankKey} · ${match.first.bank.accountName}';
      }
    }
    _controller.text = label;
    return SizedBox(
      width: 220,
      child: TextFormField(
        controller: _controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: tr('transactions.search_bank'),
          prefixIcon: bankKey == null
              ? null
              : Padding(
                  padding: const EdgeInsets.all(8),
                  child: BankIcons.logo(bankKey, size: 20),
                ),
          suffixIcon: filter.bankId == null
              ? const Icon(Icons.search)
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => cubit.updateFilter(
                    TransactionsFilter(
                      from: filter.from,
                      to: filter.to,
                      type: filter.type,
                      userId: filter.userId,
                      bankId: null,
                    ),
                  ),
                ),
        ),
        onTap: () async {
          final picked = await _showBankPicker(context, banksState);
          if (picked != null) {
            cubit.updateFilter(
              TransactionsFilter(
                from: filter.from,
                to: filter.to,
                type: filter.type,
                userId: filter.userId,
                bankId: picked,
              ),
            );
          }
        },
      ),
    );
  }
}

class _FilterUserField extends StatefulWidget {
  const _FilterUserField();
  @override
  State<_FilterUserField> createState() => _FilterUserFieldState();
}

class _FilterUserFieldState extends State<_FilterUserField> {
  final TextEditingController _controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TransactionsCubit>();
    final filter = context.watch<TransactionsCubit>().state.filter;
    final usersState = context.watch<UsersCubit>().state;
    String label = '';
    if (filter.userId != null) {
      final match = usersState.users.where((u) => u.id == filter.userId);
      if (match.isNotEmpty) {
        final u = match.first;
        label = '${u.firstName} ${u.lastName}';
      }
    }
    _controller.text = label;
    return SizedBox(
      width: double.infinity,
      child: TextFormField(
        controller: _controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: tr('transactions.search_user'),
          suffixIcon: filter.userId == null
              ? const Icon(Icons.search)
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => cubit.updateFilter(
                    TransactionsFilter(
                      from: filter.from,
                      to: filter.to,
                      type: filter.type,
                      userId: null,
                      bankId: filter.bankId,
                    ),
                  ),
                ),
        ),
        onTap: () async {
          final picked = await _showUserPicker(context, usersState);
          if (picked != null) {
            cubit.updateFilter(
              TransactionsFilter(
                from: filter.from,
                to: filter.to,
                type: filter.type,
                userId: picked,
                bankId: filter.bankId,
              ),
            );
          }
        },
      ),
    );
  }
}
