import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/user.dart';
import '../../domain/usecases/users_usecases.dart';

class UsersState extends Equatable {
  final List<UserEntity> users;
  final String query;
  final bool loading;
  const UsersState({
    this.users = const [],
    this.query = '',
    this.loading = false,
  });

  UsersState copyWith({List<UserEntity>? users, String? query, bool? loading}) {
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
  StreamSubscription<List<UserEntity>>? _sub;
  final WatchUsersUseCase _watchUsers;
  final AddUserUseCase _addUser;
  final UpdateUserUseCase _updateUser;
  final DeleteUserCascadeUseCase _deleteUserCascade;
  final GetUserBalanceUseCase _getUserBalance;
  UsersCubit(
    this._watchUsers,
    this._addUser,
    this._updateUser,
    this._deleteUserCascade,
    this._getUserBalance,
  ) : super(const UsersState());

  void watch([String q = '']) {
    _sub?.cancel();
    emit(state.copyWith(loading: true, query: q));
    _sub = _watchUsers(q).listen((data) {
      emit(state.copyWith(users: data, loading: false));
    });
  }

  Future<void> addUser({
    required String firstName,
    required String lastName,
    String? fatherName,
    String? mobile,
  }) async {
    await _addUser(
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
    await _updateUser(
      id: id,
      firstName: firstName,
      lastName: lastName,
      fatherName: fatherName,
      mobileNumber: mobile,
    );
  }

  Future<void> deleteUser(int id) async {
    await _deleteUserCascade(id);
  }

  Future<int> getUserBalance(int userId) => _getUserBalance(userId);

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
