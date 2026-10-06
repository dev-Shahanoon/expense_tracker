import 'package:flutter/material.dart';

import '../data/categories.dart';
import '../data/income_sources.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../services/theme_controller.dart';
import 'account_dashboard_screen.dart';
import 'accounts_screen.dart';
import 'add_transaction_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';
import 'transactions_screen.dart';

class HomeScreen extends StatefulWidget {
  final DatabaseService databaseService;
  final ThemeController themeController;

  const HomeScreen({
    super.key,
    required this.databaseService,
    required this.themeController,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;

    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  String _accountName(String accountId) {
    final account =
        widget.databaseService.getAccount(accountId);

    return account?.name ?? 'Unknown account';
  }

  String _categoryName(String categoryId) {
    for (final category in expenseCategories) {
      if (category.id == categoryId) {
        return category.name;
      }
    }

    return 'Other';
  }

  String _categoryIcon(String categoryId) {
    for (final category in expenseCategories) {
      if (category.id == categoryId) {
        return category.icon;
      }
    }

    return '📦';
  }

  String _incomeSourceName(String sourceId) {
    for (final source in incomeSources) {
      if (source.id == sourceId) {
        return source.name;
      }
    }

    return 'Other';
  }

  String _incomeSourceIcon(String sourceId) {
    for (final source in incomeSources) {
      if (source.id == sourceId) {
        return source.icon;
      }
    }

    return '📦';
  }

  IconData _accountIcon(String type) {
    switch (type.toLowerCase()) {
      case 'bank':
        return Icons.account_balance_rounded;
      case 'cash':
        return Icons.payments_rounded;
      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      case 'credit card':
        return Icons.credit_card_rounded;
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  Future<void> _openAddTransaction() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          databaseService: widget.databaseService,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _openAccounts() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AccountsScreen(
          databaseService: widget.databaseService,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _openTransactions() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransactionsScreen(
          databaseService: widget.databaseService,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openAnalytics() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnalyticsScreen(
          databaseService: widget.databaseService,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          databaseService: widget.databaseService,
          themeController: widget.themeController,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openAccountDashboard(
    String accountId,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AccountDashboardScreen(
          databaseService: widget.databaseService,
          accountId: accountId,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildBalanceCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final totalBalance =
        widget.databaseService.totalBalance;

    final totalIncome =
        widget.databaseService.totalIncome;

    final totalExpense =
        widget.databaseService.totalExpense;

    final accountCount =
        widget.databaseService.accounts.length;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total Balance',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(
                    color: colorScheme.onPrimary
                        .withValues(alpha: 0.75),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary
                      .withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: colorScheme.onPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            _formatAmount(totalBalance),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineMedium
                ?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.7,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            '$accountCount '
            '${accountCount == 1 ? 'account' : 'accounts'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onPrimary
                  .withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildBalanceStat(
                  context,
                  title: 'Income',
                  amount: totalIncome,
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBalanceStat(
                  context,
                  title: 'Expenses',
                  amount: totalExpense,
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceStat(
    BuildContext context, {
    required String title,
    required double amount,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: colorScheme.onPrimary
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: colorScheme.onPrimary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(
                    color: colorScheme.onPrimary
                        .withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatAmount(amount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(
                    color: colorScheme.onPrimary,
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

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required String actionText,
    required VoidCallback onAction,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge
                ?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextButton(
          onPressed: onAction,
          child: Text(
            actionText,
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountCard(
    BuildContext context,
    String accountId,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final account =
        widget.databaseService.getAccount(accountId);

    if (account == null) {
      return const SizedBox.shrink();
    }

    final balance =
        widget.databaseService.getAccountBalance(
      account.id,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(21),
      onTap: () {
        _openAccountDashboard(account.id);
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: Icon(
                  _accountIcon(account.type),
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      account.bankName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(
                        color: colorScheme.onSurface
                            .withValues(alpha: 0.55),
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
                    _formatAmount(balance),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: colorScheme.onSurface
                        .withValues(alpha: 0.4),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyAccounts(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.account_balance_outlined,
              size: 42,
              color: colorScheme.primary
                  .withValues(alpha: 0.65),
            ),
            const SizedBox(height: 10),
            Text(
              'No accounts yet',
              style: theme.textTheme.titleMedium
                  ?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Add your first account to start tracking '
              'your finances.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(
                color: colorScheme.onSurface
                    .withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 15),
            FilledButton.icon(
              onPressed: _openAccounts,
              icon: const Icon(
                Icons.add_rounded,
              ),
              label: const Text('Add Account'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(
    BuildContext context,
    TransactionModel transaction,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isIncome =
        transaction.type == TransactionType.income;

    final isTransfer =
        transaction.type == TransactionType.transfer;

    String title;
    String subtitle;
    String iconText;

    if (isTransfer) {
      title = 'Transfer';

      subtitle =
          '${_accountName(transaction.accountId)} → '
          '${_accountName(transaction.toAccountId ?? '')}';

      iconText = '↔️';
    } else if (isIncome) {
      title =
          _incomeSourceName(transaction.categoryId);

      subtitle =
          transaction.note.isNotEmpty
              ? transaction.note
              : _accountName(transaction.accountId);

      iconText =
          _incomeSourceIcon(transaction.categoryId);
    } else {
      title =
          _categoryName(transaction.categoryId);

      subtitle =
          transaction.note.isNotEmpty
              ? transaction.note
              : _accountName(transaction.accountId);

      iconText =
          _categoryIcon(transaction.categoryId);
    }

    Color amountColor;

    if (isTransfer) {
      amountColor = colorScheme.primary;
    } else if (isIncome) {
      amountColor = Colors.green;
    } else {
      amountColor = colorScheme.error;
    }

    String amountPrefix;

    if (isTransfer) {
      amountPrefix = '';
    } else if (isIncome) {
      amountPrefix = '+';
    } else {
      amountPrefix = '-';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.55),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: Center(
                  child: Text(
                    iconText,
                    style: const TextStyle(
                      fontSize: 19,
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
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(
                        color: colorScheme.onSurface
                            .withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_formatDate(transaction.date)} • '
                      '${_formatTime(transaction.date)}',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(
                        color: colorScheme.onSurface
                            .withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$amountPrefix${_formatAmount(transaction.amount)}',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(
                  color: amountColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyTransactions(
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 42,
              color: colorScheme.primary
                  .withValues(alpha: 0.65),
            ),
            const SizedBox(height: 10),
            Text(
              'No transactions yet',
              style: theme.textTheme.titleMedium
                  ?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Add income, expenses or transfers '
              'to see them here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(
                color: colorScheme.onSurface
                    .withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 10,
          ),
          decoration: BoxDecoration(
            color: colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: colorScheme.primary,
                size: 23,
              ),
              const SizedBox(height: 7),
              Text(
                title,
                style: theme.textTheme.labelMedium
                    ?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accounts =
        widget.databaseService.accounts;

    final transactions =
        widget.databaseService.transactions.toList()
          ..sort(
            (a, b) => b.date.compareTo(a.date),
          );

    final recentTransactions =
        transactions.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Expense Tracker',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Analytics',
            icon: const Icon(
              Icons.analytics_outlined,
            ),
            onPressed: _openAnalytics,
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(
              Icons.settings_outlined,
            ),
            onPressed: _openSettings,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              110,
            ),
            children: [
              _buildBalanceCard(context),

              const SizedBox(height: 22),

              _buildSectionHeader(
                context,
                title: 'Accounts',
                actionText: 'View All',
                onAction: _openAccounts,
              ),

              if (accounts.isEmpty)
                _buildEmptyAccounts(context)
              else
                ...accounts
                    .take(3)
                    .map(
                      (account) => Padding(
                        padding:
                            const EdgeInsets.only(
                          bottom: 10,
                        ),
                        child: _buildAccountCard(
                          context,
                          account.id,
                        ),
                      ),
                    ),

              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      _buildQuickAction(
                        context,
                        icon:
                            Icons.add_card_rounded,
                        title: 'Transaction',
                        onTap: _openAddTransaction,
                      ),
                      const SizedBox(width: 8),
                      _buildQuickAction(
                        context,
                        icon:
                            Icons.receipt_long_rounded,
                        title: 'History',
                        onTap: _openTransactions,
                      ),
                      const SizedBox(width: 8),
                      _buildQuickAction(
                        context,
                        icon:
                            Icons.bar_chart_rounded,
                        title: 'Analytics',
                        onTap: _openAnalytics,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              _buildSectionHeader(
                context,
                title: 'Recent Transactions',
                actionText: 'View All',
                onAction: _openTransactions,
              ),

              if (recentTransactions.isEmpty)
                _buildEmptyTransactions(context)
              else
                ...recentTransactions.map(
                  (transaction) =>
                      _buildTransactionTile(
                    context,
                    transaction,
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: _openAddTransaction,
        icon: const Icon(
          Icons.add_rounded,
        ),
        label: const Text(
          'Add Transaction',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}