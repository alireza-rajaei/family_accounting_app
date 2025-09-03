part of 'transactions_page.dart';

Future<void> _openTransactionSheet(
  BuildContext context, {
  TransactionWithJoins? data,
  int? initialUserId,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => TransactionsCubit(locator())..watch()),
        BlocProvider(create: (_) => BanksCubit(locator())..watch()),
        BlocProvider(create: (_) => UsersCubit(locator())..watch()),
      ],
      child: TransactionSheet(data: data, initialUserId: initialUserId),
    ),
  );
}

Future<void> showTransactionSheet(
  BuildContext context, {
  TransactionWithJoins? data,
  int? initialUserId,
}) {
  return _openTransactionSheet(
    context,
    data: data,
    initialUserId: initialUserId,
  );
}

int? _parseInt(String? v) {
  if (v == null) return null;
  final digits = v.replaceAll(',', '');
  return int.tryParse(digits);
}

Future<int?> _showBankPicker(BuildContext context, BanksState state) async {
  final controller = TextEditingController();
  List<int> filtered = state.banks.map((e) => e.bank.id).toList();
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: StatefulBuilder(
          builder: (context, setStateSB) {
            void apply(String q) {
              setStateSB(() {
                final pat = q.trim();
                filtered = state.banks
                    .where(
                      (b) => '${b.bank.bankName} ${b.bank.accountName}'
                          .contains(pat),
                    )
                    .map((e) => e.bank.id)
                    .toList();
              });
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: tr('transactions.search_bank'),
                  ),
                  onChanged: apply,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 320,
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final id = filtered[index];
                      final b = state.banks.firstWhere((e) => e.bank.id == id);
                      return ListTile(
                        title: Text(
                          '${b.bank.bankName} · ${b.bank.accountName}',
                        ),
                        onTap: () => Navigator.pop(context, id),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}

Future<int?> _showUserPicker(BuildContext context, UsersState state) async {
  final controller = TextEditingController();
  List<int> filtered = state.users.map((e) => e.id).toList();
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: StatefulBuilder(
          builder: (context, setStateSB) {
            void apply(String q) {
              setStateSB(() {
                final pat = q.trim();
                filtered = state.users
                    .where((u) => '${u.firstName} ${u.lastName}'.contains(pat))
                    .map((e) => e.id)
                    .toList();
              });
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: tr('transactions.search_user'),
                  ),
                  onChanged: apply,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 320,
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final id = filtered[index];
                      final u = state.users.firstWhere((e) => e.id == id);
                      return ListTile(
                        title: Text('${u.firstName} ${u.lastName}'),
                        onTap: () => Navigator.pop(context, id),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}
