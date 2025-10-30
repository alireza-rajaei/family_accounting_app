class JalaliDate {
  final int year;
  final int month;
  final int day;
  const JalaliDate(this.year, this.month, this.day);
  @override
  String toString() => '$year/$month/$day';
}

class JalaliUtils {
  // Converts a Gregorian date to Jalali (algorithm based on khayam algorithm)
  static JalaliDate fromDateTime(DateTime date) {
    int gy = date.year;
    int gm = date.month;
    int gd = date.day;
    final g_d_m = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
    int jy = (gy <= 1600) ? 0 : 979;
    gy -= (gy <= 1600) ? 621 : 1600;
    int gy2 = (gm > 2) ? (gy + 1) : gy;
    int days =
        (365 * gy) +
        ((gy2 + 3) ~/ 4) -
        ((gy2 + 99) ~/ 100) +
        ((gy2 + 399) ~/ 400) -
        80 +
        gd +
        g_d_m[gm - 1];
    jy += 33 * (days ~/ 12053);
    days %= 12053;
    jy += 4 * (days ~/ 1461);
    days %= 1461;
    if (days > 365) {
      jy += (days - 1) ~/ 365;
      days = (days - 1) % 365;
    }
    int jm = (days < 186) ? 1 + (days ~/ 31) : 7 + ((days - 186) ~/ 30);
    int jd = 1 + ((days < 186) ? (days % 31) : ((days - 186) % 30));
    return JalaliDate(jy, jm, jd);
  }

  static String formatJalali(DateTime date) {
    final j = fromDateTime(date);
    return '${_toFa(j.year)}/${_two(_toFa(j.month))}/${_two(_toFa(j.day))}';
  }

  // Simple ISO-like Gregorian date for non-Persian locales
  static String formatGregorian(DateTime date) {
    String two(int x) => x < 10 ? '0$x' : '$x';
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }

  // Ensure leading zero uses Persian numeral to avoid mixed scripts
  static String _two(String x) => x.length == 1 ? '۰$x' : x;

  static String _toFaNum(String input) {
    const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const fa = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    var out = input;
    for (int i = 0; i < 10; i++) {
      out = out.replaceAll(en[i], fa[i]);
    }
    return out;
  }

  static String _toFa(int number) => _toFaNum(number.toString());
}
