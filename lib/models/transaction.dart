enum TransactionType {
  income,
  expense,
  transfer,
  cardPayment,
}

class TransactionModel {
  final String id;
  final TransactionType type;
  final double amount;
  final String categoryId;
  final String accountId;
  final String? toAccountId;
  final String note;
  final DateTime date;

  TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.accountId,
    this.toAccountId,
    required this.note,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'amount': amount,
      'categoryId': categoryId,
      'accountId': accountId,
      'toAccountId': toAccountId,
      'note': note,
      'date': date.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(
    Map<String, dynamic> map,
  ) {
    final savedType = map['type'] as String;

    return TransactionModel(
      id: map['id'] as String,
      type: TransactionType.values.firstWhere(
        (type) => type.name == savedType,
        orElse: () => TransactionType.expense,
      ),
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['categoryId'] as String,
      accountId: map['accountId'] as String,
      toAccountId: map['toAccountId'] as String?,
      note: map['note'] as String,
      date: DateTime.parse(map['date'] as String),
    );
  }
}