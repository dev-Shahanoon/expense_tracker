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

Box get _transactionsBox => Hive.box(_transactionsBoxName);

// ------------------------------------------------------------
// LOAD DATA
// ------------------------------------------------------------

void _loadAccounts() {
_accounts.clear();

for (final value in _accountsBox.values) {
  if (value is Map) {
    _accounts.add(
      Account.fromMap(Map<String, dynamic>.from(value)),
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

// ------------------------------------------------------------
// ACCOUNTS
// ------------------------------------------------------------

Future<void> addAccount(Account account) async {
final index = _accounts.indexWhere(
(item) => item.id == account.id,
);

if (index == -1) {
  _accounts.add(account);
} else {
  _accounts[index] = account;
}

await _accountsBox.put(account.id, account.toMap());

}

Future<void> deleteAccount(String id) async {
final hasTransactions = _transactions.any(
(transaction) =>
transaction.accountId == id ||
transaction.toAccountId == id,
);

if (hasTransactions) {
  throw StateError(
    'Delete or reassign this account\'s transactions first.',
  );
}

_accounts.removeWhere((account) => account.id == id);
await _accountsBox.delete(id);

}

Account? getAccount(String id) {
for (final account in _accounts) {
if (account.id == id) return account;
}

return null;

}

// ------------------------------------------------------------
// TRANSACTIONS
// ------------------------------------------------------------

Future<void> addTransaction(
TransactionModel transaction,
) async {
final index = _transactions.indexWhere(
(item) => item.id == transaction.id,
);

if (index != -1) {
  throw StateError('This transaction already exists.');
}

_transactions.add(transaction);

try {
  await _transactionsBox.put(
    transaction.id,
    transaction.toMap(),
  );
} catch (_) {
  _transactions.removeWhere(
    (item) => item.id == transaction.id,
  );
  rethrow;
}

}

Future<void> updateTransaction(
TransactionModel transaction,
) async {
final index = _transactions.indexWhere(
(item) => item.id == transaction.id,
);

if (index == -1) return;

final previous = _transactions[index];
_transactions[index] = transaction;

try {
  await _transactionsBox.put(
    transaction.id,
    transaction.toMap(),
  );
} catch (_) {
  _transactions[index] = previous;
  rethrow;
}

}

Future<void> deleteTransaction(String id) async {
final index = _transactions.indexWhere(
(item) => item.id == id,
);

if (index == -1) return;

final removed = _transactions[index];
_transactions.removeAt(index);

try {
  await _transactionsBox.delete(id);
} catch (_) {
  _transactions.insert(index, removed);
  rethrow;
}

}

List<TransactionModel> getAccountTransactions(
String accountId,
) {
return _transactions.where((transaction) {
return transaction.accountId == accountId ||
transaction.toAccountId == accountId;
}).toList();
}

// ------------------------------------------------------------
// CREDIT CARD BALANCES
// ------------------------------------------------------------

/// Opening balance for a credit card is treated as its
/// initial outstanding debt.
///
/// Card expenses increase debt.
/// Card payments and transfers to the card reduce debt.
double getCreditCardOutstanding(String accountId) {
final account = getAccount(accountId);

if (account == null || !account.isCreditCard) {
  return 0;
}

double outstanding = account.openingBalance;

for (final transaction in _transactions) {
  if (transaction.type == TransactionType.expense &&
      transaction.accountId == accountId) {
    outstanding += transaction.amount;
  }

  if ((transaction.type == TransactionType.cardPayment ||
          transaction.type == TransactionType.transfer) &&
      transaction.toAccountId == accountId) {
    outstanding -= transaction.amount;
  }
}

return outstanding < 0 ? 0 : outstanding;

}

double getAvailableCredit(String accountId) {
final account = getAccount(accountId);

if (account == null || !account.isCreditCard) {
  return 0;
}

final limit = account.creditLimit ?? 0;
final available = limit - getCreditCardOutstanding(accountId);

return available < 0 ? 0 : available;

}

/// Combined outstanding debt across all credit cards.
double get totalCreditCardDebt {
return _accounts
.where((account) => account.isCreditCard)
.fold(
0.0,
(total, account) =>
total + getCreditCardOutstanding(account.id),
);
}

/// Combined unused credit across all credit cards.
double get totalAvailableCredit {
return _accounts
.where((account) => account.isCreditCard)
.fold(
0.0,
(total, account) => total + getAvailableCredit(account.id),
);
}

// ------------------------------------------------------------
// ACCOUNT BALANCES
// ------------------------------------------------------------

/// For bank/cash accounts, returns available money.
/// For credit cards, returns outstanding debt.
double getAccountBalance(String accountId) {
final account = getAccount(accountId);

if (account == null) return 0;

if (account.isCreditCard) {
  return getCreditCardOutstanding(accountId);
}

double balance = account.openingBalance;

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

  if (transaction.toAccountId == accountId &&
      transaction.type == TransactionType.transfer) {
    balance += transaction.amount;
  }
}

return balance;

}

/// Total money in cash and bank accounts.
/// Credit card accounts are excluded.
double get totalBalance {
return _accounts
.where((account) => !account.isCreditCard)
.fold(
0.0,
(total, account) =>
total + getAccountBalance(account.id),
);
}

/// Money in cash/bank accounts minus credit card debt.
double get netBalanceAfterCreditCardDebt {
return totalBalance - totalCreditCardDebt;
}

// ------------------------------------------------------------
// INCOME AND EXPENSE TOTALS
// ------------------------------------------------------------

/// Card payments and transfers are not expenses.
/// Purchases made using a credit card are counted as expenses.
double get totalIncome {
return _transactions
.where(
(transaction) =>
transaction.type == TransactionType.income,
)
.fold(
0.0,
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
0.0,
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
0.0,
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
0.0,
(total, transaction) => total + transaction.amount,
);
}

// ------------------------------------------------------------
// DATE-BASED TRANSACTIONS
// ------------------------------------------------------------

List<TransactionModel> getTransactionsForDate(
DateTime date,
) {
return _transactions.where((transaction) {
return transaction.date.year == date.year &&
transaction.date.month == date.month &&
transaction.date.day == date.day;
}).toList();
}

List<TransactionModel> getTransactionsForMonth(
DateTime date,
) {
return _transactions.where((transaction) {
return transaction.date.year == date.year &&
transaction.date.month == date.month;
}).toList();
}

double getMonthlyIncome(DateTime date) {
return getTransactionsForMonth(date)
.where(
(transaction) =>
transaction.type == TransactionType.income,
)
.fold(
0.0,
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
0.0,
(total, transaction) => total + transaction.amount,
);
}
}