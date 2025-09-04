import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BankIcons {
  BankIcons._();

  static const Map<String, String> _keyToAsset = {
    'melli': 'assets/banks/Melli.svg',
    'sepah': 'assets/banks/Sepah.svg',
    'mellat': 'assets/banks/Mellat.svg',
    'tejarat': 'assets/banks/Tejarat.svg',
    'saman': 'assets/banks/Saman.svg',
    'pasargad': 'assets/banks/Pasargad.svg',
    'saderat': 'assets/banks/Saderat.svg',
    'refah': 'assets/banks/Refah.svg',
    'keshavarzi': 'assets/banks/Keshavarzi.svg',
    'ayandeh': 'assets/banks/Ayandeh.svg',
  };

  // Brand gradient colors for Iranian banks (approx based on assets)
  static const Map<String, List<Color>> gradients = {
    'ayandeh': [Color(0xFFF4B31B), Color(0xFFCC932B), Color(0xFF6E2616)],
    'keshavarzi': [Color(0xFFECE482), Color(0xFFD8AC4E), Color(0xFF1F261A)],
    'mellat': [Color(0xFFFFC730), Color(0xFFBA0B22)],
    'pasargad': [Color(0xFFFECC09), Color(0xFFB78A04)],
    'refah': [Color(0xFF173576), Color(0xFF0F2550)],
    'saderat': [Color(0xFF2D2A68), Color(0xFF1B184C)],
    'saman': [Color(0xFF7DCDF1), Color(0xFF00AAE7), Color(0xFF006FBA)],
    'sepah': [Color(0xFF1B5FC1), Color(0xFF0E3F8F)],
    'tejarat': [Color(0xFF2F4A98), Color(0xFF1B2D6D)],
    'melli': [Color(0xFFD6A933), Color(0xFF8D6B20)], // approx until confirmed
  };

  // English display names for banks (for card header subtitle)
  static const Map<String, String> englishNames = {
    'melli': 'bank melli',
    'sepah': 'bank sepah',
    'mellat': 'bank mellat',
    'tejarat': 'bank tejarat',
    'saman': 'bank saman',
    'pasargad': 'bank pasargad',
    'saderat': 'bank saderat',
    'refah': 'bank refah',
    'keshavarzi': 'bank keshavarzi',
    'ayandeh': 'bank ayandeh',
  };

  // Persian display names for banks based on key (used across UI after removing bank_name column)
  static const Map<String, String> persianNames = {
    'melli': 'بانک ملی',
    'sepah': 'بانک سپه',
    'mellat': 'بانک ملت',
    'tejarat': 'بانک تجارت',
    'saman': 'بانک سامان',
    'pasargad': 'بانک پاسارگاد',
    'saderat': 'بانک صادرات',
    'refah': 'بانک رفاه',
    'keshavarzi': 'بانک کشاورزی',
    'ayandeh': 'بانک آینده',
    'sandogh': 'صندوق',
  };

  /// Renders the raw bank logo asset (SVG/PNG) at a given size.
  /// If [color] is provided, the logo will be colorized (useful for faded overlays).
  static Widget logo(String bankKey, {double size = 140, Color? color}) {
    final path = _keyToAsset[bankKey];
    if (path == null) {
      return Icon(Icons.account_balance, size: size, color: color);
    }
    if (path.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.contain,
        colorFilter: color == null
            ? null
            : ColorFilter.mode(color, BlendMode.srcIn),
      );
    }
    return Image.asset(
      path,
      width: size,
      height: size,
      fit: BoxFit.contain,
      color: color,
      colorBlendMode: color == null ? null : BlendMode.srcIn,
    );
  }

  static Widget avatar(String bankKey, String name) {
    final path = _keyToAsset[bankKey];
    if (path == null) {
      return CircleAvatar(child: Text(name.characters.first));
    }
    // Use SVG with a fallback if needed
    return CircleAvatar(
      backgroundColor: Colors.transparent,
      child: ClipOval(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: _SvgOrPng(path: path),
        ),
      ),
    );
  }
}

class BankCircleAvatar extends StatelessWidget {
  final String bankKey;
  final String name;
  const BankCircleAvatar({
    super.key,
    required this.bankKey,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return BankIcons.avatar(bankKey, name);
  }
}

class _SvgOrPng extends StatelessWidget {
  final String path;
  const _SvgOrPng({required this.path});
  @override
  Widget build(BuildContext context) {
    if (path.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(path, fit: BoxFit.contain, width: 50, height: 50);
    }
    return Image.asset(path, fit: BoxFit.contain, width: 50, height: 50);
  }
}
