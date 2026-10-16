import 'package:easy_localization/easy_localization.dart';

String formatThousands(int value) {
  final formatter = NumberFormat.decimalPattern('en');
  return formatter.format(value);
}

/// Formatted amount with the localized Rial suffix.
String formatAmount(int value) {
  return '${formatThousands(value)} ${tr('banks.rial')}';
}
