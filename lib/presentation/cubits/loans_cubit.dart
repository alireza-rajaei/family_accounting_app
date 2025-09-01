import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/local/db/app_database.dart';
import '../../data/repositories/loans_repository.dart';

class LoansState extends Equatable {
  final List<LoanWithStats> items;
  final bool loading;
  const LoansState({this.items = const [], this.loading = false});

  LoansState copyWith({List<LoanWithStats>? items, bool? loading}) =>
      LoansState(items: items ?? this.items, loading: loading ?? this.loading);
  @override
  List<Object?> get props => [items, loading];
}

class LoansCubit extends Cubit<LoansState> {
  final LoansRepository repository;
  StreamSubscription<List<LoanWithStats>>? _sub;
  LoansCubit(this.repository) : super(const LoansState());

  void watch() {
    _sub?.cancel();
    emit(state.copyWith(loading: true));
    _sub = repository.watchLoans().listen((data) {
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
    await repository.addLoanWithTransaction(
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
    await repository.updateLoan(
      id: id,
      userId: userId,
      principalAmount: principalAmount,
      installments: installments,
      note: note,
    );
  }

  Future<void> deleteLoan(int id) async {
    await repository.deleteLoan(id);
  }

  Stream<List<(LoanPayment, Transaction, Bank)>> watchPayments(int loanId) =>
      repository.watchPayments(loanId);

  Future<void> addPayment({
    required int loanId,
    required int bankId,
    required int amount,
    String? note,
  }) => repository.addPayment(
    loanId: loanId,
    bankId: bankId,
    amount: amount,
    note: note,
  );

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
