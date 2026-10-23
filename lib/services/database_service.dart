import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/account.dart';
import '../models/transaction.dart';
import '../models/loan.dart';
import '../models/emi_payment.dart';
import '../models/money_lent.dart';
import '../models/lent_repayment.dart';

class DatabaseService extends ChangeNotifier {
  static const String _accountsBoxName = 'accounts';
  static const String _transactionsBoxName = 'transactions';
  static const String _loansBoxName = 'loans';
  static const String _emiPaymentsBoxName = 'emi_payments';
  static const String _moneyLentBoxName = 'money_lent';
  static const String _lentRepaymentsBoxName = 'lent_repayments';

  late Box _accountsBox;
  late Box _transactionsBox;
  late Box _loansBox;
  late Box _emiPaymentsBox;
  late Box _moneyLentBox;
  late Box _lentRepaymentsBox;

  final List<Account> _accounts = [];
  final List<TransactionModel> _transactions = [];
  final List<Loan> _loans = [];
  final List<EmiPayment> _emiPayments = [];
  final List<MoneyLent> _moneyLent = [];
  final List<LentRepayment> _lentRepayments = [];

  bool _initialized = false;

  List<Account> get accounts => List.unmodifiable(_accounts);
  List<TransactionModel> get transactions => List.unmodifiable(_transactions);
  List<Loan> get loans => List.unmodifiable(_loans);
  List<EmiPayment> get emiPayments => List.unmodifiable(_emiPayments);
  List<MoneyLent> get moneyLent => List.unmodifiable(_moneyLent);
  List<LentRepayment> get lentRepayments => List.unmodifiable(_lentRepayments);

  Future<void> init() async {
    if (_initialized) return;

    await Hive.initFlutter();

    _accountsBox = await Hive.openBox(_accountsBoxName);
    _transactionsBox = await Hive.openBox(_transactionsBoxName);
    _loansBox = await Hive.openBox(_loansBoxName);
    _emiPaymentsBox = await Hive.openBox(_emiPaymentsBoxName);
    _moneyLentBox = await Hive.openBox(_moneyLentBoxName);
    _lentRepaymentsBox = await Hive.openBox(_lentRepaymentsBoxName);

    _accounts
      ..clear()
      ..addAll(
        _accountsBox.values.map(
          (value) => Account.fromMap(Map<String, dynamic>.from(value as Map)),
        ),
      );

    _transactions
      ..clear()
      ..addAll(
        _transactionsBox.values.map(
          (value) =>
              TransactionModel.fromMap(Map<String, dynamic>.from(value as Map)),
        ),
      );

    _loans
      ..clear()
      ..addAll(
        _loansBox.values.map(
          (value) => Loan.fromMap(Map<String, dynamic>.from(value as Map)),
        ),
      );

    _emiPayments
      ..clear()
      ..addAll(
        _emiPaymentsBox.values.map(
          (value) =>
              EmiPayment.fromMap(Map<String, dynamic>.from(value as Map)),
        ),
      );

    _moneyLent
      ..clear()
      ..addAll(
        _moneyLentBox.values.map(
          (value) => MoneyLent.fromMap(Map<String, dynamic>.from(value as Map)),
        ),
      );

    _lentRepayments
      ..clear()
      ..addAll(
        _lentRepaymentsBox.values.map(
          (value) =>
              LentRepayment.fromMap(Map<String, dynamic>.from(value as Map)),
        ),
      );

    _initialized = true;
    notifyListeners();
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'DatabaseService is not initialized. Call init() first.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // ACCOUNTS
  // ---------------------------------------------------------------------------

  Account? getAccount(String id) {
    for (final account in _accounts) {
      if (account.id == id) return account;
    }
    return null;
  }

  Future<void> addAccount(Account account) async {
    _ensureInitialized();

    if (_accountsBox.containsKey(account.id)) {
      throw StateError('An account with this ID already exists.');
    }

    await _accountsBox.put(account.id, account.toMap());
    _accounts.add(account);
    notifyListeners();
  }

  Future<void> updateAccount(Account account) async {
    _ensureInitialized();

    if (getAccount(account.id) == null) {
      throw StateError('Account not found.');
    }

    await _accountsBox.put(account.id, account.toMap());

    final index = _accounts.indexWhere((item) => item.id == account.id);
    _accounts[index] = account;
    notifyListeners();
  }

  Future<void> deleteAccount(String id) async {
    _ensureInitialized();

    if (_transactions.any(
      (transaction) =>
          transaction.accountId == id || transaction.toAccountId == id,
    )) {
      throw StateError('Cannot delete an account with transactions.');
    }

    if (_loans.any((loan) => loan.accountId == id)) {
      throw StateError('Cannot delete an account linked to a loan.');
    }

    if (_moneyLent.any((item) => item.accountId == id) ||
        _lentRepayments.any((item) => item.accountId == id)) {
      throw StateError('Cannot delete an account linked to a lending record.');
    }

    await _accountsBox.delete(id);
    _accounts.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // TRANSACTIONS
  // ---------------------------------------------------------------------------

  TransactionModel? getTransaction(String id) {
    for (final transaction in _transactions) {
      if (transaction.id == id) return transaction;
    }
    return null;
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    _ensureInitialized();

    if (_transactionsBox.containsKey(transaction.id)) {
      throw StateError('A transaction with this ID already exists.');
    }

    if (getAccount(transaction.accountId) == null) {
      throw StateError('The selected account does not exist.');
    }

    if (transaction.toAccountId != null &&
        getAccount(transaction.toAccountId!) == null) {
      throw StateError('The destination account does not exist.');
    }

    await _transactionsBox.put(transaction.id, transaction.toMap());
    _transactions.add(transaction);
    notifyListeners();
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    _ensureInitialized();

    if (getTransaction(transaction.id) == null) {
      throw StateError('Transaction not found.');
    }

    await _transactionsBox.put(transaction.id, transaction.toMap());

    final index = _transactions.indexWhere((item) => item.id == transaction.id);
    _transactions[index] = transaction;
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    _ensureInitialized();

    final linkedToEmi = _emiPayments.any(
      (payment) => payment.transactionId == id,
    );
    final linkedToRepayment = _lentRepayments.any(
      (repayment) => repayment.transactionId == id,
    );

    if (linkedToEmi || linkedToRepayment) {
      throw StateError(
        'This transaction is linked to a finance payment. '
        'Reverse the linked payment first.',
      );
    }

    await _transactionsBox.delete(id);
    _transactions.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  List<TransactionModel> getAccountTransactions(String accountId) {
    return _transactions
        .where(
          (transaction) =>
              transaction.accountId == accountId ||
              transaction.toAccountId == accountId,
        )
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<TransactionModel> getTransactionsForDate(DateTime date) {
    return _transactions.where((transaction) {
      return transaction.date.year == date.year &&
          transaction.date.month == date.month &&
          transaction.date.day == date.day;
    }).toList();
  }

  List<TransactionModel> getTransactionsForMonth(DateTime date) {
    return _transactions.where((transaction) {
      return transaction.date.year == date.year &&
          transaction.date.month == date.month;
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // ACCOUNT BALANCES AND CREDIT CARDS
  // ---------------------------------------------------------------------------

  double getAccountBalance(String accountId) {
    final account = getAccount(accountId);
    if (account == null) return 0;

    var balance = account.openingBalance;

    for (final transaction in _transactions) {
      if (transaction.accountId == accountId) {
        switch (transaction.type) {
          case TransactionType.income:
            balance += transaction.amount;
            break;
          case TransactionType.expense:
          case TransactionType.transfer:
          case TransactionType.cardPayment:
            balance -= transaction.amount;
            break;
        }
      }

      if (transaction.toAccountId == accountId) {
        if (transaction.type == TransactionType.transfer ||
            transaction.type == TransactionType.cardPayment) {
          balance += transaction.amount;
        }
      }
    }

    return balance;
  }

  double getCreditCardOutstanding(String accountId) {
    final account = getAccount(accountId);
    if (account == null || !account.isCreditCard) return 0;

    var outstanding = 0.0;

    for (final transaction in _transactions) {
      if (transaction.accountId == accountId) {
        if (transaction.type == TransactionType.expense) {
          outstanding += transaction.amount;
        } else if (transaction.type == TransactionType.income) {
          outstanding -= transaction.amount;
        }
      }

      if (transaction.toAccountId == accountId &&
          transaction.type == TransactionType.cardPayment) {
        outstanding -= transaction.amount;
      }
    }

    return outstanding < 0 ? 0 : outstanding;
  }

  double getAvailableCredit(String accountId) {
    final account = getAccount(accountId);
    if (account == null || !account.isCreditCard) return 0;

    final limit = account.creditLimit ?? 0;
    final available = limit - getCreditCardOutstanding(accountId);

    return available < 0 ? 0 : available;
  }

  double get totalBalance {
    return _accounts
        .where((account) => !account.isCreditCard)
        .fold(0.0, (sum, account) => sum + getAccountBalance(account.id));
  }

  double get totalIncome {
    return _transactions
        .where((transaction) => transaction.type == TransactionType.income)
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  double get totalExpense {
    return _transactions
        .where((transaction) => transaction.type == TransactionType.expense)
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  double get totalCreditCardDebt {
    return _accounts
        .where((account) => account.isCreditCard)
        .fold(
          0.0,
          (sum, account) => sum + getCreditCardOutstanding(account.id),
        );
  }

  double get totalAvailableCredit {
    return _accounts
        .where((account) => account.isCreditCard)
        .fold(0.0, (sum, account) => sum + getAvailableCredit(account.id));
  }

  double get netBalanceAfterCreditCardDebt =>
      totalBalance - totalCreditCardDebt;

  double get netWorth => netBalanceAfterCreditCardDebt;

  double getAccountIncome(String accountId) {
    return _transactions
        .where(
          (transaction) =>
              transaction.accountId == accountId &&
              transaction.type == TransactionType.income,
        )
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  double getAccountExpense(String accountId) {
    return _transactions
        .where(
          (transaction) =>
              transaction.accountId == accountId &&
              transaction.type == TransactionType.expense,
        )
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  double getMonthlyIncome(int year, int month) {
    return getTransactionsForMonth(DateTime(year, month))
        .where((transaction) => transaction.type == TransactionType.income)
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  double getMonthlyExpense(int year, int month) {
    return getTransactionsForMonth(DateTime(year, month))
        .where((transaction) => transaction.type == TransactionType.expense)
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  // ---------------------------------------------------------------------------
  // LOANS
  // ---------------------------------------------------------------------------

  Loan? getLoan(String id) {
    for (final loan in _loans) {
      if (loan.id == id) return loan;
    }
    return null;
  }

  Future<void> addLoan(Loan loan) async {
    _ensureInitialized();

    if (!loan.isValid) {
      throw ArgumentError(
        'Enter a valid principal, down payment, interest rate, tenure and EMI day.',
      );
    }

    if (getAccount(loan.accountId) == null) {
      throw StateError('The loan account does not exist.');
    }

    if (_loansBox.containsKey(loan.id)) {
      throw StateError('A loan with this ID already exists.');
    }

    await _loansBox.put(loan.id, loan.toMap());
    _loans.add(loan);
    notifyListeners();
  }

  Future<void> updateLoan(Loan loan) async {
    _ensureInitialized();

    if (getLoan(loan.id) == null) {
      throw StateError('Loan not found.');
    }

    if (getLoanEmiPayments(loan.id).isNotEmpty) {
      throw StateError(
        'Cannot edit a loan after its EMI schedule has been created.',
      );
    }

    if (!loan.isValid) {
      throw ArgumentError(
        'Enter a valid principal, down payment, interest rate, tenure and EMI day.',
      );
    }

    if (getAccount(loan.accountId) == null) {
      throw StateError('The loan account does not exist.');
    }

    await _loansBox.put(loan.id, loan.toMap());

    final index = _loans.indexWhere((item) => item.id == loan.id);
    _loans[index] = loan;
    notifyListeners();
  }

  Future<void> deleteLoan(String id) async {
    _ensureInitialized();

    final schedule = getLoanEmiPayments(id);

    // Preserve loans that have actual payment history.
    if (schedule.any(
      (payment) => payment.paidAmount > 0 || payment.transactionId != null,
    )) {
      throw StateError(
        'This loan has recorded EMI payments. '
        'Reverse those payments before deleting the loan.',
      );
    }

    // Remove only unpaid schedule entries.
    for (final payment in schedule) {
      await _emiPaymentsBox.delete(payment.id);
    }

    _emiPayments.removeWhere((payment) => payment.loanId == id);

    await _loansBox.delete(id);
    _loans.removeWhere((loan) => loan.id == id);

    notifyListeners();
  }

  List<EmiPayment> getLoanEmiPayments(String loanId) {
    return _emiPayments.where((payment) => payment.loanId == loanId).toList()
      ..sort((a, b) => a.installmentNumber.compareTo(b.installmentNumber));
  }

  Future<void> recordEmiPayment({
    required String emiPaymentId,
    required double amount,
    required DateTime paymentDate,
  }) async {
    _ensureInitialized();

    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError('Payment must be greater than zero.');
    }

    final index = _emiPayments.indexWhere(
      (payment) => payment.id == emiPaymentId,
    );

    if (index == -1) {
      throw StateError('EMI installment not found.');
    }

    final emi = _emiPayments[index];
    final loan = getLoan(emi.loanId);

    if (loan == null) {
      throw StateError('Loan not found.');
    }

    if (amount > emi.remainingAmount + 0.005) {
      throw StateError('Payment exceeds the remaining EMI amount.');
    }

    if (getAccount(loan.accountId) == null) {
      throw StateError('The EMI payment account was not found.');
    }

    final transactionId =
        'emi_payment_${emi.id}_${DateTime.now().microsecondsSinceEpoch}';

    final transaction = TransactionModel(
      id: transactionId,
      type: TransactionType.expense,
      amount: amount,
      categoryId: 'loan_emi',
      accountId: loan.accountId,
      note: 'EMI payment: ${loan.name} - Installment ${emi.installmentNumber}',
      date: paymentDate,
    );

    final updatedPaidAmount = (emi.paidAmount + amount)
        .clamp(0.0, emi.amount)
        .toDouble();

    final updatedEmi = EmiPayment(
      id: emi.id,
      loanId: emi.loanId,
      installmentNumber: emi.installmentNumber,
      dueDate: emi.dueDate,
      amount: emi.amount,
      principalComponent: emi.principalComponent,
      interestComponent: emi.interestComponent,
      paidAmount: updatedPaidAmount,
      paidDate: updatedPaidAmount >= emi.amount - 0.005 ? paymentDate : null,
      transactionId: transactionId,
    );

    await addTransaction(transaction);

    try {
      await _emiPaymentsBox.put(updatedEmi.id, updatedEmi.toMap());

      _emiPayments[index] = updatedEmi;
      notifyListeners();
    } catch (_) {
      await _transactionsBox.delete(transactionId);
      _transactions.removeWhere((item) => item.id == transactionId);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> createEmiSchedule(Loan loan) async {
    _ensureInitialized();

    if (!loan.isValid) {
      throw ArgumentError('The loan details are invalid.');
    }

    if (getLoan(loan.id) == null) {
      throw StateError('Save the loan before creating its EMI schedule.');
    }

    if (getLoanEmiPayments(loan.id).isNotEmpty) {
      throw StateError('An EMI schedule already exists for this loan.');
    }

    final monthlyRate = loan.annualInterestRate / 1200;
    final emi = loan.monthlyEmi;
    var remainingPrincipal = loan.principal;

    final installments = <EmiPayment>[];

    for (var i = 1; i <= loan.tenureMonths; i++) {
      final interest = remainingPrincipal * monthlyRate;
      var principalComponent = emi - interest;

      if (i == loan.tenureMonths || principalComponent > remainingPrincipal) {
        principalComponent = remainingPrincipal;
      }

      if (principalComponent < 0) {
        principalComponent = 0;
      }

      final amount = principalComponent + interest;

      final dueDate = i == 1
          ? loan.firstEmiDate
          : _dateForEmiMonth(loan.firstEmiDate, i - 1, loan.emiDay);

      installments.add(
        EmiPayment(
          id: '${loan.id}_emi_$i',
          loanId: loan.id,
          installmentNumber: i,
          dueDate: dueDate,
          amount: amount,
          principalComponent: principalComponent,
          interestComponent: interest,
        ),
      );

      remainingPrincipal -= principalComponent;

      if (remainingPrincipal < 0.005) {
        remainingPrincipal = 0;
      }
    }

    final writtenIds = <String>[];

    try {
      for (final payment in installments) {
        if (_emiPaymentsBox.containsKey(payment.id)) {
          throw StateError('An EMI record with this ID already exists.');
        }

        await _emiPaymentsBox.put(payment.id, payment.toMap());

        writtenIds.add(payment.id);
      }

      _emiPayments.addAll(installments);
    } catch (_) {
      for (final id in writtenIds) {
        await _emiPaymentsBox.delete(id);
      }
      rethrow;
    }

    notifyListeners();
  }

  DateTime _dateForEmiMonth(DateTime firstDate, int months, int emiDay) {
    final monthIndex = firstDate.month - 1 + months;
    final year = firstDate.year + monthIndex ~/ 12;
    final month = monthIndex % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = emiDay.clamp(1, lastDay);

    return DateTime(year, month, day);
  }

  double getLoanOutstanding(String loanId) {
    final loan = getLoan(loanId);
    if (loan == null) return 0;

    final schedule = getLoanEmiPayments(loanId);
    if (schedule.isEmpty) return loan.principal;

    return schedule.fold(0.0, (sum, payment) {
      final safeAmount = payment.amount.clamp(0.000001, double.infinity);

      return sum +
          payment.principalComponent * (payment.remainingAmount / safeAmount);
    });
  }

  List<EmiPayment> get overdueEmis =>
      _emiPayments.where((payment) => payment.isOverdue).toList();

  List<EmiPayment> get upcomingEmis =>
      _emiPayments
          .where((payment) => !payment.isPaid && !payment.isOverdue)
          .toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

  // ---------------------------------------------------------------------------
  // MONEY LENT
  // ---------------------------------------------------------------------------

  MoneyLent? getMoneyLentById(String id) {
    for (final item in _moneyLent) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<void> addMoneyLent(MoneyLent item) async {
    _ensureInitialized();

    if (!item.amount.isFinite || item.amount <= 0) {
      throw ArgumentError('The lent amount must be greater than zero.');
    }

    if (getAccount(item.accountId) == null) {
      throw StateError('The selected account does not exist.');
    }

    if (_moneyLentBox.containsKey(item.id)) {
      throw StateError('This lending record already exists.');
    }

    await _moneyLentBox.put(item.id, item.toMap());
    _moneyLent.add(item);
    notifyListeners();
  }

  Future<void> updateMoneyLent(MoneyLent item) async {
    _ensureInitialized();

    if (getMoneyLentById(item.id) == null) {
      throw StateError('Lending record not found.');
    }

    if (_lentRepayments.any((repayment) => repayment.moneyLentId == item.id)) {
      throw StateError(
        'Cannot edit a lending record after repayments have been added.',
      );
    }

    await _moneyLentBox.put(item.id, item.toMap());

    final index = _moneyLent.indexWhere((value) => value.id == item.id);
    _moneyLent[index] = item;
    notifyListeners();
  }

  double getMoneyLentRepaid(String moneyLentId) {
    return _lentRepayments
        .where((repayment) => repayment.moneyLentId == moneyLentId)
        .fold(0.0, (sum, repayment) => sum + repayment.amount);
  }

  double getMoneyLentOutstanding(String moneyLentId) {
    final item = getMoneyLentById(moneyLentId);
    if (item == null) return 0;

    final remaining = item.amount - getMoneyLentRepaid(moneyLentId);
    return remaining > 0 ? remaining : 0;
  }

  Future<void> addLentRepayment(LentRepayment repayment) async {
    _ensureInitialized();

    final lending = getMoneyLentById(repayment.moneyLentId);
    if (lending == null) {
      throw StateError('The lending record does not exist.');
    }

    if (!repayment.amount.isFinite || repayment.amount <= 0) {
      throw ArgumentError('Repayment must be greater than zero.');
    }

    if (getAccount(repayment.accountId) == null) {
      throw StateError('The selected account does not exist.');
    }

    if (repayment.amount >
        getMoneyLentOutstanding(repayment.moneyLentId) + 0.005) {
      throw StateError('Repayment exceeds the outstanding amount.');
    }

    if (_lentRepaymentsBox.containsKey(repayment.id)) {
      throw StateError('This repayment already exists.');
    }

    await _lentRepaymentsBox.put(repayment.id, repayment.toMap());

    _lentRepayments.add(repayment);
    notifyListeners();
  }

  Future<void> deleteLentRepayment(String id) async {
    _ensureInitialized();

    final repayment = _lentRepayments.firstWhere(
      (item) => item.id == id,
      orElse: () => throw StateError('Repayment not found.'),
    );

    if (repayment.transactionId != null) {
      throw StateError(
        'This repayment is linked to a transaction. '
        'Reverse that payment first.',
      );
    }

    await _lentRepaymentsBox.delete(id);
    _lentRepayments.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  Future<void> deleteMoneyLent(String id) async {
    _ensureInitialized();

    if (_lentRepayments.any((item) => item.moneyLentId == id)) {
      throw StateError(
        'Delete or reverse the repayments before deleting this record.',
      );
    }

    await _moneyLentBox.delete(id);
    _moneyLent.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // DISPOSAL
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    // Boxes are shared by the app, so this service does not close them.
    super.dispose();
  }
}
