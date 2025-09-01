import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/banks_repository.dart';

class BanksState extends Equatable {
  final List<BankWithBalance> banks;
  final String query;
  final bool loading;
  const BanksState({this.banks = const [], this.query = '', this.loading = false});

  BanksState copyWith({List<BankWithBalance>? banks, String? query, bool? loading}) {
    return BanksState(banks: banks ?? this.banks, query: query ?? this.query, loading: loading ?? this.loading);
  }

  @override
  List<Object?> get props => [banks, query, loading];
}

class BanksCubit extends Cubit<BanksState> {
  final BanksRepository repository;
  StreamSubscription<List<BankWithBalance>>? _sub;
  BanksCubit(this.repository) : super(const BanksState());

  void watch([String q = '']) {
    _sub?.cancel();
    emit(state.copyWith(loading: true, query: q));
    _sub = repository.watchBanksWithBalance(query: q).listen((data) {
      emit(state.copyWith(banks: data, loading: false));
    });
  }

  Future<void> addBank({required String bankKey, required String bankName, required String accountName, required String accountNumber}) async {
    await repository.addBank(bankKey: bankKey, bankName: bankName, accountName: accountName, accountNumber: accountNumber);
  }

  Future<void> updateBank({required int id, required String bankKey, required String bankName, required String accountName, required String accountNumber}) async {
    await repository.updateBank(id: id, bankKey: bankKey, bankName: bankName, accountName: accountName, accountNumber: accountNumber);
  }

  Future<void> deleteBank(int id) async {
    await repository.deleteBank(id);
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}


