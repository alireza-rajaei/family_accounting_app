import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/auth_repository.dart';

sealed class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthChecking extends AuthState {
  const AuthChecking();
}

class AuthNeedsSetup extends AuthState {
  const AuthNeedsSetup();
}

class AuthLoggedOut extends AuthState {
  const AuthLoggedOut();
}

class AuthLoggedIn extends AuthState {
  const AuthLoggedIn();
}

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repository;
  AuthCubit(this.repository) : super(const AuthChecking());

  Future<void> check() async {
    final hasAdmin = await repository.hasAnyAdmin();
    if (!hasAdmin) {
      emit(const AuthNeedsSetup());
    } else {
      emit(const AuthLoggedOut());
    }
  }

  Future<bool> setupAndLogin(String username, String password) async {
    await repository.createInitialAdmin(username, password);
    final ok = await repository.login(username, password);
    if (ok) emit(const AuthLoggedIn());
    return ok;
  }

  Future<bool> login(String username, String password) async {
    final ok = await repository.login(username, password);
    if (ok) emit(const AuthLoggedIn());
    return ok;
  }
}


