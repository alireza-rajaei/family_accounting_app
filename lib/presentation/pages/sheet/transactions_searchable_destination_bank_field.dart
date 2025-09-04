part of '../transactions_page.dart';

class _SearchableDestinationBankField extends StatefulWidget {
  final int? value;
  final int? sourceBankId;
  final ValueChanged<int?> onChanged;
  final String? Function()? validator;
  const _SearchableDestinationBankField({
    required this.value,
    required this.onChanged,
    required this.sourceBankId,
    this.validator,
  });
  @override
  State<_SearchableDestinationBankField> createState() =>
      _SearchableDestinationBankFieldState();
}

class _SearchableDestinationBankFieldState
    extends State<_SearchableDestinationBankField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _syncLabel();
  }

  @override
  void didUpdateWidget(covariant _SearchableDestinationBankField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _syncLabel();
    }
  }

  void _syncLabel() {
    final state = context.read<BanksCubit>().state;
    String label = '';
    if (widget.value != null) {
      final match = state.banks.where((b) => b.bank.id == widget.value);
      if (match.isNotEmpty) {
        label =
            '${BankIcons.persianNames[match.first.bank.bankKey] ?? match.first.bank.bankKey} · ${match.first.bank.accountName}';
      }
    }
    _controller.text = label;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<BanksCubit>().state;
    String? bankKey;
    if (widget.value != null) {
      final match = state.banks.where((b) => b.bank.id == widget.value);
      if (match.isNotEmpty) {
        bankKey = match.first.bank.bankKey;
      }
    }
    return TextFormField(
      controller: _controller,
      readOnly: true,
      validator: (_) => widget.validator?.call(),
      decoration: InputDecoration(
        labelText: 'بانک مقصد',
        prefixIcon: bankKey == null
            ? null
            : Padding(
                padding: const EdgeInsets.all(8),
                child: BankIcons.logo(bankKey, size: 20),
              ),
        suffixIcon: const Icon(Icons.search),
      ),
      onTap: () async {
        final state = context.read<BanksCubit>().state;
        final picked = await _showBankPicker(
          context,
          state,
          excludeBankId: widget.sourceBankId,
        );
        if (picked != null) {
          widget.onChanged(picked);
          _syncLabel();
        }
      },
    );
  }
}
