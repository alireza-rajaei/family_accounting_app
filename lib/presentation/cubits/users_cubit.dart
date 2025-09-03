import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/local/db/app_database.dart';
import '../../data/repositories/users_repository.dart';

class UsersState extends Equatable {
  final List<User> users;
  final String query;
  final bool loading;
  const UsersState({
    this.users = const [],
    this.query = '',
    this.loading = false,
  });

  UsersState copyWith({List<User>? users, String? query, bool? loading}) {
    return UsersState(
      users: users ?? this.users,
      query: query ?? this.query,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props => [users, query, loading];
}

class UsersCubit extends Cubit<UsersState> {
  final UsersRepository repository;
  StreamSubscription<List<User>>? _sub;
  UsersCubit(this.repository) : super(const UsersState());

  void watch([String q = '']) {
    _sub?.cancel();
    emit(state.copyWith(loading: true, query: q));
    _sub = repository.watchUsers(q).listen((data) {
      emit(state.copyWith(users: data, loading: false));
    });
  }

  Future<void> addUser({
    required String firstName,
    required String lastName,
    String? fatherName,
    String? mobile,
  }) async {
    await repository.addUser(
      firstName: firstName,
      lastName: lastName,
      fatherName: fatherName,
      mobileNumber: mobile,
    );
  }

  Future<void> updateUser({
    required int id,
    required String firstName,
    required String lastName,
    String? fatherName,
    String? mobile,
  }) async {
    await repository.updateUser(
      id: id,
      firstName: firstName,
      lastName: lastName,
      fatherName: fatherName,
      mobileNumber: mobile,
    );
  }

  Future<void> deleteUser(int id) async {
    await repository.deleteUser(id);
  }

  Future<int> getUserBalance(int userId) => repository.getUserBalance(userId);

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
