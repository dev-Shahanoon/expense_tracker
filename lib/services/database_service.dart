import 'package:hive_flutter/hive_flutter.dart';

import '../models/account.dart';
import '../models/transaction.dart';

class DatabaseService {
  static const String _accountsBoxName = 'accounts';
  static const String _transactionsBoxName = 'transactions';

  final List<Account> _accounts = [];
  final List<TransactionModel> _transactions = [];

  List<Account> get accounts => List.unmodifiable(_accounts);

  List<TransactionModel> get transactions =>
      List.unmodifiable(_transactions);

  Future<void> init() async {
    await Hive.initFlutter();

    await Hive.openBox(_accountsBoxName);
    await Hive.openBox(_transactionsBoxName);

    _loadAccounts();
    _loadTransactions();
  }

  Box get _accountsBox => Hive.box(_accountsBoxName);

  Box get _transactionsBox =>
      Hive.box(_transactionsBoxName);

  void _loadAccounts() {
    _accounts.clear();

    for (final value in _accountsBox.values) {
      if (value is Map) {
        _accounts.add(
          Account.fromMap(
            Map<String, dynamic>.from(value),
          ),
        );
      }
    }
  }

  void _loadTransactions() {
    _transactions.clear();

    for (final value in _transactionsBox.values) {
      if (value is Map) {
        _transactions.add(
          TransactionModel.fromMap(
            Map<String, dynamic>.from(value),
          ),
        );
      }
    }
  }

  Future<void> addAccount(Account account) async {
    _accounts.add(account);

    await _accountsBox.put(
      account.id,
      account.toMap(),
    );
  }

  Future<void> deleteAccount(String id) async {
    _accounts.removeWhere(
      (account) => account.id == id,
    );

    await _accountsBox.delete(id);
  }

  Account? getAccount(String id) {
    for (final account in _accounts) {
      if (account.id == id) {
        return account;
      }
    }

    return null;
  }

  Future<void> addTransaction(
    TransactionModel transaction,
  ) async {
    _transactions.add(transaction);

    await _transactionsBox.put(
      transaction.id,
      transaction.toMap(),
    );
  }

  Future<void> updateTransaction(
    TransactionModel transaction,
  ) async {
    final index = _transactions.indexWhere(
      (item) => item.id == transaction.id,
    );

    if (index == -1) {
      return;
    }

    _transactions[index] = transaction;

    await _transactionsBox.put(
      transaction.id,
      transaction.toMap(),
    );
  }

  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere(
      (transaction) => transaction.id == id,
    );

    await _transactionsBox.delete(id);
  }

  List<TransactionModel> getAccountTransactions(
    String accountId,
  ) {
    return _transactions.where(
      (transaction) {
        return transaction.accountId == accountId ||
            transaction.toAccountId == accountId;
      },
    ).toList();
  }

  double getAccountBalance(String accountId) {
    final account = getAccount(accountId);

    if (account == null) {
      return 0;
    }

    double balance = account.openingBalance;

    for (final transaction in _transactions) {
      if (transaction.type == TransactionType.income &&
          transaction.accountId == accountId) {
        balance += transaction.amount;
      }

      if (transaction.type == TransactionType.expense &&
          transaction.accountId == accountId) {
        balance -= transaction.amount;
      }

      if (transaction.type == TransactionType.transfer) {
        if (transaction.accountId == accountId) {
          balance -= transaction.amount;
        }

        if (transaction.toAccountId == accountId) {
          balance += transaction.amount;
        }
      }
    }

    return balance;
  }

  double get totalBalance {
    return _accounts.fold(
      0,
      (total, account) {
        return total + getAccountBalance(account.id);
      },
    );
  }

  double get totalIncome {
    return _transactions
        .where(
          (transaction) =>
              transaction.type == TransactionType.income,
        )
        .fold(
          0,
          (total, transaction) => total + transaction.amount,
        );
  }

  double get totalExpense {
    return _transactions
        .where(
          (transaction) =>
              transaction.type == TransactionType.expense,
        )
        .fold(
          0,
          (total, transaction) => total + transaction.amount,
        );
  }

  double getAccountIncome(String accountId) {
    return _transactions
        .where(
          (transaction) =>
              transaction.type == TransactionType.income &&
              transaction.accountId == accountId,
        )
        .fold(
          0,
          (total, transaction) => total + transaction.amount,
        );
  }

  double getAccountExpense(String accountId) {
    return _transactions
        .where(
          (transaction) =>
              transaction.type == TransactionType.expense &&
              transaction.accountId == accountId,
        )
        .fold(
          0,
          (total, transaction) => total + transaction.amount,
        );
  }

  List<TransactionModel> getTransactionsForDate(
    DateTime date,
  ) {
    return _transactions.where(
      (transaction) {
        return transaction.date.year == date.year &&
            transaction.date.month == date.month &&
            transaction.date.day == date.day;
      },
    ).toList();
  }

  List<TransactionModel> getTransactionsForMonth(
    DateTime date,
  ) {
    return _transactions.where(
      (transaction) {
        return transaction.date.year == date.year &&
            transaction.date.month == date.month;
      },
    ).toList();
  }

  double getMonthlyIncome(DateTime date) {
    return getTransactionsForMonth(date)
        .where(
          (transaction) =>
              transaction.type == TransactionType.income,
        )
        .fold(
          0,
          (total, transaction) => total + transaction.amount,
        );
  }

  double getMonthlyExpense(DateTime date) {
    return getTransactionsForMonth(date)
        .where(
          (transaction) =>
              transaction.type == TransactionType.expense,
        )
        .fold(
          0,
          (total, transaction) => total + transaction.amount,
        );
  }
}