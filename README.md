## Family Accounting App

A Flutter-based family accounting application focused on Clean Architecture, high performance, and top-notch UX with full Farsi/English support.

### Table of Contents
- **Features**
- **Tech Stack**
- **Architecture**
- **Project Tree**
- **Quick Start**
- **State Management (Bloc)**
- **Navigation (GoRouter)**
- **Localization (easy_localization)**
- **Database (Drift + SQLite)**
- **App Icon & Splash Screen**
- **Useful Commands**
- **Assets**

---

### Features
- **State management with Bloc**: predictable, testable data flow.
- **Clean Architecture**: clearly separated layers for easier scaling and maintenance.
- **Modern navigation with GoRouter**: simple, declarative, type-safe routing.
- **Internationalization with easy_localization**: full Farsi/English support.
- **Typed local database with Drift + SQLite**: robust data layer with code generation.
- **Charts and analytics** with `fl_chart`.
- **Backup/Share** with `share_plus` and **PDF export** with `pdf`.
- **File picking, URL launching, contacts** via `file_picker`, `url_launcher`, `flutter_contacts`.
- **Persian calendar support** via `persian_datetime_picker` and `shamsi_date`.

---

### Tech Stack
- **Flutter SDK**: 3.8.x (Dart SDK: ^3.8.1)
- **State Management**: `flutter_bloc` (8.1.6) + `equatable`
- **Navigation**: `go_router` (14.2.7)
- **Dependency Injection**: `get_it` + `injectable` (+ codegen)
- **Database**: `drift` (2.20.3) + `sqlite3` + `sqlite3_flutter_libs`
- **Localization**: `easy_localization` + `flutter_localizations`
- **Storage/Prefs**: `shared_preferences`
- **Intl/Formatting**: `intl`; Persian dates: `shamsi_date`, `persian_datetime_picker`
- **UI/UX**: `google_fonts`, `iconsax`, `flutter_svg`, charts: `fl_chart`
- **OS/Device**: `path`, `path_provider`, `package_info_plus`, `url_launcher`
- **I/O & Share**: `file_picker`, `share_plus`, `pdf`
- **Contacts**: `flutter_contacts`
- **Security/Utils**: `crypto`
- **Dev tools**: `build_runner`, `injectable_generator`, `drift_dev`, `flutter_lints`, `flutter_launcher_icons`, `flutter_native_splash`, `image`

All versions are aligned with `pubspec.yaml`.

---

### Architecture
Organized according to **Clean Architecture**:
- `domain/`: entities, repository interfaces, and use cases (framework-independent).
- `data/`: repository implementations, data sources (Drift/SQLite), and mappers.
- `presentation/`: UI pages and Bloc Cubits.
- `di/`: dependency registration via `get_it` and `injectable`.
- `app/`: theme, colors, typography, and app-level utilities.

---

### Project Tree
```text
lib/
  app/
    app.dart
    theme/
      app_colors.dart
      app_theme.dart
      app_typography.dart
    utils/
      bank_icons.dart
      format.dart
      jalali_utils.dart
      thousands_input_formatter.dart
      utilitys.dart
  data/
    adapters/
      auth_repository_adapter.dart
      backup_repository_adapter.dart
      banks_repository_adapter.dart
      loans_repository_adapter.dart
      transactions_repository_adapter.dart
      users_repository_adapter.dart
    local/
      db/
        app_database.dart
        app_database.g.dart
        connection/
          connection_native.dart
          connection_web.dart
          connection.dart
        tables/
          admins.dart
          banks.dart
          loan_payments.dart
          loans.dart
          transaction_type.dart
          transactions.dart
          users.dart
        tables.dart
    mappers/
      domain_mappers.dart
    repositories/
      auth_repository.dart
      backup_repository.dart
      banks_repository.dart
      loans_repository.dart
      transactions_repository.dart
      users_repository.dart
  di/
    locator.dart
  domain/
    entities/
      bank.dart
      loan.dart
      transaction.dart
      user.dart
    repositories/
      i_auth_repository.dart
      i_backup_repository.dart
      i_banks_repository.dart
      i_loans_repository.dart
      i_transactions_repository.dart
      i_users_repository.dart
    usecases/
      banks_usecases.dart
      loans_usecases.dart
      transactions_usecases.dart
      users_usecases.dart
  presentation/
    cubits/
      auth_cubit.dart
      banks_cubit.dart
      loans_cubit.dart
      settings_cubit.dart
      transactions_cubit.dart
      users_cubit.dart
    pages/
      banks_page.dart
      home_page_stat_tile.dart
      home_page_view.dart
      home_page.dart
      loans_page.dart
      login_page.dart
      sheet/
        transactions_destination_bank_dropdown.dart
        transactions_searchable_bank_field.dart
        transactions_searchable_destination_bank_field.dart
        transactions_searchable_user_field.dart
        transactions_sheet_helpers.dart
        transactions_transaction_sheet_state.dart
        transactions_transaction_sheet.dart
      shell.dart
      transactions_bank_picker.dart
      transactions_date_range_picker.dart
      transactions_filters_bar.dart
      transactions_page_view.dart
      transactions_page.dart
      transactions_user_picker.dart
      users_page.dart
    router/
      app_router.dart
  main.dart
```

---

### Quick Start
Requirements:
- Flutter SDK 3.8.x with Dart as specified in `environment`.

Commands:
```bash
flutter pub get

# Code generation for Drift and Injectable
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

Build release:
```bash
# Android
flutter build apk --release

# iOS (requires macOS/Xcode)
flutter build ios --release
```

---

### State Management (Bloc)
- Cubits live in `lib/presentation/cubits/`.
- Each Cubit depends on data-layer repositories via DI (`get_it`).
- States implement `equatable` for efficient comparisons.

Tip: when adding a new Cubit, register dependencies in `di/locator.dart` and optionally use `injectable` for code-generated wiring.

---

### Navigation (GoRouter)
- Routes are configured in `lib/presentation/router/app_router.dart`.
- The app uses a shell route pattern for the main scaffold and nested pages.

---

### Localization (easy_localization)
- Translation files are under `assets/translations/` (e.g., `fa.json`, `en.json`).
- When adding keys, update all supported locale files.
- At runtime, use `easy_localization` APIs to switch locales.

Ensure `flutter_localizations` and `easy_localization` are initialized in your `App`/`MaterialApp`.

---

### Database (Drift + SQLite)
- Tables/DAOs are defined under `lib/data/local/db/tables/` and `app_database.dart`.
- Drift generates type-safe code (`app_database.g.dart`) via `build_runner`.
- Platform-specific connections are implemented under `local/db/connection/`.

After changing any table:
```bash
dart run build_runner build --delete-conflicting-outputs
```

---

### App Icon & Splash Screen
Configured in `pubspec.yaml` under `flutter_launcher_icons` and `flutter_native_splash`.

Generate app icons:
```bash
dart run flutter_launcher_icons
```

Generate splash screen:
```bash
dart run flutter_native_splash:create
```

---

### Useful Commands
```bash
# Upgrade packages
flutter pub upgrade --major-versions

# Code generation in watch mode
dart run build_runner watch --delete-conflicting-outputs
```

---

### Assets
- Fonts and icons under `assets/fonts/` and `assets/icons/`.
- Logos and bank assets under `assets/logos/` and `assets/banks/`.
- Translations under `assets/translations/`.

Ensure asset paths are listed in `pubspec.yaml` under `flutter > assets`.

---

Contributions and suggestions are welcome.
