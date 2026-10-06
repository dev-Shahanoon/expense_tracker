import 'package:flutter/material.dart';

import '../data/categories.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';

class AnalyticsScreen extends StatefulWidget {
  final DatabaseService databaseService;

  const AnalyticsScreen({
    super.key,
    required this.databaseService,
  });

  @override
  State<AnalyticsScreen> createState() =>
      _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  DateTime _selectedMonth = DateTime.now();

  String _formatAmount(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  String _formatMonth(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.year}';
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();

    return _selectedMonth.year == now.year &&
        _selectedMonth.month == now.month;
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
      );
    });
  }

  void _nextMonth() {
    if (_isCurrentMonth) {
      return;
    }

    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
      );
    });
  }

  List<TransactionModel> get _monthlyTransactions {
    return widget.databaseService
        .getTransactionsForMonth(_selectedMonth);
  }

  List<TransactionModel> get _expenseTransactions {
    return _monthlyTransactions
        .where(
          (transaction) =>
              transaction.type == TransactionType.expense,
        )
        .toList();
  }

  List<TransactionModel> get _incomeTransactions {
    return _monthlyTransactions
        .where(
          (transaction) =>
              transaction.type == TransactionType.income,
        )
        .toList();
  }

  List<TransactionModel> get _transferTransactions {
    return _monthlyTransactions
        .where(
          (transaction) =>
              transaction.type == TransactionType.transfer,
        )
        .toList();
  }

  double get _income {
    return _incomeTransactions.fold(
      0,
      (total, transaction) => total + transaction.amount,
    );
  }

  double get _expense {
    return _expenseTransactions.fold(
      0,
      (total, transaction) => total + transaction.amount,
    );
  }

  double get _net {
    return _income - _expense;
  }

  Map<String, double> get _categoryTotals {
    final totals = <String, double>{};

    for (final transaction in _expenseTransactions) {
      totals[transaction.categoryId] =
          (totals[transaction.categoryId] ?? 0) +
              transaction.amount;
    }

    return totals;
  }

  List<MapEntry<String, double>> get _sortedCategories {
    final entries = _categoryTotals.entries.toList();

    entries.sort(
      (a, b) => b.value.compareTo(a.value),
    );

    return entries;
  }

  String get _topCategory {
    if (_sortedCategories.isEmpty) {
      return 'No expenses';
    }

    return _categoryName(_sortedCategories.first.key);
  }

  String _categoryName(String id) {
    for (final category in expenseCategories) {
      if (category.id == id) {
        return category.name;
      }
    }

    return 'Other';
  }

  String _categoryIcon(String id) {
    for (final category in expenseCategories) {
      if (category.id == id) {
        return category.icon;
      }
    }

    return '📦';
  }

  double _categoryPercentage(double amount) {
    if (_expense <= 0) {
      return 0;
    }

    return amount / _expense;
  }

  Widget _buildMonthSelector(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _previousMonth,
            tooltip: 'Previous month',
            icon: const Icon(
              Icons.chevron_left_rounded,
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                _formatMonth(_selectedMonth),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed:
                _isCurrentMonth ? null : _nextMonth,
            tooltip: 'Next month',
            icon: const Icon(
              Icons.chevron_right_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Overview',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onPrimary
                  .withValues(alpha: 0.75),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatAmount(_net),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _net >= 0
                ? 'Net amount remaining'
                : 'Expenses are higher than income',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onPrimary
                  .withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _buildOverviewItem(
                  context,
                  title: 'Income',
                  amount: _income,
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOverviewItem(
                  context,
                  title: 'Expenses',
                  amount: _expense,
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(
    BuildContext context, {
    required String title,
    required double amount,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.onPrimary
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 19,
            color: colorScheme.onPrimary,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimary
                        .withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatAmount(amount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
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

  Widget _buildQuickStats(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final averageExpense = _expenseTransactions.isEmpty
        ? 0.0
        : _expense / _expenseTransactions.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Stats',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    title: 'Transactions',
                    value: '${_monthlyTransactions.length}',
                    icon: Icons.receipt_long_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatItem(
                    context,
                    title: 'Categories',
                    value: '${_sortedCategories.length}',
                    icon: Icons.category_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    title: 'Transfers',
                    value: '${_transferTransactions.length}',
                    icon: Icons.swap_horiz_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatItem(
                    context,
                    title: 'Avg. Expense',
                    value: _formatAmount(averageExpense),
                    icon: Icons.calculate_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer
                    .withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.trending_up_rounded,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Top spending category: $_topCategory',
                      style:
                          theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface
                        .withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
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

  Widget _buildExpenseSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categories = _sortedCategories;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Spending by Category',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  _formatAmount(_expense),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (categories.isEmpty)
              _buildNoExpenses(context)
            else
              ...categories.map(
                (entry) => Padding(
                  padding:
                      const EdgeInsets.only(bottom: 17),
                  child: _buildCategoryRow(
                    context,
                    entry.key,
                    entry.value,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRow(
    BuildContext context,
    String categoryId,
    double amount,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final percentage = _categoryPercentage(amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  _categoryIcon(categoryId),
                  style: const TextStyle(fontSize: 19),
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    _categoryName(categoryId),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${(percentage * 100).toStringAsFixed(1)}% of expenses',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface
                          .withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _formatAmount(amount),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 7,
            backgroundColor:
                colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }

  Widget _buildNoExpenses(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.pie_chart_outline_rounded,
              size: 42,
              color: colorScheme.primary
                  .withValues(alpha: 0.65),
            ),
            const SizedBox(height: 10),
            Text(
              'No expenses this month',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Expense categories will appear here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface
                    .withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferNote(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final transferCount = _transferTransactions.length;

    if (transferCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.swap_horiz_rounded,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              '$transferCount transfer${transferCount == 1 ? '' : 's'} '
              'included this month. Transfers are not counted as expenses.',
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.4,
                color: colorScheme.onSurface
                    .withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Analytics',
          style: TextStyle(
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
            _buildMonthSelector(context),

            const SizedBox(height: 18),

            _buildOverviewCard(context),

            const SizedBox(height: 20),

            Text(
              'Expense Breakdown',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 10),

            _buildExpenseSection(context),

            const SizedBox(height: 20),

            _buildQuickStats(context),

            const SizedBox(height: 14),

            _buildTransferNote(context),
          ],
        ),
      ),
    );
  }
}