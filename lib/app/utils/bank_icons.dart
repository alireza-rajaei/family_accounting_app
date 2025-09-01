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
      return SvgPicture.asset(path, fit: BoxFit.contain);
    }
    return Image.asset(path, fit: BoxFit.contain);
  }
}
