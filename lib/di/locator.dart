import 'package:get_it/get_it.dart';

import '../data/local/db/app_database.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/users_repository.dart';
import '../data/repositories/banks_repository.dart';

final GetIt locator = GetIt.instance;

Future<void> setupLocator() async {
  locator.registerLazySingleton<AppDatabase>(() => AppDatabase());
  locator.registerLazySingleton<AuthRepository>(
    () => AuthRepository(locator<AppDatabase>()),
  );
  locator.registerLazySingleton<UsersRepository>(
    () => UsersRepository(locator<AppDatabase>()),
  );
  locator.registerLazySingleton<BanksRepository>(
    () => BanksRepository(locator<AppDatabase>()),
  );
}
