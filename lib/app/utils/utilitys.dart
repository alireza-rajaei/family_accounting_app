import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shamsi_date/shamsi_date.dart';

class Utilitys {
  const Utilitys._();

  static String formatCurrency(int value) {
    final s = value.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idx = s.length - i - 1;
      buf.write(s[idx]);
      if (i % 3 == 2 && idx != 0) buf.write(',');
    }
    final str = buf.toString().split('').reversed.join();
    return (value < 0 ? '-' : '') + str;
  }

  static String cleanPhone(String input) {
    String s = toEnglishDigits(input).trim();
    s = s.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    s = s.replaceAll(RegExp(r'[^0-9\+]'), '');
    if (s.startsWith('+98')) {
      s = '0' + s.substring(3);
    } else if (s.startsWith('0098')) {
      s = '0' + s.substring(4);
    } else if (s.startsWith('98')) {
      s = '0' + s.substring(2);
    }
    if (s.startsWith('9') && s.length >= 10) {
      s = '0' + s;
    }
    s = s.replaceAll(RegExp(r'[^0-9]'), '');
    s = s.replaceFirst(RegExp(r'^00+'), '0');
    return s;
  }

  static String toEnglishDigits(String input) {
    const String fa = '۰۱۲۳۴۵۶۷۸۹';
    const String ar = '٠١٢٣٤٥٦٧٨٩';
    return input.replaceAllMapped(RegExp('[\u06F0-\u06F9\u0660-\u0669]'), (m) {
      final String ch = m.group(0)!;
      int idx = fa.indexOf(ch);
      if (idx == -1) idx = ar.indexOf(ch);
      return idx >= 0 ? idx.toString() : ch;
    });
  }

  static String formatJalaliFull(DateTime dt) {
    final j = dt.toJalali();
    final w = j.formatter.wN;
    final d = j.day.toString();
    final m = j.formatter.mN;
    final y = (j.year % 1000).toString();
    return '$w $d $m $y';
  }

  static String formatLastLogin(BuildContext context, DateTime dt) {
    if (Localizations.localeOf(context).languageCode == 'fa') {
      return formatJalaliFull(dt);
    }
    return DateFormat('EEE, MMM d, yyyy').format(dt);
  }
}
