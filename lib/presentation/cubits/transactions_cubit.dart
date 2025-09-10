import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/transactions_repository.dart';

class TransactionsState extends Equatable {
  final List<TransactionWithJoins> items;
  final TransactionsFilter filter;
  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final int offset;
  const TransactionsState({
    this.items = const [],
    this.filter = const TransactionsFilter(),
    this.loading = false,
    this.loadingMore = false,
    this.hasMore = true,
    this.offset = 0,
  });

  TransactionsState copyWith({
    List<TransactionWithJoins>? items,
    TransactionsFilter? filter,
    bool? loading,
    bool? loadingMore,
    bool? hasMore,
    int? offset,
  }) {
    return TransactionsState(
      items: items ?? this.items,
      filter: filter ?? this.filter,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
    );
  }

  @override
  List<Object?> get props => [
    items,
    filter,
    loading,
    loadingMore,
    hasMore,
    offset,
  ];
}

class TransactionsCubit extends Cubit<TransactionsState> {
  final TransactionsRepository repository;
  StreamSubscription<List<TransactionWithJoins>>? _sub;
  TransactionsCubit(this.repository) : super(const TransactionsState());

  void watch([TransactionsFilter? filter]) {
    _sub?.cancel();
    final next = filter ?? state.filter;
    emit(state.copyWith(loading: true, filter: next, offset: 0, hasMore: true));
    // Initial page load (non-streaming) to support pagination
    _loadPage(reset: true);
  }

  void updateFilter(TransactionsFilter filter) => watch(filter);

  Future<void> add({
    required int bankId,
    int? userId,
    required int amount,
    required String type,
    String? note,
    DateTime? createdAt,
  }) async {
    await repository.addTransaction(
      bankId: bankId,
      userId: userId,
      amount: amount,
      type: type,
      note: note,
      createdAt: createdAt,
    );
    // Optimistic refresh from start to keep order consistent
    await _loadPage(reset: true);
  }

  Future<void> update({
    required int id,
    required int bankId,
    int? userId,
    required int amount,
    required String type,
    String? note,
  }) async {
    await repository.updateTransaction(
      id: id,
      bankId: bankId,
      userId: userId,
      amount: amount,
      type: type,
      note: note,
    );
    await _loadPage(reset: true);
  }

  Future<void> delete(int id) async {
    await repository.deleteTransaction(id);
    await _loadPage(reset: true);
  }

  Future<void> transferBetweenBanks({
    required int fromBankId,
    required int toBankId,
    required int amount,
    String? note,
  }) async {
    await repository.transferBetweenBanks(
      fromBankId: fromBankId,
      toBankId: toBankId,
      amount: amount,
      note: note,
    );
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }

  static const int _pageSize = 50;

  Future<void> _loadPage({bool reset = false}) async {
    if (state.loadingMore) return;
    final int nextOffset = reset ? 0 : state.offset;
    if (!reset && !state.hasMore) return;
    emit(state.copyWith(loadingMore: true));
    final data = await repository.fetchTransactions(
      state.filter,
      limit: _pageSize,
      offset: nextOffset,
    );
    final List<TransactionWithJoins> combined = reset
        ? data
        : [...state.items, ...data];
    emit(
      state.copyWith(
        items: combined,
        loading: false,
        loadingMore: false,
        offset: nextOffset + data.length,
        hasMore: data.length == _pageSize,
      ),
    );
  }

  Future<void> loadMoreIfNeeded(int currentIndex) async {
    // Prefetch when user passes 80% of current items
    final threshold = (state.items.length * 0.8).floor();
    if (currentIndex >= threshold) {
      await _loadPage();
    }
  }
}
