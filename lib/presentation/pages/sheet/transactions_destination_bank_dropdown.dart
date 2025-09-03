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
                child: Text('${e.bank.bankName} · ${e.bank.accountName}'),
              ),
            )
            .toList();
        return DropdownButtonFormField<int>(
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: const InputDecoration(labelText: 'بانک مقصد'),
        );
      },
    );
  }
}
