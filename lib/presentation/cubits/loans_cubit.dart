import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/loan.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/bank.dart';
import '../../domain/usecases/loans_usecases.dart';

class LoansState extends Equatable {
  final List<LoanWithStatsEntity> items;
  final bool loading;
  const LoansState({this.items = const [], this.loading = false});

  LoansState copyWith({List<LoanWithStatsEntity>? items, bool? loading}) =>
      LoansState(items: items ?? this.items, loading: loading ?? this.loading);
  @override
  List<Object?> get props => [items, loading];
}

class LoansCubit extends Cubit<LoansState> {
  final WatchLoansUseCase _watchLoans;
  final AddLoanWithTransactionUseCase _addLoanWithTx;
  final UpdateLoanUseCase _updateLoan;
  final DeleteLoanUseCase _deleteLoan;
  final WatchPaymentsUseCase _watchPayments;
  final AddPaymentUseCase _addPayment;
  final GetPrincipalBankIdForLoanUseCase _getPrincipalBank;
  final WatchLoanTransactionsUseCase _watchLoanTransactions;
  StreamSubscription<List<LoanWithStatsEntity>>? _sub;
  LoansCubit(
    this._watchLoans,
    this._addLoanWithTx,
    this._updateLoan,
    this._deleteLoan,
    this._watchPayments,
    this._addPayment,
    this._getPrincipalBank,
    this._watchLoanTransactions,
  ) : super(const LoansState());

  Stream<List<LoanWithStatsEntity>> watchLoans() => _watchLoans();

  void watch() {
    _sub?.cancel();
    emit(state.copyWith(loading: true));
    _sub = _watchLoans().listen((data) {
      emit(state.copyWith(items: data, loading: false));
    });
  }

  Future<void> addLoan({
    required int userId,
    required int bankId,
    required int principalAmount,
    required int installments,
    String? note,
  }) async {
    await _addLoanWithTx(
      userId: userId,
      bankId: bankId,
      principalAmount: principalAmount,
      installments: installments,
      note: note,
    );
  }

  Future<void> updateLoan({
    required int id,
    required int userId,
    required int principalAmount,
    required int installments,
    String? note,
  }) async {
    await _updateLoan(
      id: id,
      userId: userId,
      principalAmount: principalAmount,
      installments: installments,
      note: note,
    );
  }

  Future<void> deleteLoan(int id) async {
    await _deleteLoan(id);
  }

  Stream<List<(LoanPaymentEntity, TransactionEntity, BankEntity)>>
  watchPayments(int loanId) => _watchPayments(loanId);

  Future<void> addPayment({
    required int loanId,
    required int bankId,
    required int amount,
    String? note,
  }) => _addPayment(loanId: loanId, bankId: bankId, amount: amount, note: note);

  Future<int?> getPrincipalBankIdForLoan(int loanId) =>
      _getPrincipalBank(loanId);

  Stream<List<(TransactionEntity, BankEntity)>> watchLoanTransactions(
    int loanId,
  ) => _watchLoanTransactions(loanId);

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
