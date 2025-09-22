import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/transaction.dart';
import '../../domain/usecases/transactions_usecases.dart';

class TransactionsState extends Equatable {
  final List<TransactionAggregate> items;
  final TransactionsFilterEntity filter;
  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final int offset;
  const TransactionsState({
    this.items = const [],
    this.filter = const TransactionsFilterEntity(),
    this.loading = false,
    this.loadingMore = false,
    this.hasMore = true,
    this.offset = 0,
  });

  TransactionsState copyWith({
    List<TransactionAggregate>? items,
    TransactionsFilterEntity? filter,
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
  final FetchTransactionsUseCase _fetch;
  final AddTransactionUseCase _add;
  final UpdateTransactionUseCase _update;
  final DeleteTransactionUseCase _delete;
  final TransferBetweenBanksUseCase _transfer;
  StreamSubscription<List<TransactionAggregate>>? _sub;
  TransactionsCubit(
    this._fetch,
    this._add,
    this._update,
    this._delete,
    this._transfer,
  ) : super(const TransactionsState());

  void watch([TransactionsFilterEntity? filter]) {
    _sub?.cancel();
    final next = filter ?? state.filter;
    emit(state.copyWith(loading: true, filter: next, offset: 0, hasMore: true));
    _loadPage(reset: true);
  }

  void updateFilter(TransactionsFilterEntity filter) => watch(filter);

  Future<void> add({
    required int bankId,
    int? userId,
    required int amount,
    required String type,
    String? note,
    DateTime? createdAt,
  }) async {
    await _add(
      bankId: bankId,
      userId: userId,
      amount: amount,
      type: type,
      note: note,
      createdAt: createdAt,
    );
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
    await _update(
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
    await _delete(id);
    await _loadPage(reset: true);
  }

  Future<void> transferBetweenBanks({
    required int fromBankId,
    required int toBankId,
    required int amount,
    String? note,
  }) async {
    await _transfer(
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
    final data = await _fetch(
      state.filter,
      limit: _pageSize,
      offset: nextOffset,
    );
    final List<TransactionAggregate> combined = reset
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
    final threshold = (state.items.length * 0.8).floor();
    if (currentIndex >= threshold) {
      await _loadPage();
    }
  }
}
