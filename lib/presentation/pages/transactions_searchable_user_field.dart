part of 'transactions_page.dart';

class _SearchableUserField extends StatefulWidget {
  final int? value;
  final ValueChanged<int?> onChanged;
  const _SearchableUserField({required this.value, required this.onChanged});
  @override
  State<_SearchableUserField> createState() => _SearchableUserFieldState();
}

class _SearchableUserFieldState extends State<_SearchableUserField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _syncLabel();
  }

  @override
  void didUpdateWidget(covariant _SearchableUserField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _syncLabel();
    }
  }

  void _syncLabel() {
    final state = context.read<UsersCubit>().state;
    String label = '';
    if (widget.value != null) {
      final sel = state.users.where((u) => u.id == widget.value).toList();
      if (sel.isNotEmpty)
        label = '${sel.first.firstName} ${sel.first.lastName}';
    }
    _controller.text = label;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UsersCubit, UsersState>(
      builder: (context, state) {
        _syncLabel();
        return TextFormField(
          controller: _controller,
          readOnly: true,
          decoration: InputDecoration(
            labelText: tr('loans.user'),
            suffixIcon: const Icon(Icons.search),
          ),
          onTap: () async {
            final picked = await _showUserPicker(context, state);
            if (picked != null) {
              widget.onChanged(picked);
              _syncLabel();
            }
          },
        );
      },
    );
  }
}
