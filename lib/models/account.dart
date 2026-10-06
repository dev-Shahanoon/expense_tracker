class Account {
  final String id;
  final String name;
  final String bankName;
  final String type;
  final double openingBalance;
  final String? lastFourDigits;

  Account({
    required this.id,
    required this.name,
    required this.bankName,
    required this.type,
    required this.openingBalance,
    this.lastFourDigits,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'bankName': bankName,
      'type': type,
      'openingBalance': openingBalance,
      'lastFourDigits': lastFourDigits,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as String,
      name: map['name'] as String,
      bankName: map['bankName'] as String,
      type: map['type'] as String,
      openingBalance: (map['openingBalance'] as num).toDouble(),
      lastFourDigits: map['lastFourDigits'] as String?,
    );
  }
}