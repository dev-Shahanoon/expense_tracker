class MoneyLent {
  final String id;
  final String personName;
  final String contact;
  final double amount;
  final DateTime lentDate;
  final DateTime? dueDate;
  final String accountId;
  final String note;

  const MoneyLent({
    required this.id,
    required this.personName,
    this.contact = '',
    required this.amount,
    required this.lentDate,
    this.dueDate,
    required this.accountId,
    this.note = '',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'personName': personName,
    'contact': contact,
    'amount': amount,
    'lentDate': lentDate.toIso8601String(),
    'dueDate': dueDate?.toIso8601String(),
    'accountId': accountId,
    'note': note,
  };

  factory MoneyLent.fromMap(Map<String, dynamic> map) {
    return MoneyLent(
      id: map['id'] as String,
      personName: map['personName'] as String,
      contact: (map['contact'] as String?) ?? '',
      amount: (map['amount'] as num).toDouble(),
      lentDate: DateTime.parse(map['lentDate'] as String),
      dueDate: map['dueDate'] == null
          ? null
          : DateTime.tryParse(map['dueDate'] as String),
      accountId: map['accountId'] as String,
      note: (map['note'] as String?) ?? '',
    );
  }
}
