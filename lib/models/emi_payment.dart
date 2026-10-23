class EmiPayment {
  final String id;
  final String loanId;
  final int installmentNumber;
  final DateTime dueDate;
  final double amount;
  final double principalComponent;
  final double interestComponent;
  final double paidAmount;
  final DateTime? paidDate;
  final String? transactionId;

  const EmiPayment({
    required this.id,
    required this.loanId,
    required this.installmentNumber,
    required this.dueDate,
    required this.amount,
    required this.principalComponent,
    required this.interestComponent,
    this.paidAmount = 0,
    this.paidDate,
    this.transactionId,
  });

  double get remainingAmount {
    final remaining = amount - paidAmount;
    return remaining > 0.005 ? remaining : 0;
  }

  bool get isPaid => remainingAmount <= 0.005;

  bool get isOverdue =>
      !isPaid &&
      DateTime.now().isAfter(
        DateTime(dueDate.year, dueDate.month, dueDate.day, 23, 59, 59),
      );

  EmiPayment copyWith({
    double? paidAmount,
    DateTime? paidDate,
    bool clearPaidDate = false,
    String? transactionId,
  }) {
    return EmiPayment(
      id: id,
      loanId: loanId,
      installmentNumber: installmentNumber,
      dueDate: dueDate,
      amount: amount,
      principalComponent: principalComponent,
      interestComponent: interestComponent,
      paidAmount: paidAmount ?? this.paidAmount,
      paidDate: clearPaidDate ? null : (paidDate ?? this.paidDate),
      transactionId: transactionId ?? this.transactionId,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'loanId': loanId,
    'installmentNumber': installmentNumber,
    'dueDate': dueDate.toIso8601String(),
    'amount': amount,
    'principalComponent': principalComponent,
    'interestComponent': interestComponent,
    'paidAmount': paidAmount,
    'paidDate': paidDate?.toIso8601String(),
    'transactionId': transactionId,
  };

  factory EmiPayment.fromMap(Map<String, dynamic> map) {
    return EmiPayment(
      id: map['id'] as String,
      loanId: map['loanId'] as String,
      installmentNumber: (map['installmentNumber'] as num).toInt(),
      dueDate: DateTime.parse(map['dueDate'] as String),
      amount: (map['amount'] as num).toDouble(),
      principalComponent: (map['principalComponent'] as num).toDouble(),
      interestComponent: (map['interestComponent'] as num).toDouble(),
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0,
      paidDate: map['paidDate'] == null
          ? null
          : DateTime.tryParse(map['paidDate'] as String),
      transactionId: map['transactionId'] as String?,
    );
  }
}
