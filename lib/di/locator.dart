import 'package:get_it/get_it.dart';

import '../data/local/db/app_database.dart';
import '../domain/repositories/i_auth_repository.dart';
import '../domain/repositories/i_users_repository.dart';
import '../domain/repositories/i_banks_repository.dart';
import '../domain/repositories/i_transactions_repository.dart';
import '../domain/repositories/i_loans_repository.dart';
import '../domain/repositories/i_backup_repository.dart';
import '../data/adapters/auth_repository_adapter.dart';
import '../data/adapters/users_repository_adapter.dart';
import '../data/adapters/banks_repository_adapter.dart';
import '../data/adapters/transactions_repository_adapter.dart';
import '../data/adapters/loans_repository_adapter.dart';
import '../data/adapters/backup_repository_adapter.dart';
import '../domain/usecases/users_usecases.dart';
import '../domain/usecases/banks_usecases.dart';
import '../domain/usecases/transactions_usecases.dart';
import '../domain/usecases/loans_usecases.dart';

final GetIt locator = GetIt.instance;

Future<void> setupLocator() async {
  locator.registerLazySingleton<AppDatabase>(() => AppDatabase());

  locator.registerLazySingleton<IAuthRepository>(
    () => AuthRepositoryAdapter(locator<AppDatabase>()),
  );
  locator.registerLazySingleton<IUsersRepository>(
    () => UsersRepositoryAdapter(locator<AppDatabase>()),
  );
  locator.registerLazySingleton<IBanksRepository>(
    () => BanksRepositoryAdapter(locator<AppDatabase>()),
  );
  locator.registerLazySingleton<ITransactionsRepository>(
    () => TransactionsRepositoryAdapter(locator<AppDatabase>()),
  );
  locator.registerLazySingleton<ILoansRepository>(
    () => LoansRepositoryAdapter(locator<AppDatabase>()),
  );
  locator.registerLazySingleton<IBackupRepository>(
    () => BackupRepositoryAdapter(locator<AppDatabase>()),
  );

  locator.registerLazySingleton(() => WatchUsersUseCase(locator()));
  locator.registerLazySingleton(() => AddUserUseCase(locator()));
  locator.registerLazySingleton(() => UpdateUserUseCase(locator()));
  locator.registerLazySingleton(() => DeleteUserCascadeUseCase(locator()));
  locator.registerLazySingleton(() => GetUserBalanceUseCase(locator()));

  locator.registerLazySingleton(() => WatchBanksWithBalanceUseCase(locator()));
  locator.registerLazySingleton(() => AddBankUseCase(locator()));
  locator.registerLazySingleton(() => UpdateBankUseCase(locator()));
  locator.registerLazySingleton(() => DeleteBankUseCase(locator()));

  locator.registerLazySingleton(() => WatchTransactionsUseCase(locator()));
  locator.registerLazySingleton(() => FetchTransactionsUseCase(locator()));
  locator.registerLazySingleton(() => AddTransactionUseCase(locator()));
  locator.registerLazySingleton(() => UpdateTransactionUseCase(locator()));
  locator.registerLazySingleton(() => DeleteTransactionUseCase(locator()));
  locator.registerLazySingleton(() => TransferBetweenBanksUseCase(locator()));
  locator.registerLazySingleton(() => WatchBankFlowSumsUseCase(locator()));

  locator.registerLazySingleton(() => WatchLoansUseCase(locator()));
  locator.registerLazySingleton(() => AddLoanWithTransactionUseCase(locator()));
  locator.registerLazySingleton(() => UpdateLoanUseCase(locator()));
  locator.registerLazySingleton(() => DeleteLoanUseCase(locator()));
  locator.registerLazySingleton(() => WatchPaymentsUseCase(locator()));
  locator.registerLazySingleton(() => AddPaymentUseCase(locator()));
  locator.registerLazySingleton(
    () => GetPrincipalBankIdForLoanUseCase(locator()),
  );
  locator.registerLazySingleton(() => WatchLoanTransactionsUseCase(locator()));
}
