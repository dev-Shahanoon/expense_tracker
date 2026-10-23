
class Loan {
  final String id;
  final String name;
  final String lender;

  /// Amount actually borrowed from the lender.
  final double principal;

  /// Down payment made separately from the borrowed principal.
  final double downPayment;

  final double annualInterestRate;
  final int tenureMonths;
  final DateTime startDate;
  final DateTime firstEmiDate;

  /// Recurring EMI day, from 1 to 28.
  final int emiDay;

  final String accountId;
  final String note;

  const Loan({
    required this.id,
    required this.name,
    required this.lender,
    required this.principal,
    this.downPayment = 0,
    required this.annualInterestRate,
    required this.tenureMonths,
    required this.startDate,
    required this.firstEmiDate,
    int? emiDay,
    required this.accountId,
    this.note = '',
  }) : emiDay = emiDay ?? 1;

  bool get isValid =>
      principal.isFinite &&
      principal > 0 &&
      downPayment.isFinite &&
      downPayment >= 0 &&
      annualInterestRate.isFinite &&
      annualInterestRate >= 0 &&
      tenureMonths > 0 &&
      emiDay >= 1 &&
      emiDay <= 28;

  double get monthlyEmi {
    if (!isValid) return 0;

    final monthlyRate = annualInterestRate / 1200;

    if (monthlyRate == 0) {
      return principal / tenureMonths;
    }

    final factor = _power(1 + monthlyRate, tenureMonths);

    return principal * monthlyRate * factor / (factor - 1);
  }

  double get totalRepayment => monthlyEmi * tenureMonths;

  double get totalInterest => totalRepayment - principal;

  /// Total initial purchase funding: borrowed amount + down payment.
  double get totalPurchaseCost => principal + downPayment;

  double _power(double base, int exponent) {
    var result = 1.0;

    for (var i = 0; i < exponent; i++) {
      result *= base;
    }

    return result;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'lender': lender,
      'principal': principal,
      'downPayment': downPayment,
      'annualInterestRate': annualInterestRate,
      'tenureMonths': tenureMonths,
      'startDate': startDate.toIso8601String(),
      'firstEmiDate': firstEmiDate.toIso8601String(),
      'emiDay': emiDay,
      'accountId': accountId,
      'note': note,
    };
  }

  factory Loan.fromMap(Map<String, dynamic> map) {
    final firstEmiDate = DateTime.parse(
      map['firstEmiDate'] as String,
    );

    final storedEmiDay = map['emiDay'];

    return Loan(
      id: map['id'] as String,
      name: map['name'] as String,
      lender: map['lender'] as String,
      principal: (map['principal'] as num).toDouble(),
      downPayment: (map['downPayment'] as num?)?.toDouble() ?? 0,
      annualInterestRate:
          (map['annualInterestRate'] as num).toDouble(),
      tenureMonths: (map['tenureMonths'] as num).toInt(),
      startDate: DateTime.parse(map['startDate'] as String),
      firstEmiDate: firstEmiDate,
      emiDay: (storedEmiDay as num?)?.toInt() ??
          (firstEmiDate.day.clamp(1, 28)),
      accountId: map['accountId'] as String,
      note: map['note'] as String? ?? '',
    );
  }
}
