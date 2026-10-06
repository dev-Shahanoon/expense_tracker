import 'package:flutter/material.dart';

import '../data/categories.dart';
import '../data/income_sources.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';

class AccountDashboardScreen extends StatefulWidget {
  final DatabaseService databaseService;
  final String accountId;

  const AccountDashboardScreen({
    super.key,
    required this.databaseService,
    required this.accountId,
  });

  @override
  State<AccountDashboardScreen> createState() =>
      _AccountDashboardScreenState();
}

class _AccountDashboardScreenState
    extends State<AccountDashboardScreen> {
  String _formatAmount(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  Account? get _account {
    return widget.databaseService.getAccount(
      widget.accountId,
    );
  }

  List<TransactionModel> get _transactions {
    final transactions =
        widget.databaseService.getAccountTransactions(
      widget.accountId,
    );

    transactions.sort(
      (a, b) => b.date.compareTo(a.date),
    );

    return transactions;
  }

  String _categoryName(TransactionModel transaction) {
    if (transaction.type == TransactionType.income) {
      for (final source in incomeSources) {
        if (source.id == transaction.categoryId) {
          return source.name;
        }
      }

      return 'Income';
    }

    if (transaction.type == TransactionType.expense) {
      for (final category in expenseCategories) {
        if (category.id == transaction.categoryId) {
          return category.name;
        }
      }

      return 'Expense';
    }

    return 'Transfer';
  }

  String _categoryIcon(TransactionModel transaction) {
    if (transaction.type == TransactionType.income) {
      for (final source in incomeSources) {
        if (source.id == transaction.categoryId) {
          return source.icon;
        }
      }

      return '💰';
    }

    if (transaction.type == TransactionType.expense) {
      for (final category in expenseCategories) {
        if (category.id == transaction.categoryId) {
          return category.icon;
        }
      }

      return '📦';
    }

    return '↔️';
  }

  String _accountTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'savings':
        return '💰';
      case 'current':
        return '🏦';
      case 'credit card':
        return '💳';
      case 'cash':
        return '💵';
      default:
        return '🏦';
    }
  }

  String _accountName(String id) {
    return widget.databaseService.getAccount(id)?.name ??
        'Unknown account';
  }

  String _transactionTitle(
    TransactionModel transaction,
  ) {
    if (transaction.type == TransactionType.transfer) {
      if (transaction.accountId == widget.accountId) {
        return 'Transfer Out';
      }

      return 'Transfer In';
    }

    return _categoryName(transaction);
  }

  String _transactionSubtitle(
    TransactionModel transaction,
  ) {
    if (transaction.type == TransactionType.transfer) {
      if (transaction.accountId == widget.accountId) {
        return 'To ${_accountName(transaction.toAccountId ?? '')}';
      }

      return 'From ${_accountName(transaction.accountId)}';
    }

    if (transaction.note.isNotEmpty) {
      return transaction.note;
    }

    return transaction.type == TransactionType.income
        ? 'Income'
        : 'Expense';
  }

  Color _amountColor(
    BuildContext context,
    TransactionModel transaction,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    if (transaction.type == TransactionType.income) {
      return Colors.green;
    }

    if (transaction.type == TransactionType.expense) {
      return colorScheme.error;
    }

    if (transaction.accountId == widget.accountId) {
      return colorScheme.error;
    }

    return colorScheme.primary;
  }

  String _amountPrefix(TransactionModel transaction) {
    if (transaction.type == TransactionType.income) {
      return '+';
    }

    if (transaction.type == TransactionType.expense) {
      return '-';
    }

    if (transaction.accountId == widget.accountId) {
      return '-';
    }

    return '+';
  }

  Future<void> _deleteTransaction(
    TransactionModel transaction,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Transaction?',
          ),
          content: const Text(
            'This transaction will be permanently deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor:
                    Theme.of(dialogContext).colorScheme.error,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await widget.databaseService.deleteTransaction(
      transaction.id,
    );

    if (!mounted) {
      return;
    }

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Transaction deleted',
        ),
      ),
    );
  }

  Widget _buildAccountHeader(
    BuildContext context,
    Account account,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary
                      .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    _accountTypeIcon(account.type),
                    style: const TextStyle(
                      fontSize: 25,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      account.bankName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimary
                            .withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Text(
            'Current Balance',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimary
                  .withValues(alpha: 0.75),
            ),
          ),

          const SizedBox(height: 5),

          Text(
            _formatAmount(
              widget.databaseService
                  .getAccountBalance(account.id),
            ),
            style:
                theme.textTheme.headlineMedium?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              if (account.lastFourDigits != null)
                _buildHeaderInfo(
                  context,
                  label: 'Account',
                  value:
                      '•••• ${account.lastFourDigits}',
                ),

              if (account.lastFourDigits != null)
                const SizedBox(width: 26),

              _buildHeaderInfo(
                context,
                label: 'Type',
                value: account.type,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onPrimary
                .withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onPrimary
                .withValues(alpha: 0.9),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: color,
              ),
            ),
            const SizedBox(height: 13),
            Text(
              title,
              style:
                  theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatAmount(amount),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferSummary(
    BuildContext context,
    List<TransactionModel> transactions,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    double transferIn = 0;
    double transferOut = 0;

    for (final transaction in transactions) {
      if (transaction.type != TransactionType.transfer) {
        continue;
      }

      if (transaction.toAccountId == widget.accountId) {
        transferIn += transaction.amount;
      }

      if (transaction.accountId == widget.accountId) {
        transferOut += transaction.amount;
      }
    }

    return Row(
      children: [
        Expanded(
          child: _buildMiniTransferCard(
            context,
            title: 'Transfer In',
            amount: transferIn,
            icon: Icons.south_west_rounded,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniTransferCard(
            context,
            title: 'Transfer Out',
            amount: transferOut,
            icon: Icons.north_east_rounded,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniTransferCard(
    BuildContext context, {
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 19,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatAmount(amount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    TransactionModel transaction,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final color =
        _amountColor(context, transaction);

    final isTransfer =
        transaction.type == TransactionType.transfer;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onLongPress: () {
          _deleteTransaction(transaction);
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: isTransfer
                      ? Icon(
                          transaction.accountId ==
                                  widget.accountId
                              ? Icons.north_east_rounded
                              : Icons.south_west_rounded,
                          color: color,
                          size: 21,
                        )
                      : Text(
                          _categoryIcon(transaction),
                          style: const TextStyle(
                            fontSize: 20,
                          ),
                        ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _transactionTitle(transaction),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      _transactionSubtitle(transaction),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      '${_formatDate(transaction.date)} • '
                      '${_formatTime(transaction.date)}',
                      style:
                          theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurface
                            .withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_amountPrefix(transaction)}'
                    '${_formatAmount(transaction.amount)}',
                    style:
                        theme.textTheme.titleSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 4),

                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    iconSize: 19,
                    tooltip: 'Options',
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteTransaction(
                          transaction,
                        );
                      }
                    },
                    itemBuilder: (context) {
                      return const [
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.red,
                              ),
                              SizedBox(width: 10),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 40,
        horizontal: 24,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 32,
              color: colorScheme.primary,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'No transactions yet',
            style:
                theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            'Transactions for this account will appear here.',
            textAlign: TextAlign.center,
            style:
                theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface
                  .withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final account = _account;

    if (account == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Account',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: Center(
          child: Text(
            'Account not found.',
            style: theme.textTheme.titleMedium,
          ),
        ),
      );
    }

    final transactions = _transactions;

    final income =
        widget.databaseService.getAccountIncome(
      account.id,
    );

    final expense =
        widget.databaseService.getAccountExpense(
      account.id,
    );

    final balance =
        widget.databaseService.getAccountBalance(
      account.id,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          account.name,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            32,
          ),
          children: [
            _buildAccountHeader(
              context,
              account,
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                _buildSummaryCard(
                  context,
                  title: 'Income',
                  amount: income,
                  icon: Icons.arrow_downward_rounded,
                  color: Colors.green,
                ),
                const SizedBox(width: 12),
                _buildSummaryCard(
                  context,
                  title: 'Expense',
                  amount: expense,
                  icon: Icons.arrow_upward_rounded,
                  color: Theme.of(context)
                      .colorScheme
                      .error,
                ),
              ],
            ),

            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.3),
                borderRadius:
                    BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Theme.of(context)
                        .colorScheme
                        .primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Balance',
                          style: theme
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                            color: theme
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _formatAmount(balance),
                          style: theme
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            _buildTransferSummary(
              context,
              transactions,
            ),

            const SizedBox(height: 26),

            Row(
              children: [
                Expanded(
                  child: Text(
                    'Transactions',
                    style:
                        theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${transactions.length}',
                  style:
                      theme.textTheme.bodyMedium?.copyWith(
                    color: theme
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.55),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (transactions.isEmpty)
              _buildEmptyState(context)
            else
              ...transactions.map(
                (transaction) => Padding(
                  padding: const EdgeInsets.only(
                    bottom: 10,
                  ),
                  child: _buildTransactionCard(
                    context,
                    transaction,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}