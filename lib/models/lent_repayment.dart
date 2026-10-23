class LentRepayment {
  final String id;
  final String moneyLentId;
  final double amount;
  final DateTime date;
  final String accountId;
  final String? transactionId;
  final String note;

  const LentRepayment({
    required this.id,
    required this.moneyLentId,
    required this.amount,
    required this.date,
    required this.accountId,
    this.transactionId,
    this.note = '',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'moneyLentId': moneyLentId,
    'amount': amount,
    'date': date.toIso8601String(),
    'accountId': accountId,
    'transactionId': transactionId,
    'note': note,
  };

  factory LentRepayment.fromMap(Map<String, dynamic> map) {
    return LentRepayment(
      id: map['id'] as String,
      moneyLentId: map['moneyLentId'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      accountId: map['accountId'] as String,
      transactionId: map['transactionId'] as String?,
      note: (map['note'] as String?) ?? '',
    );
  }
}
