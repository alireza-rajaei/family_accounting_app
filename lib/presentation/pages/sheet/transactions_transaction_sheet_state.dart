part of '../transactions_page.dart';

class _TransactionSheetState extends State<TransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  int? bankId;
  int? userId;
  String type = 'واریز';
  int? toBankId;
  int? selectedLoanId;
  final amountCtrl = TextEditingController();
  final noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    if (d != null) {
      bankId = d.bank.id;
      userId = d.user?.id;
      type = d.transaction.type;
      amountCtrl.text = d.transaction.amount.abs().toString();
      noteCtrl.text = d.transaction.note ?? '';
    } else if (widget.initialUserId != null) {
      userId = widget.initialUserId;
    }
    // Apply optional initial values for type and loan selection
    if (widget.initialType != null && widget.initialType!.isNotEmpty) {
      type = widget.initialType!;
    }
    if (widget.initialLoanId != null) {
      selectedLoanId = widget.initialLoanId;
    }
  }

  @override
  void dispose() {
    amountCtrl.dispose();
    noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.data != null;
    final padding =
        MediaQuery.of(context).viewInsets + const EdgeInsets.all(16);
    final typeOptions = <String>[
      'واریز',
      'برداشت',
      'پرداخت وام به کاربر',
      'پرداخت قسط وام',
      'جابجایی بین بانکی',
    ];
    return Padding(
      padding: padding,
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEdit ? tr('transactions.save') : tr('transactions.create'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SearchableBankField(
                      value: bankId,
                      onChanged: (v) => setState(() => bankId = v),
                      validator: () => bankId == null ? 'الزامی' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: type,
                      items: typeOptions
                          .map(
                            (opt) =>
                                DropdownMenuItem(value: opt, child: Text(opt)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => type = v ?? 'واریز'),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'الزامی' : null,
                      decoration: InputDecoration(
                        labelText: tr('transactions.type'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (type == 'جابجایی بین بانکی')
                Row(
                  children: [
                    Expanded(
                      child: _SearchableDestinationBankField(
                        value: toBankId,
                        sourceBankId: bankId,
                        onChanged: (v) => setState(() => toBankId = v),
                        validator: () => (toBankId == null) ? 'الزامی' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: amountCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [ThousandsSeparatorInputFormatter()],
                        decoration: InputDecoration(
                          labelText: tr('transactions.amount'),
                        ),
                        validator: (v) =>
                            (_parseInt(v) == null) ? 'الزامی' : null,
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _SearchableUserField(
                        value: userId,
                        onChanged: (v) => setState(() => userId = v),
                        validator: () => (type == 'جابجایی بین بانکی')
                            ? null
                            : (userId == null ? 'الزامی' : null),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: amountCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [ThousandsSeparatorInputFormatter()],
                        decoration: InputDecoration(
                          labelText: tr('transactions.amount'),
                        ),
                        validator: (v) =>
                            (_parseInt(v) == null) ? 'الزامی' : null,
                      ),
                    ),
                  ],
                ),
              if (type == 'پرداخت قسط وام') ...[
                const SizedBox(height: 12),
                _UnsettledLoanField(
                  selectedUserId: userId,
                  selectedLoanId: selectedLoanId,
                  requiredSelection: true,
                  onSelected: (v) => setState(() => selectedLoanId = v),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: noteCtrl,
                decoration: InputDecoration(labelText: tr('transactions.note')),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate() && bankId != null) {
                      final c = context.read<TransactionsCubit>();
                      final amount = _parseInt(amountCtrl.text)!;
                      if (type == 'جابجایی بین بانکی') {
                        if (toBankId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('بانک مقصد را انتخاب کنید'),
                            ),
                          );
                          return;
                        }
                        final from = bankId!;
                        final to = toBankId!;
                        if (from == to) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'بانک مبدا و مقصد نباید یکسان باشند',
                              ),
                            ),
                          );
                          return;
                        }
                        final banksState = context.read<BanksCubit>().state;
                        final srcMatch = banksState.banks.where(
                          (b) => b.bank.id == from,
                        );
                        final srcBalance = srcMatch.isNotEmpty
                            ? srcMatch.first.balance
                            : 0;
                        if (amount > srcBalance) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'مبلغ برداشت از موجودی بانک بیشتر است',
                              ),
                            ),
                          );
                          return;
                        }
                        await c.transferBetweenBanks(
                          fromBankId: from,
                          toBankId: to,
                          amount: amount,
                          note: noteCtrl.text.trim().isEmpty
                              ? null
                              : noteCtrl.text.trim(),
                        );
                        if (context.mounted) Navigator.pop(context);
                        return;
                      }
                      if (type == 'پرداخت قسط وام') {
                        if (selectedLoanId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('ابتدا وام را انتخاب کنید'),
                            ),
                          );
                          return;
                        }
                        await context.read<LoansCubit>().addPayment(
                          loanId: selectedLoanId!,
                          bankId: bankId!,
                          amount: amount,
                          note: noteCtrl.text.trim().isEmpty
                              ? null
                              : noteCtrl.text.trim(),
                        );
                        if (context.mounted) Navigator.pop(context);
                        return;
                      }
                      if (type == 'برداشت' || type == 'پرداخت وام به کاربر') {
                        final banksState = context.read<BanksCubit>().state;
                        final srcMatch = banksState.banks.where(
                          (b) => b.bank.id == bankId,
                        );
                        final srcBalance = srcMatch.isNotEmpty
                            ? srcMatch.first.balance
                            : 0;
                        if (amount > srcBalance) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'مبلغ برداشت از موجودی بانک بیشتر است',
                              ),
                            ),
                          );
                          return;
                        }
                      }
                      final signedAmount =
                          (type == 'برداشت' || type == 'پرداخت وام به کاربر')
                          ? -amount
                          : amount;
                      if (isEdit) {
                        await c.update(
                          id: widget.data!.transaction.id,
                          bankId: bankId!,
                          userId: userId,
                          amount: signedAmount,
                          type: type,
                          note: noteCtrl.text.trim().isEmpty
                              ? null
                              : noteCtrl.text.trim(),
                        );
                      } else {
                        await c.add(
                          bankId: bankId!,
                          userId: userId,
                          amount: signedAmount,
                          type: type,
                          note: noteCtrl.text.trim().isEmpty
                              ? null
                              : noteCtrl.text.trim(),
                        );
                      }
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: Text(
                    isEdit
                        ? tr('transactions.save')
                        : tr('transactions.create'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
