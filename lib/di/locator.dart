import 'package:get_it/get_it.dart';

import '../data/local/db/app_database.dart';

final GetIt locator = GetIt.instance;

Future<void> setupLocator() async {
  locator.registerLazySingleton<AppDatabase>(() => AppDatabase());
}


