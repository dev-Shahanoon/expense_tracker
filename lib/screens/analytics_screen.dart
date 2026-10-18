
import 'dart:math' as math;

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
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  static const Color teal = Color(0xFF078D83);
  static const Color turquoise = Color(0xFF10B5A5);
  static const Color navy = Color(0xFF172C2A);
  static const Color red = Color(0xFFFF8585);
  static const Color muted = Color(0xFF82918E);

  late DateTime _selectedMonth;
  late AnimationController _flipController;

  bool _showDistribution = false;

  static const List<Color> _chartColors = [
    Color(0xFF8DF0E2),
    Color(0xFF4ADE80),
    Color(0xFFFFC078),
    Color(0xFFB9A4FF),
    Color(0xFFFF8585),
    Color(0xFF78D8FF),
    Color(0xFFFFDF78),
  ];

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flipCard() {
    setState(() {
      _showDistribution = !_showDistribution;
    });

    if (_showDistribution) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    if (_isCurrentMonth) return;

    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year &&
        _selectedMonth.month == now.month;
  }

  List<TransactionModel> get _monthlyTransactions =>
      widget.databaseService.getTransactionsForMonth(_selectedMonth);

  List<TransactionModel> get _expenseTransactions =>
      _monthlyTransactions
          .where((t) => t.type == TransactionType.expense)
          .toList();

  List<TransactionModel> get _incomeTransactions =>
      _monthlyTransactions
          .where((t) => t.type == TransactionType.income)
          .toList();

  List<TransactionModel> get _transferTransactions =>
      _monthlyTransactions
          .where((t) => t.type == TransactionType.transfer)
          .toList();

  double get _income => _incomeTransactions.fold(
        0.0,
        (sum, t) => sum + t.amount,
      );

  double get _expense => _expenseTransactions.fold(
        0.0,
        (sum, t) => sum + t.amount,
      );

  double get _net => _income - _expense;

  Map<String, double> get _categoryTotals {
    final totals = <String, double>{};

    for (final transaction in _expenseTransactions) {
      totals.update(
        transaction.categoryId,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }

    return totals;
  }

  List<MapEntry<String, double>> get _sortedCategories {
    final entries = _categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  String get _topCategory => _sortedCategories.isEmpty
      ? 'None'
      : _categoryName(_sortedCategories.first.key);

  String _categoryName(String id) {
    for (final category in expenseCategories) {
      if (category.id == id) return category.name;
    }
    return id;
  }

  String _categoryIcon(String id) {
    for (final category in expenseCategories) {
      if (category.id == id) return category.icon;
    }
    return '📁';
  }

  String _money(double amount) => '₹${amount.toStringAsFixed(2)}';

  String get _monthLabel {
    const months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December',
    ];

    return '${months[_selectedMonth.month - 1]} ${_selectedMonth.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F7),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
          children: [
            const Text(
              'Analytics',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: navy,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Understand your money at a glance.',
              style: TextStyle(fontSize: 14, color: muted),
            ),
            const SizedBox(height: 24),
            _buildMonthSelector(),
            const SizedBox(height: 18),
            _buildFlipCard(),
            const SizedBox(height: 22),
            _buildQuickStats(),
            const SizedBox(height: 22),
            _buildCategoryBreakdown(),
            if (_transferTransactions.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildTransferNote(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0EBE8)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _previousMonth,
            icon: const Icon(Icons.chevron_left_rounded),
            color: teal,
          ),
          Expanded(
            child: Text(
              _monthLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: navy,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: _isCurrentMonth ? null : _nextMonth,
            icon: const Icon(Icons.chevron_right_rounded),
            color: _isCurrentMonth ? const Color(0xFFD0DAD7) : teal,
          ),
        ],
      ),
    );
  }

  Widget _buildFlipCard() {
    return GestureDetector(
      onTap: _flipCard,
      child: AnimatedBuilder(
        animation: _flipController,
        builder: (context, child) {
          final angle = _flipController.value * math.pi;
          final showBack = angle >= math.pi / 2;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateY(angle),
            child: showBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(math.pi),
                    child: _buildDistributionFace(),
                  )
                : _buildOverviewFace(),
          );
        },
      ),
    );
  }

  Widget _cardShell({required Widget child}) {
    return Container(
      height: 350,
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [teal, turquoise],
        ),
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: teal.withValues(alpha: 0.22),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildOverviewFace() {
    return _cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'MONTHLY OVERVIEW',
                  style: TextStyle(
                    color: Color(0xFFC7F6EF),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              _flipButton(
                Icons.donut_large_rounded,
                'Distribution',
              ),
            ],
          ),
          const SizedBox(height: 25),
          const Text(
            'Net change',
            style: TextStyle(color: Color.fromARGB(255, 240, 237, 237), fontSize: 13),
          ),
          const SizedBox(height: 7),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${_net >= 0 ? '+' : '-'}${_money(_net.abs())}',
              style: TextStyle(
                color: _net >= 0 ? Colors.white : const Color.fromARGB(221, 224, 67, 67),
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.22),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _overviewMetric(
                  icon: Icons.south_west_rounded,
                  label: 'Income', 
                  amount: _income,
                  color: const Color.fromARGB(255, 11, 232, 45),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _overviewMetric(
                  icon: Icons.north_east_rounded,
                  label: 'Expenses',
                  amount: _expense,
                  color: const Color.fromARGB(255, 214, 29, 0),
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(
                Icons.touch_app_rounded,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'Tap card to view distribution',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                ),
              ),
              Text(
                '${_monthlyTransactions.length} records',
                style: const TextStyle(
                  color: Color(0xFFD1F8F2),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _overviewMetric({
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFD1F8F2),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _money(amount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDistributionFace() {
    final categories = _sortedCategories;

    return _cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'EXPENSE DISTRIBUTION',
                  style: TextStyle(
                    color: Color(0xFFC7F6EF),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              _flipButton(
                Icons.account_balance_wallet_rounded,
                'Overview',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(140, 140),
                        painter: _DonutPainter(
                          values: categories.map((e) => e.value).toList(),
                          colors: _chartColors,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'TOTAL SPENT',
                            style: TextStyle(
                              color: Color(0xFFD1F8F2),
                              fontSize: 9,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 5),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _money(_expense),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: categories.isEmpty
                      ? const Center(
                          child: Text(
                            'No expenses yet',
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: math.min(categories.length, 5),
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final entry = categories[index];
                            final color =
                                _chartColors[index % _chartColors.length];
                            final percentage = _expense == 0
                                ? 0.0
                                : entry.value / _expense * 100;

                            return Row(
                              children: [
                                Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _categoryName(entry.key),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${percentage.toStringAsFixed(0)}%',
                                        style: const TextStyle(
                                          color: Color(0xFFD1F8F2),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(
                Icons.touch_app_rounded,
                size: 15,
                color: Colors.white,
              ),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'Tap card to return to overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                ),
              ),
              Text(
                '${categories.length} categories',
                style: const TextStyle(
                  color: Color(0xFFD1F8F2),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _flipButton(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.17),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final averageExpense = _expenseTransactions.isEmpty
        ? 0.0
        : _expense / _expenseTransactions.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick insights',
          style: TextStyle(
            color: navy,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 13),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.65,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _statCard(
              icon: Icons.receipt_long_rounded,
              title: 'Transactions',
              value: '${_monthlyTransactions.length}',
              color: teal,
            ),
            _statCard(
              icon: Icons.swap_horiz_rounded,
              title: 'Transfers',
              value: '${_transferTransactions.length}',
              color: const Color(0xFF8A79D6),
            ),
            _statCard(
              icon: Icons.payments_rounded,
              title: 'Average expense',
              value: _money(averageExpense),
              color: red,
            ),
            _statCard(
              icon: Icons.local_offer_rounded,
              title: 'Top category',
              value: _topCategory,
              color: const Color(0xFFE5A34F),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0EBE8)),
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
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: muted, fontSize: 11),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 14,
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

  Widget _buildCategoryBreakdown() {
    final categories = _sortedCategories;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE0EBE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category breakdown',
            style: TextStyle(
              color: navy,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Where your money went this month',
            style: TextStyle(color: muted, fontSize: 12),
          ),
          const SizedBox(height: 20),
          if (categories.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No expense records for this month.',
                  style: TextStyle(color: muted),
                ),
              ),
            )
          else
            ...categories.asMap().entries.map((item) {
              final entry = item.value;
              final percentage =
                  _expense == 0 ? 0.0 : entry.value / _expense;
              final color =
                  _chartColors[item.key % _chartColors.length];

              return Padding(
                padding: const EdgeInsets.only(bottom: 19),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              _categoryIcon(entry.key),
                              style: const TextStyle(fontSize: 19),
                            ),
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            _categoryName(entry.key),
                            style: const TextStyle(
                              color: navy,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          _money(entry.value),
                          style: const TextStyle(
                            color: navy,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: percentage.clamp(0.0, 1.0),
                        minHeight: 7,
                        backgroundColor: const Color(0xFFEAF2EF),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${(percentage * 100).toStringAsFixed(1)}% of expenses',
                        style: const TextStyle(
                          color: muted,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildTransferNote() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFE1F7F2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.swap_horiz_rounded, color: teal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${_transferTransactions.length} transfer(s) this month. '
              'Transfers are shown separately and are not counted as income or expenses.',
              style: const TextStyle(
                color: Color(0xFF176B62),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  _DonutPainter({
    required this.values,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 16.0;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final total = values.fold<double>(0, (sum, value) => sum + value);

    if (total <= 0) {
      paint.color = const Color(0xFFBDEDE5);
      canvas.drawArc(rect, 0, math.pi * 2, false, paint);
      return;
    }

    var startAngle = -math.pi / 2;

    for (var i = 0; i < values.length; i++) {
      if (values[i] <= 0) continue;

      final sweepAngle = values[i] / total * math.pi * 2;
      paint.color = colors[i % colors.length];

      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}
