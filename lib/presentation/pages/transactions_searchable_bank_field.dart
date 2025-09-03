part of 'transactions_page.dart';

class _SearchableBankField extends StatefulWidget {
  final int? value;
  final ValueChanged<int?> onChanged;
  const _SearchableBankField({required this.value, required this.onChanged});
  @override
  State<_SearchableBankField> createState() => _SearchableBankFieldState();
}

class _SearchableBankFieldState extends State<_SearchableBankField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _syncLabel();
  }

  @override
  void didUpdateWidget(covariant _SearchableBankField oldWidget) {
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
            '${match.first.bank.bankName} · ${match.first.bank.accountName}';
      }
    }
    _controller.text = label;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: tr('banks.bank'),
        suffixIcon: const Icon(Icons.search),
      ),
      onTap: () async {
        final state = context.read<BanksCubit>().state;
        final picked = await _showBankPicker(context, state);
        if (picked != null) {
          widget.onChanged(picked);
          _syncLabel();
        }
      },
    );
  }
}
