import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/transactions_repository.dart';

class TransactionsState extends Equatable {
  final List<TransactionWithJoins> items;
  final TransactionsFilter filter;
  final bool loading;
  const TransactionsState({this.items = const [], this.filter = const TransactionsFilter(), this.loading = false});

  TransactionsState copyWith({List<TransactionWithJoins>? items, TransactionsFilter? filter, bool? loading}) {
    return TransactionsState(items: items ?? this.items, filter: filter ?? this.filter, loading: loading ?? this.loading);
  }

  @override
  List<Object?> get props => [items, filter, loading];
}

class TransactionsCubit extends Cubit<TransactionsState> {
  final TransactionsRepository repository;
  StreamSubscription<List<TransactionWithJoins>>? _sub;
  TransactionsCubit(this.repository) : super(const TransactionsState());

  void watch([TransactionsFilter? filter]) {
    _sub?.cancel();
    final next = filter ?? state.filter;
    emit(state.copyWith(loading: true, filter: next));
    _sub = repository.watchTransactions(next).listen((data) {
      emit(state.copyWith(items: data, loading: false));
    });
  }

  void updateFilter(TransactionsFilter filter) => watch(filter);

  Future<void> add({
    required int bankId,
    int? userId,
    required int amount,
    required String type,
    String? depositKind,
    String? withdrawKind,
    String? note,
    DateTime? createdAt,
  }) async {
    await repository.addTransaction(
      bankId: bankId,
      userId: userId,
      amount: amount,
      type: type,
      depositKind: depositKind,
      withdrawKind: withdrawKind,
      note: note,
      createdAt: createdAt,
    );
  }

  Future<void> update({
    required int id,
    required int bankId,
    int? userId,
    required int amount,
    required String type,
    String? depositKind,
    String? withdrawKind,
    String? note,
  }) async {
    await repository.updateTransaction(
      id: id,
      bankId: bankId,
      userId: userId,
      amount: amount,
      type: type,
      depositKind: depositKind,
      withdrawKind: withdrawKind,
      note: note,
    );
  }

  Future<void> delete(int id) async {
    await repository.deleteTransaction(id);
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}


