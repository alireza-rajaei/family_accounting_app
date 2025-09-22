import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/bank.dart';
import '../../domain/usecases/banks_usecases.dart';

class BanksState extends Equatable {
  final List<BankWithBalanceEntity> banks;
  final String query;
  final bool loading;
  const BanksState({
    this.banks = const [],
    this.query = '',
    this.loading = false,
  });

  BanksState copyWith({
    List<BankWithBalanceEntity>? banks,
    String? query,
    bool? loading,
  }) {
    return BanksState(
      banks: banks ?? this.banks,
      query: query ?? this.query,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props => [banks, query, loading];
}

class BanksCubit extends Cubit<BanksState> {
  final WatchBanksWithBalanceUseCase _watch;
  final AddBankUseCase _add;
  final UpdateBankUseCase _update;
  final DeleteBankUseCase _delete;
  StreamSubscription<List<BankWithBalanceEntity>>? _sub;
  BanksCubit(this._watch, this._add, this._update, this._delete)
    : super(const BanksState());

  void watch([String q = '']) {
    _sub?.cancel();
    emit(state.copyWith(loading: true, query: q));
    _sub = _watch(query: q).listen((data) {
      emit(state.copyWith(banks: data, loading: false));
    });
  }

  Future<void> addBank({
    required String bankKey,
    required String accountName,
    required String accountNumber,
  }) async {
    await _add(
      bankKey: bankKey,
      accountName: accountName,
      accountNumber: accountNumber,
    );
  }

  Future<void> updateBank({
    required int id,
    required String bankKey,
    required String accountName,
    required String accountNumber,
  }) async {
    await _update(
      id: id,
      bankKey: bankKey,
      accountName: accountName,
      accountNumber: accountNumber,
    );
  }

  Future<void> deleteBank(int id) async {
    await _delete(id);
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
