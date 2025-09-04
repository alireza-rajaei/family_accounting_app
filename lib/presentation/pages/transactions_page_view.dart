part of 'transactions_page.dart';

class _TransactionsView extends StatelessWidget {
  const _TransactionsView();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _FiltersBar(),
            Expanded(
              child: BlocBuilder<TransactionsCubit, TransactionsState>(
                builder: (context, state) {
                  if (state.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.items.isEmpty) {
                    return Center(child: Text(tr('transactions.not_found')));
                  }
                  return ListView.separated(
                    itemCount: state.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (context, index) {
                      final it = state.items[index];
                      final trn = it.transaction;
                      final isIncome = trn.amount >= 0;
                      return ListTile(
                        leading: BankCircleAvatar(
                          bankKey: it.bank.bankKey,
                          name:
                              BankIcons.persianNames[it.bank.bankKey] ??
                              it.bank.bankKey,
                        ),
                        title: Text(
                          it.user != null
                              ? '${it.user!.firstName} ${it.user!.lastName}'
                              : (BankIcons.persianNames[it.bank.bankKey] ??
                                    it.bank.bankKey),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${it.bank.accountName} · ${JalaliUtils.formatJalali(trn.createdAt)}',
                            ),
                            if ((trn.type).isNotEmpty) Text('نوع: ${trn.type}'),
                          ],
                        ),
                        trailing: Text(
                          '${_formatCurrency(trn.amount.abs() * (isIncome ? 1 : -1))} ${tr('banks.rial')}',
                          style: TextStyle(
                            color: isIncome ? Colors.green : Colors.red,
                          ),
                        ),
                        onTap: () => _openTransactionSheet(context, data: it),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openTransactionSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatCurrency(int v) {
    final s = v.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idx = s.length - i - 1;
      buf.write(s[idx]);
      if (i % 3 == 2 && idx != 0) buf.write(',');
    }
    final str = buf.toString().split('').reversed.join();
    return (v < 0 ? '-' : '') + str;
  }
}
