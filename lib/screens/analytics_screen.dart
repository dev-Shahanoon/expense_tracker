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
    return '₹${amount.abs().toStringAsFixed(2)}';
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
        horizontal: 6,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: 0.25,
          ),
        ),
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
            child: Column(
              children: [
                Text(
                  'MONTH',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface.withValues(
                      alpha: 0.45,
                    ),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatMonth(_selectedMonth),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
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

  // ---------------------------------------------------------------------------
  // MONTHLY OVERVIEW
  // ---------------------------------------------------------------------------

  Widget _buildOverviewCard(BuildContext context) {
    final theme = Theme.of(context);

    final isDark =
        theme.brightness == Brightness.dark;

    final backgroundColor = isDark
        ? const Color(0xFF182235)
        : const Color(0xFF17243A);

    final sign = _net > 0
        ? '+'
        : _net < 0
            ? '-'
            : '';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0.18 : 0.08,
            ),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.09,
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Monthly Overview',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(
                    alpha: 0.85,
                  ),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Text(
            'Net Change',
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(
                alpha: 0.50,
              ),
            ),
          ),

          const SizedBox(height: 5),

          // Separate sign from amount so + and ₹ never overlap.
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (sign.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(
                    right: 3,
                  ),
                  child: Text(
                    sign,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              Flexible(
                child: Text(
                  _formatAmount(_net),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            _net >= 0
                ? 'You earned more than you spent'
                : 'You spent more than you earned',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(
                alpha: 0.55,
              ),
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
                  color: const Color(0xFF4ADE80),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildOverviewItem(
                  context,
                  title: 'Expenses',
                  amount: _expense,
                  icon: Icons.arrow_upward_rounded,
                  color: const Color(0xFFFF7B7B),
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
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.07,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 17,
              color: color,
            ),
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
                    color: Colors.white.withValues(
                      alpha: 0.50,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatAmount(amount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SHARED SECTION CARD
  // ---------------------------------------------------------------------------

  Widget _buildSectionCard(
    BuildContext context, {
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final isDark =
        theme.brightness == Brightness.dark;

    // Same dark navy family used by the premium Home UI.
    final backgroundColor = isDark
        ? const Color(0xFF171B24)
        : const Color(0xFFFFFFFF);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFE5E7EB);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: borderColor,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.04,
              ),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: child,
    );
  }

  // ---------------------------------------------------------------------------
  // QUICK STATS
  // ---------------------------------------------------------------------------

  Widget _buildQuickStats(BuildContext context) {
    final theme = Theme.of(context);

    final averageExpense = _expenseTransactions.isEmpty
        ? 0.0
        : _expense / _expenseTransactions.length;

    return _buildSectionCard(
      context,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            context,
            icon: Icons.auto_graph_rounded,
            title: 'Quick Stats',
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
              color: const Color(0xFF182235),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: 0.08,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.trending_up_rounded,
                    color: Color(0xFF7EA8FF),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Top spending category: $_topCategory',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
    final isDark =
        theme.brightness == Brightness.dark;

    final cardColor = isDark
        ? const Color(0xFF202633)
        : const Color(0xFFF6F7F9);

    final iconColor = isDark
        ? const Color(0xFF8FAFFF)
        : const Color(0xFF3559A8);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 17,
              color: iconColor,
            ),
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
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.50),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SPENDING BY CATEGORY
  // ---------------------------------------------------------------------------

  Widget _buildExpenseSection(BuildContext context) {
    final theme = Theme.of(context);
    final categories = _sortedCategories;

    return _buildSectionCard(
      context,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSectionHeader(
                  context,
                  icon: Icons.pie_chart_outline_rounded,
                  title: 'Spending by Category',
                  compact: true,
                ),
              ),
              Text(
                _formatAmount(_expense),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFFF7B7B),
                  fontWeight: FontWeight.w900,
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
                    const EdgeInsets.only(bottom: 18),
                child: _buildCategoryRow(
                  context,
                  entry.key,
                  entry.value,
                ),
              ),
            ),
        ],
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

    final percentage =
        _categoryPercentage(amount);

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: theme.brightness ==
                        Brightness.dark
                    ? const Color(0xFF202633)
                    : const Color(0xFFF6F7F9),
                borderRadius:
                    BorderRadius.circular(13),
              ),
              child: Center(
                child: Text(
                  _categoryIcon(categoryId),
                  style: const TextStyle(
                    fontSize: 19,
                  ),
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
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${(percentage * 100).toStringAsFixed(1)}% of expenses',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface
                          .withValues(alpha: 0.50),
                    ),
                  ),
                ],
              ),
            ),

            Text(
              _formatAmount(amount),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 7,
            backgroundColor:
                theme.brightness == Brightness.dark
                    ? const Color(0xFF282E3A)
                    : const Color(0xFFE9ECF1),
            valueColor:
                const AlwaysStoppedAnimation<Color>(
              Color(0xFF6F8FD8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoExpenses(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 24,
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(
                  alpha: 0.08,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.pie_chart_outline_rounded,
                size: 28,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No expenses this month',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Expense categories will appear here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(
                  alpha: 0.50,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TRANSFER NOTE
  // ---------------------------------------------------------------------------

  Widget _buildTransferNote(BuildContext context) {
    final theme = Theme.of(context);

    final transferCount =
        _transferTransactions.length;

    if (transferCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF182235),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.08,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.swap_horiz_rounded,
              color: Color(0xFF8FAFFF),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$transferCount transfer'
              '${transferCount == 1 ? '' : 's'} included this month. '
              'Transfers are not counted as expenses.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(
                  alpha: 0.72,
                ),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION HEADER
  // ---------------------------------------------------------------------------

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    bool compact = false,
  }) {
    final theme = Theme.of(context);
    final isDark =
        theme.brightness == Brightness.dark;

    final iconColor = isDark
        ? const Color(0xFF8FAFFF)
        : const Color(0xFF3559A8);

    return Row(
      children: [
        Container(
          width: compact ? 34 : 38,
          height: compact ? 34 : 38,
          decoration: BoxDecoration(
            color: iconColor.withValues(
              alpha: 0.10,
            ),
            borderRadius: BorderRadius.circular(
              compact ? 10 : 11,
            ),
          ),
          child: Icon(
            icon,
            size: compact ? 17 : 19,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.15,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Analytics',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
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

            const SizedBox(height: 25),

            Text(
              'Expense Breakdown',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
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