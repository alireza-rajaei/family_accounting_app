part of '../transactions_page.dart';

class _DestinationBankDropdown extends StatelessWidget {
  final int? value;
  final ValueChanged<int?> onChanged;
  const _DestinationBankDropdown({
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BanksCubit, BanksState>(
      builder: (context, state) {
        final sourceBankId =
            (context.findAncestorStateOfType<_TransactionSheetState>())?.bankId;
        final items = state.banks
            .where((b) => b.bank.id != sourceBankId)
            .map(
              (e) => DropdownMenuItem(
                value: e.bank.id,
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: BankIcons.logo(e.bank.bankKey, size: 24),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${BankIcons.persianNames[e.bank.bankKey] ?? e.bank.bankKey} · ${e.bank.accountName}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList();
        return DropdownButtonFormField<int>(
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'بانک مقصد',
            hintText: 'بانک مقصد',
          ),
        );
      },
    );
  }
}
