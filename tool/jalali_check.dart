import 'package:shamsi_date/shamsi_date.dart';

void main() {
  final now = DateTime.now();
  final j = now.toJalali();
  print('host DateTime.now(): $now');
  print('host toJalali: ${j.year}-${j.month.toString().padLeft(2, '0')}-${j.day.toString().padLeft(2, '0')}');
  for (final d in [
    DateTime(2026, 10, 16),
    DateTime(2026, 6, 26),
    DateTime(2025, 6, 26),
  ]) {
    final jj = d.toJalali();
    print(
      '$d -> ${jj.year}-${jj.month.toString().padLeft(2, '0')}-${jj.day.toString().padLeft(2, '0')}',
    );
  }
  print('Jalali 1405-04-05 -> ${Jalali(1405, 4, 5).toDateTime()}');
  print('Jalali 1405-07-24 -> ${Jalali(1405, 7, 24).toDateTime()}');
}
