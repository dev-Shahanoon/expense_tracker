import 'package:flutter/material.dart';

class BankLogo extends StatelessWidget {
  final String? bankName;
  final double size;

  const BankLogo({super.key, required this.bankName, this.size = 44});

  static const Map<String, String> _logos = {
    'sbi': 'assets/banks/sbi.png',
    'state bank of india': 'assets/banks/sbi.png',
    'hdfc': 'assets/banks/hdfc.png',
    'icici': 'assets/banks/icici.png',
    'axis': 'assets/banks/axis.png',
    'kotak': 'assets/banks/kotak.png',
    'indusind': 'assets/banks/indusind.png',
    'yes bank': 'assets/banks/yes_bank.png',
    'federal': 'assets/banks/federal.png',
    'canara': 'assets/banks/canara.png',
    'punjab national bank': 'assets/banks/pnb.png',
    'pnb': 'assets/banks/pnb.png',
    'bank of baroda': 'assets/banks/bob.png',
    'bob': 'assets/banks/bob.png',
  };

  String? _findLogo(String name) {
    // Prefer longer matches to avoid matching a short name first.
    final keys = _logos.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final key in keys) {
      if (name == key || name.contains(key)) {
        return _logos[key];
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final normalized = (bankName ?? '').trim().toLowerCase();
    final assetPath = _findLogo(normalized);

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: assetPath == null
          ? Icon(
              Icons.account_balance_rounded,
              color: const Color(0xFF087D72),
              size: size * 0.62,
            )
          : Image.asset(
              assetPath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.account_balance_rounded,
                  color: const Color(0xFF087D72),
                  size: size * 0.62,
                );
              },
            ),
    );
  }
}
