import 'package:intl/intl.dart';

String formatThousands(int value) {
  final formatter = NumberFormat.decimalPattern('en');
  return formatter.format(value);
}
