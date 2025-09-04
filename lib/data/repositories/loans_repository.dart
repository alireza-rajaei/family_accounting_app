import 'package:drift/drift.dart' as d;

import '../local/db/app_database.dart';

class LoanWithStats {
  final Loan loan;
  final int paidAmount;
  int get remaining => loan.principalAmount - paidAmount;
  bool get settled => remaining <= 0;
  LoanWithStats({required this.loan, required this.paidAmount});
}

class LoansRepository {
  final AppDatabase db;
  LoansRepository(this.db);

  Stream<List<LoanWithStats>> watchLoans() {
    const sql = '''
SELECT l.*, COALESCE(SUM(lp.amount), 0) AS paid
FROM loans l
LEFT JOIN loan_payments lp ON lp.loan_id = l.id
GROUP BY l.id
ORDER BY l.created_at DESC, l.id DESC
''';
    return db
        .customSelect(sql, readsFrom: {db.loans, db.loanPayments})
        .watch()
        .map(
          (rows) => rows
              .map(
                (r) => LoanWithStats(
                  loan: Loan(
                    id: r.read<int>('id'),
                    userId: r.read<int>('user_id'),
                    principalAmount: r.read<int>('principal_amount'),
                    installments: r.read<int>('installments'),
                    note: r.readNullable<String>('note'),
                    createdAt: r.read<DateTime>('created_at'),
                    updatedAt: r.readNullable<DateTime>('updated_at'),
                  ),
                  paidAmount: r.read<int>('paid'),
                ),
              )
              .toList(),
        );
  }

  Future<int> addLoan({
    required int userId,
    required int principalAmount,
    required int installments,
    String? note,
  }) async {
    return db
        .into(db.loans)
        .insert(
          LoansCompanion.insert(
            userId: userId,
            principalAmount: principalAmount,
            installments: installments,
            note: d.Value(note),
          ),
        );
  }

  Future<int> addLoanWithTransaction({
    required int userId,
    required int bankId,
    required int principalAmount,
    required int installments,
    String? note,
  }) async {
    return await db.transaction(() async {
      final loanId = await db
          .into(db.loans)
          .insert(
            LoansCompanion.insert(
              userId: userId,
              principalAmount: principalAmount,
              installments: installments,
              note: d.Value(note),
            ),
          );
      await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              bankId: bankId,
              userId: d.Value(userId),
              loanId: d.Value(loanId),
              amount: -principalAmount,
              type: 'پرداخت وام به کاربر',
              note: d.Value(note),
            ),
          );
      return loanId;
    });
  }

  Future<void> updateLoan({
    required int id,
    required int userId,
    required int principalAmount,
    required int installments,
    String? note,
  }) async {
    await (db.update(db.loans)..where((l) => l.id.equals(id))).write(
      LoansCompanion(
        userId: d.Value(userId),
        principalAmount: d.Value(principalAmount),
        installments: d.Value(installments),
        note: d.Value(note),
        updatedAt: d.Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteLoan(int id) async {
    await (db.delete(db.loans)..where((l) => l.id.equals(id))).go();
  }

  Stream<List<(LoanPayment, Transaction, Bank)>> watchPayments(int loanId) {
    final sql = '''
SELECT 
  lp.id AS lp_id, lp.loan_id AS lp_loan_id, lp.transaction_id AS lp_transaction_id, lp.amount AS lp_amount, lp.paid_at AS lp_paid_at,
  t.id AS t_id, t.bank_id AS t_bank_id, t.user_id AS t_user_id, t.amount AS t_amount, t.type AS t_type, t.note AS t_note, t.created_at AS t_created_at, t.updated_at AS t_updated_at,
  b.id AS b_id, b.bank_key AS b_bank_key, b.account_name AS b_account_name, b.account_number AS b_account_number, b.created_at AS b_created, b.updated_at AS b_updated
FROM loan_payments lp
JOIN transactions t ON t.id = lp.transaction_id
JOIN banks b ON b.id = t.bank_id
WHERE lp.loan_id = ?
ORDER BY lp.paid_at DESC, lp.id DESC
''';
    return db
        .customSelect(
          sql,
          variables: [d.Variable.withInt(loanId)],
          readsFrom: {db.loanPayments, db.transactions, db.banks},
        )
        .watch()
        .map(
          (rows) => rows.map((r) {
            final lp = LoanPayment(
              id: r.read<int>('lp_id'),
              loanId: r.read<int>('lp_loan_id'),
              transactionId: r.read<int>('lp_transaction_id'),
              amount: r.read<int>('lp_amount'),
              paidAt: r.read<DateTime>('lp_paid_at'),
            );
            final tr = Transaction(
              id: r.read<int>('t_id'),
              bankId: r.read<int>('t_bank_id'),
              userId: r.readNullable<int>('t_user_id'),
              amount: r.read<int>('t_amount'),
              type: r.read<String>('t_type'),
              note: r.readNullable<String>('t_note'),
              createdAt: r.read<DateTime>('t_created_at'),
              updatedAt: r.readNullable<DateTime>('t_updated_at'),
            );
            final bank = Bank(
              id: r.read<int>('b_id'),
              bankKey: r.read<String>('b_bank_key'),
              accountName: r.read<String>('b_account_name'),
              accountNumber: r.read<String>('b_account_number'),
              createdAt: r.read<DateTime>('b_created'),
              updatedAt: r.readNullable<DateTime>('b_updated'),
            );
            return (lp, tr, bank);
          }).toList(),
        );
  }

  Future<void> addPayment({
    required int loanId,
    required int bankId,
    required int amount,
    String? note,
  }) async {
    // Create a positive transaction for loan installment and attach userId
    // inferred from the loan itself so the user becomes searchable/reportable
    final loan = await (db.select(
      db.loans,
    )..where((l) => l.id.equals(loanId))).getSingle();
    final trId = await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            bankId: bankId,
            userId: d.Value(loan.userId),
            loanId: d.Value(loanId),
            amount: amount,
            type: 'پرداخت قسط وام',
            note: d.Value(note),
          ),
        );
    await db
        .into(db.loanPayments)
        .insert(
          LoanPaymentsCompanion.insert(
            loanId: loanId,
            transactionId: trId,
            amount: amount,
          ),
        );
  }

  Future<int?> getPrincipalBankIdForLoan(int loanId) async {
    const sql = '''
SELECT bank_id
FROM transactions
WHERE loan_id = ? AND amount < 0
ORDER BY created_at ASC, id ASC
LIMIT 1
''';
    final row = await db
        .customSelect(
          sql,
          variables: [d.Variable.withInt(loanId)],
          readsFrom: {db.transactions},
        )
        .getSingleOrNull();
    return row?.read<int>('bank_id');
  }

  Stream<List<(Transaction, Bank)>> watchLoanTransactions(int loanId) {
    const sql = '''
SELECT t.*, b.id AS b_id, b.bank_key, b.account_name, b.account_number, b.created_at AS b_created, b.updated_at AS b_updated
FROM transactions t
JOIN banks b ON b.id = t.bank_id
WHERE t.loan_id = ?
ORDER BY t.created_at DESC, t.id DESC
''';
    return db
        .customSelect(
          sql,
          variables: [d.Variable.withInt(loanId)],
          readsFrom: {db.transactions, db.banks},
        )
        .watch()
        .map(
          (rows) => rows.map((r) {
            final tr = Transaction(
              id: r.read<int>('id'),
              bankId: r.read<int>('bank_id'),
              userId: r.readNullable<int>('user_id'),
              amount: r.read<int>('amount'),
              type: r.read<String>('type'),
              note: r.readNullable<String>('note'),
              createdAt: r.read<DateTime>('created_at'),
              updatedAt: r.readNullable<DateTime>('updated_at'),
            );
            final bank = Bank(
              id: r.read<int>('b_id'),
              bankKey: r.read<String>('bank_key'),
              accountName: r.read<String>('account_name'),
              accountNumber: r.read<String>('account_number'),
              createdAt: r.read<DateTime>('b_created'),
              updatedAt: r.readNullable<DateTime>('b_updated'),
            );
            return (tr, bank);
          }).toList(),
        );
  }
}
