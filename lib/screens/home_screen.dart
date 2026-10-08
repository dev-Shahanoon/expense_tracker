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
  bool _showBalances = true;

  static const Color _navy = Color(0xFF172554);
  static const Color _navyDark = Color(0xFF151C2B);

  String _formatAmount(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  String _displayBalance(double amount) {
    return _showBalances ? _formatAmount(amount) : '••••••••';
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
    final account = widget.databaseService.getAccount(accountId);
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

  Future<void> _openAccountDashboard(String accountId) async {
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
    final isDark = theme.brightness == Brightness.dark;

    final totalBalance = widget.databaseService.totalBalance;
    final totalIncome = widget.databaseService.totalIncome;
    final totalExpense = widget.databaseService.totalExpense;
    final accountCount = widget.databaseService.accounts.length;

    final balanceBackground =
        isDark ? _navyDark : _navy;

    final secondaryText =
        Colors.white.withValues(alpha: 0.62);

    final subtleSurface =
        Colors.white.withValues(alpha: 0.075);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        22,
        20,
        22,
        20,
      ),
      decoration: BoxDecoration(
        color: balanceBackground,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0.22 : 0.12,
            ),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total Balance',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: secondaryText,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              IconButton(
                tooltip: _showBalances
                    ? 'Hide balances'
                    : 'Show balances',
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  setState(() {
                    _showBalances = !_showBalances;
                  });
                },
                icon: Icon(
                  _showBalances
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: secondaryText,
                  size: 21,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: subtleSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 19,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _displayBalance(totalBalance),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.1,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            '$accountCount '
            '${accountCount == 1 ? 'account' : 'accounts'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: secondaryText,
              fontWeight: FontWeight.w500,
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
              const SizedBox(width: 10),
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
    final isIncome = title == 'Income';

    final accentColor = isIncome
        ? const Color(0xFF67E8A5)
        : const Color(0xFFFF8F8F);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.065),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.045),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              color: accentColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatAmount(amount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              minimumSize: Size.zero,
              tapTargetSize:
                  MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionText,
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(
    BuildContext context,
    String accountId,
  ) {
    final theme = Theme.of(context);

    final account =
        widget.databaseService.getAccount(accountId);

    if (account == null) {
      return const SizedBox.shrink();
    }

    final balance =
        widget.databaseService.getAccountBalance(account.id);

    final isDark =
        theme.brightness == Brightness.dark;

    final cardColor =
        isDark ? const Color(0xFF1B2740) : _navy;

    return SizedBox(
      width: 276,
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            _openAccountDashboard(account.id);
          },
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color:
                            Colors.white.withValues(alpha: 0.10),
                        borderRadius:
                            BorderRadius.circular(13),
                      ),
                      child: Icon(
                        _accountIcon(account.type),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            account.bankName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white
                                  .withValues(alpha: 0.56),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color:
                          Colors.white.withValues(alpha: 0.45),
                      size: 13,
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  'Available balance',
                  style: TextStyle(
                    color:
                        Colors.white.withValues(alpha: 0.50),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _displayBalance(balance),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountsList(BuildContext context) {
    final accounts = widget.databaseService.accounts;

    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: accounts.length,
        separatorBuilder: (_, _) =>
            const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return _buildAccountCard(
            context,
            accounts[index].id,
          );
        },
      ),
    );
  }

  Widget _buildEmptyAccounts(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color:
                  colorScheme.primary.withValues(alpha: 0.09),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_outlined,
              size: 25,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No accounts yet',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Add your first account to start tracking '
            'your finances.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface
                  .withValues(alpha: 0.52),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _openAccounts,
            icon: const Icon(
              Icons.add_rounded,
              size: 18,
            ),
            label: const Text('Add Account'),
          ),
        ],
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

      subtitle = transaction.note.isNotEmpty
          ? transaction.note
          : _accountName(transaction.accountId);

      iconText =
          _incomeSourceIcon(transaction.categoryId);
    } else {
      title = _categoryName(transaction.categoryId);

      subtitle = transaction.note.isNotEmpty
          ? transaction.note
          : _accountName(transaction.accountId);

      iconText = _categoryIcon(transaction.categoryId);
    }

    final amountColor = isTransfer
        ? colorScheme.primary
        : isIncome
            ? const Color(0xFF16A34A)
            : colorScheme.error;

    final amountPrefix = isTransfer
        ? ''
        : isIncome
            ? '+'
            : '-';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _openTransactions,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: colorScheme.outline
                    .withValues(alpha: 0.07),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: colorScheme.primary
                        .withValues(alpha: 0.08),
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      iconText,
                      style:
                          const TextStyle(fontSize: 19),
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
                        overflow:
                            TextOverflow.ellipsis,
                        style: theme
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              fontWeight:
                                  FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: theme
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: colorScheme
                                  .onSurface
                                  .withValues(
                                alpha: 0.48,
                              ),
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${_formatDate(transaction.date)} • '
                        '${_formatTime(transaction.date)}',
                        style: theme
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              color: colorScheme
                                  .onSurface
                                  .withValues(
                                alpha: 0.35,
                              ),
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$amountPrefix'
                  '${_formatAmount(transaction.amount)}',
                  style: theme
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                        color: amountColor,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
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

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color:
                  colorScheme.primary.withValues(alpha: 0.09),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 25,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No transactions yet',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Add income, expenses or transfers '
            'to see them here.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface
                  .withValues(alpha: 0.52),
            ),
          ),
        ],
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
    final isDark =
        theme.brightness == Brightness.dark;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 7,
              horizontal: 4,
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(
                            alpha: 0.07,
                          )
                        : _navy.withValues(alpha: 0.07),
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                  child: Icon(
                    icon,
                    color: isDark
                        ? Colors.white
                        : _navy,
                    size: 21,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style:
                      theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        _buildQuickAction(
          context,
          icon: Icons.add_card_rounded,
          title: 'Transaction',
          onTap: _openAddTransaction,
        ),
        _buildQuickAction(
          context,
          icon: Icons.receipt_long_rounded,
          title: 'History',
          onTap: _openTransactions,
        ),
        _buildQuickAction(
          context,
          icon: Icons.bar_chart_rounded,
          title: 'Analytics',
          onTap: _openAnalytics,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final accounts = widget.databaseService.accounts;

    final transactions =
        widget.databaseService.transactions.toList()
          ..sort(
            (a, b) => b.date.compareTo(a.date),
          );

    final recentTransactions =
        transactions.take(5).toList();

    final theme = Theme.of(context);
    final isDark =
        theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Expense Tracker',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
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
              // TOTAL BALANCE
              _buildBalanceCard(context),

              const SizedBox(height: 27),

              // ACCOUNTS
              _buildSectionHeader(
                context,
                title: 'Accounts',
                actionText: 'View All',
                onAction: _openAccounts,
              ),

              if (accounts.isEmpty)
                _buildEmptyAccounts(context)
              else
                _buildAccountsList(context),

              const SizedBox(height: 25),

              // QUICK ACTIONS
              _buildSectionHeader(
                context,
                title: 'Quick Access',
                actionText: '',
                onAction: () {},
              ),

              _buildQuickActions(context),

              const SizedBox(height: 27),

              // RECENT TRANSACTIONS
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddTransaction,
        backgroundColor:
            isDark ? const Color(0xFF243451) : _navy,
        foregroundColor: Colors.white,
        elevation: 5,
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