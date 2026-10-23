import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../widgets/bank_logo.dart';
import '../data/categories.dart';
import '../data/income_sources.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../services/theme_controller.dart';
import 'accounts_screen.dart';
import 'add_transaction_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';
import 'transactions_screen.dart';
import 'loans_screen.dart';

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

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _showBalances = false;
  bool _showAccountBalances = false;
  bool _showNetWorth = false;

  int _overviewFaceIndex = 0;
  String _chartPeriod = 'Week';
  int _weekOffset = 0;

  late final AnimationController _flipController;
  late final Animation<double> _flipAnimation;
  late final AnimationController _overviewController;
  late final Animation<double> _overviewAnimation;

  static const _teal = Color(0xFF20C9B5);
  static const _income = Color(0xFF22A879);
  static const _expense = Color(0xFFE7656D);
  static const _transfer = Color(0xFF598FE8);
  static const _payment = Color(0xFF9575D5);

  static const _gradientColors = [
    Color(0xFF087D72),
    Color(0xFF079D90),
    Color(0xFF12B7A9),
  ];

  static const _lightText = Color(0xFFD1F3ED);

  DatabaseService get _db => widget.databaseService;

  bool get _dark => Theme.of(context).brightness == Brightness.dark;

  Color get _background =>
      _dark ? const Color(0xFF101719) : const Color(0xFFF5F8F7);

  Color get _surface => _dark ? const Color(0xFF192326) : Colors.white;

  Color get _surfaceAlt =>
      _dark ? const Color(0xFF202D30) : const Color(0xFFEDF4F1);

  Color get _border =>
      _dark ? const Color(0xFF2A393B) : const Color(0xFFE3ECE8);

  Color get _text => _dark ? const Color(0xFFF0F6F4) : const Color(0xFF182622);

  Color get _muted => _dark ? const Color(0xFF96AAA5) : const Color(0xFF788A84);

  @override
  void initState() {
    super.initState();

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _flipAnimation = CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOutCubic,
    );

    _overviewController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _overviewAnimation = CurvedAnimation(
      parent: _overviewController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    _overviewController.dispose();
    super.dispose();
  }

  String _money(double amount) =>
      '₹${amount.toStringAsFixed(2).replaceFirst(RegExp(r'\.00$'), '')}';

  String _display(double amount) => _showBalances ? _money(amount) : '••••••';

  String _displayAccount(double amount) =>
      _showAccountBalances ? _money(amount) : '••••••';

  String _date(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]}';
  }

  String _accountName(String id) =>
      _db.getAccount(id)?.name ?? 'Unknown account';

  String _categoryName(String id) {
    for (final category in expenseCategories) {
      if (category.id == id) return category.name;
    }
    return 'Other';
  }

  String _categoryIcon(String id) {
    for (final category in expenseCategories) {
      if (category.id == id) return category.icon;
    }
    return '📦';
  }

  String _incomeName(String id) {
    for (final source in incomeSources) {
      if (source.id == id) return source.name;
    }
    return 'Income';
  }

  String _incomeIcon(String id) {
    for (final source in incomeSources) {
      if (source.id == id) return source.icon;
    }
    return '💰';
  }

  Future<void> _openAdd() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(databaseService: _db),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openAccounts() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AccountsScreen(databaseService: _db)),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openLoans() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LoansScreen(databaseService: _db)),
    );

    if (mounted) setState(() {});
  }

  Future<void> _openTransactions() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransactionsScreen(databaseService: _db),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openAnalytics() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AnalyticsScreen(databaseService: _db)),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          databaseService: _db,
          themeController: widget.themeController,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  void _toggleFlipCard() {
    if (_flipController.isAnimating) return;

    setState(() => _showNetWorth = !_showNetWorth);

    if (_showNetWorth) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
  }

  void _nextOverviewFace({bool reverse = false}) {
    if (_overviewController.isAnimating) return;

    setState(() {
      _overviewFaceIndex = (_overviewFaceIndex + (reverse ? 2 : 1)) % 3;
    });
    _overviewController.forward(from: 0);
  }

  void _toggleTotalPrivacy() {
    setState(() => _showBalances = !_showBalances);
  }

  void _toggleAccountPrivacy() {
    setState(() => _showAccountBalances = !_showAccountBalances);
  }

  BoxDecoration _decoration({double radius = 22}) {
    return BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _border),
    );
  }

  // Shared gradient for all three overview faces.
  BoxDecoration _overviewCardDecoration() {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _gradientColors,
      ),
      borderRadius: BorderRadius.circular(25),
      boxShadow: [
        BoxShadow(
          color: _teal.withValues(alpha: _dark ? 0.10 : 0.16),
          blurRadius: 22,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Widget _heading(String title, {String? action, VoidCallback? onAction}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: _text,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.45,
              ),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: _dark
                    ? const Color(0xFF61E0D0)
                    : const Color(0xFF087F73),
                padding: const EdgeInsets.symmetric(horizontal: 3),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(action),
                  const SizedBox(width: 3),
                  const Icon(Icons.arrow_forward_rounded, size: 15),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // THREE-FACE OVERVIEW
  // ------------------------------------------------------------

  Widget _overviewCard() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _nextOverviewFace(),
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -100) {
          _nextOverviewFace();
        } else if (velocity > 100) {
          _nextOverviewFace(reverse: true);
        }
      },
      child: SizedBox(
        height: 310,
        child: AnimatedBuilder(
          animation: _overviewAnimation,
          builder: (context, child) {
            final angle = _overviewAnimation.value * math.pi;
            final showBack = angle >= math.pi / 2;

            final matrix = Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle);

            return Transform(
              alignment: Alignment.center,
              transform: matrix,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateY(showBack ? math.pi : 0),
                child: SizedBox.expand(child: _buildOverviewFace()),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOverviewFace() {
    switch (_overviewFaceIndex) {
      case 0:
        return _balanceCard();
      case 1:
        return _individualAccountsFace();
      case 2:
        return _creditCardsFace();
      default:
        return _balanceCard();
    }
  }

  Widget _faceFooter(String label) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.swipe_rounded, size: 14, color: _lightText),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _lightText, fontSize: 10),
            ),
          ),
          const SizedBox(width: 8),
          for (var i = 0; i < 3; i++) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: _overviewFaceIndex == i ? 15 : 5,
              height: 5,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: _overviewFaceIndex == i
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _faceHeader({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String hint,
    required VoidCallback onPrivacy,
    required bool visible,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: _lightText, size: 21),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _lightText, fontSize: 10),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onPrivacy,
          tooltip: visible ? 'Hide amounts' : 'Show amounts',
          visualDensity: VisualDensity.compact,
          icon: Icon(
            visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 3),
        _flipHint(Icons.flip_rounded, hint),
      ],
    );
  }

  Widget _flipHint(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _lightText),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: _lightText,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _balanceCard() {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: _overviewCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'TOTAL BALANCE',
                  style: TextStyle(
                    color: Color(0xFFD4F6F0),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
              IconButton(
                onPressed: _toggleTotalPrivacy,
                tooltip: _showBalances ? 'Hide amounts' : 'Show amounts',
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  _showBalances
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              _flipHint(Icons.flip_rounded, 'Accounts'),
            ],
          ),
          const SizedBox(height: 1),
          Text(
            _display(_db.totalBalance),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 31,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: _lightText,
                size: 15,
              ),
              const SizedBox(width: 7),
              Text(
                '${_db.accounts.length} '
                '${_db.accounts.length == 1 ? 'account' : 'accounts'}',
                style: const TextStyle(color: _lightText, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.20)),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _balanceStat(
                  'Income',
                  _db.totalIncome,
                  Icons.south_west_rounded,
                  const Color.fromARGB(255, 4, 230, 113),
                ),
              ),
              Container(
                width: 1,
                height: 39,
                color: Colors.white.withValues(alpha: 0.20),
              ),
              const SizedBox(width: 17),
              Expanded(
                child: _balanceStat(
                  'Expenses',
                  _db.totalExpense,
                  Icons.north_east_rounded,
                  const Color.fromARGB(255, 235, 31, 31),
                ),
              ),
            ],
          ),
          const Spacer(),
          _faceFooter('Tap or swipe to view accounts'),
        ],
      ),
    );
  }

  Widget _balanceStat(
    String label,
    double amount,
    IconData icon,
    Color accent,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: accent),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: _lightText, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _display(amount),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // FACE 2: ACCOUNTS
  // ------------------------------------------------------------

  Widget _individualAccountsFace() {
    final accounts = _db.accounts
        .where((account) => !account.isCreditCard)
        .toList();

    final visibleAccounts = accounts.take(10).toList();

    const lightText = Color(0xFFD1F3ED);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _overviewCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _faceHeader(
            icon: Icons.account_balance_rounded,
            color: lightText,
            title: 'My accounts',
            subtitle: '${accounts.length} bank and cash accounts',
            hint: 'Credit cards',
            onPrivacy: _toggleAccountPrivacy,
            visible: _showAccountBalances,
          ),

          const SizedBox(height: 8),

          Expanded(
            child: visibleAccounts.isEmpty
                ? const Center(
                    child: Text(
                      'No bank or cash accounts yet',
                      style: TextStyle(color: lightText, fontSize: 12),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    physics: const ClampingScrollPhysics(),
                    itemCount: visibleAccounts.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 8,
                      thickness: 1,
                      color: Colors.white.withValues(alpha: 0.20),
                    ),
                    itemBuilder: (context, index) {
                      final account = visibleAccounts[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            BankLogo(bankName: account.bankName, size: 36),
                            const SizedBox(width: 10),

                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    account.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    account.bankName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: lightText,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),

                            Flexible(
                              child: Text(
                                _displayAccount(
                                  _db.getAccountBalance(account.id),
                                ),
                                textAlign: TextAlign.end,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          if (accounts.length > 10)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _openAccounts,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('View all accounts'),
              ),
            ),

          const SizedBox(height: 4),
          _faceFooter('Tap or swipe to view credit cards'),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // FACE 3: CREDIT CARDS
  // ------------------------------------------------------------

  Widget _creditCardsFace() {
    final allCards = _db.accounts
        .where((account) => account.isCreditCard)
        .toList();

    final cards = allCards.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _overviewCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _faceHeader(
            icon: Icons.credit_card_rounded,
            color: const Color(0xFFD1F3ED),
            title: 'Credit cards',
            subtitle: '${allCards.length} card(s) · Credit overview',
            hint: 'Total balance',
            onPrivacy: _toggleAccountPrivacy,
            visible: _showAccountBalances,
          ),
          const SizedBox(height: 8),

          Expanded(
            child: cards.isEmpty
                ? const Center(
                    child: Text(
                      'No credit cards added yet',
                      style: TextStyle(color: Color(0xFFD1F3ED), fontSize: 12),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    physics: const ClampingScrollPhysics(),
                    itemCount: cards.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 8,
                      thickness: 1,
                      color: Colors.white.withValues(alpha: 0.20),
                    ),
                    itemBuilder: (context, index) {
                      return _creditCardRow(cards[index]);
                    },
                  ),
          ),

          if (allCards.length > 3)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _openAccounts,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('View all cards'),
              ),
            ),

          const SizedBox(height: 4),
          _faceFooter('Tap or swipe to return to total balance'),
        ],
      ),
    );
  }

  Widget _creditCardRow(dynamic account) {
    final outstanding = _db.getCreditCardOutstanding(account.id);
    final available = _db.getAvailableCredit(account.id);
    final limit = (account.creditLimit as num?)?.toDouble() ?? 0.0;

    final usage = limit <= 0
        ? 0.0
        : (outstanding / limit).clamp(0.0, 1.0).toDouble();

    const spentColor = Color.fromARGB(255, 235, 31, 31);
    const availableColor = Color.fromARGB(255, 4, 230, 113);
    const secondaryColor = Color(0xFFD1F3ED);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BankLogo(bankName: account.bankName as String?, size: 34),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  account.name as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _displayAccount(outstanding),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: spentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'AVAILABLE',
                      style: TextStyle(
                        color: secondaryColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _displayAccount(available),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: availableColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'CREDIT LIMIT',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: secondaryColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _displayAccount(limit),
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: usage,
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.24),
              valueColor: const AlwaysStoppedAnimation<Color>(spentColor),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // SPENDING ACTIVITY CHART
  // ------------------------------------------------------------

  String _weekRangeLabel() {
    final now = DateUtils.dateOnly(DateTime.now());
    final currentMonday = now.subtract(
      Duration(days: now.weekday - DateTime.monday),
    );

    final monday = currentMonday.add(Duration(days: _weekOffset * 7));
    final sunday = monday.add(const Duration(days: 6));

    return '${_date(monday)} – ${_date(sunday)}';
  }

  List<_ChartPoint> _chartPoints() {
    final now = DateTime.now();

    // Expenses only; exclude income and transfers.
    final expenses = _db.transactions.where(
      (t) => t.type == TransactionType.expense,
    );

    if (_chartPeriod == 'Week') {
      final today = DateUtils.dateOnly(now);
      final currentMonday = today.subtract(
        Duration(days: today.weekday - DateTime.monday),
      );

      final monday = currentMonday.add(Duration(days: _weekOffset * 7));

      const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

      return List.generate(7, (i) {
        final day = monday.add(Duration(days: i));

        final total = expenses
            .where((t) {
              final transactionDay = DateUtils.dateOnly(t.date);
              return transactionDay == day;
            })
            .fold<double>(0, (sum, t) => sum + t.amount);

        return _ChartPoint(labels[i], total);
      });
    }

    if (_chartPeriod == 'Month') {
      final firstOfNextMonth = DateTime(now.year, now.month + 1, 1);
      final daysInMonth = firstOfNextMonth
          .subtract(const Duration(days: 1))
          .day;
      final bucketCount = (daysInMonth / 7).ceil();

      return List.generate(bucketCount, (i) {
        final startDay = i * 7 + 1;
        final endDay = math.min(startDay + 7, daysInMonth + 1);

        final start = DateTime(now.year, now.month, startDay);
        final end = DateTime(now.year, now.month, endDay);

        final total = expenses
            .where((t) => !t.date.isBefore(start) && t.date.isBefore(end))
            .fold<double>(0, (sum, t) => sum + t.amount);

        return _ChartPoint('$startDay', total);
      });
    }

    const labels = [
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

    return List.generate(12, (i) {
      final start = DateTime(now.year, i + 1, 1);
      final end = DateTime(now.year, i + 2, 1);

      final total = expenses
          .where((t) => !t.date.isBefore(start) && t.date.isBefore(end))
          .fold<double>(0, (sum, t) => sum + t.amount);

      return _ChartPoint(labels[i], total);
    });
  }

  Widget _spendingChartFace() {
    final points = _chartPoints();
    final total = points.fold<double>(0, (sum, p) => sum + p.amount);
    final maximum = points.fold<double>(
      0,
      (value, point) => math.max(value, point.amount),
    );

    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.fromLTRB(17, 17, 17, 16),
      decoration: _decoration(radius: 23),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Spending activity',
                  style: TextStyle(
                    color: _text,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _flipHint(Icons.flip_rounded, 'Net worth'),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: _surfaceAlt,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: ['Week', 'Month', 'Year'].map((period) {
                final selected = _chartPeriod == period;
                return GestureDetector(
                  onTap: () => setState(() => _chartPeriod = period),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? (_dark
                                ? const Color(0xFF35D6C3)
                                : const Color(0xFFB8F0E7))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      period,
                      style: TextStyle(
                        color: selected ? const Color(0xFF10322D) : _muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (_chartPeriod == 'Week') ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  tooltip: 'Previous week',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    setState(() {
                      _weekOffset--;
                    });
                  },
                  icon: Icon(
                    Icons.chevron_left_rounded,
                    color: _text,
                    size: 25,
                  ),
                ),
                Text(
                  _weekRangeLabel(),
                  style: TextStyle(
                    color: _text,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  tooltip: 'Next week',
                  visualDensity: VisualDensity.compact,
                  onPressed: _weekOffset < 0
                      ? () {
                          setState(() {
                            _weekOffset++;
                          });
                        }
                      : null,
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    color: _weekOffset < 0
                        ? _text
                        : _muted.withValues(alpha: 0.35),
                    size: 25,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(
            _display(total),
            style: TextStyle(
              color: _text,
              fontSize: 25,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _chartPeriod == 'Week'
                ? 'Expenses for ${_weekRangeLabel()}'
                : _chartPeriod == 'Month'
                ? 'Expenses this month'
                : 'Expenses this year',
            style: TextStyle(color: _muted, fontSize: 11),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 105,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: points.map((point) {
                final ratio = maximum == 0 ? 0.0 : point.amount / maximum;
                final height = maximum == 0 ? 4.0 : math.max(5.0, ratio * 68.0);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              width: double.infinity,
                              constraints: const BoxConstraints(maxWidth: 24),
                              height: height,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: point.amount == maximum && maximum > 0
                                      ? const [
                                          Color(0xFF39D9C6),
                                          Color(0xFF14A998),
                                        ]
                                      : [
                                          _teal.withValues(
                                            alpha: _dark ? 0.45 : 0.36,
                                          ),
                                          _teal.withValues(
                                            alpha: _dark ? 0.20 : 0.14,
                                          ),
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          point.label,
                          style: TextStyle(
                            color: _muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Spacer(),
          Center(
            child: Text(
              'Tap or swipe to view net worth',
              style: TextStyle(color: _muted, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // NET WORTH
  // ------------------------------------------------------------

  Widget _netWorthFace() {
    final assets = _db.totalBalance;
    final debt = _db.totalCreditCardDebt;
    final netWorth = _db.netBalanceAfterCreditCardDebt;

    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(Icons.account_balance_wallet_rounded, _teal),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Net worth',
                      style: TextStyle(
                        color: _text,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Assets minus credit-card debt',
                      style: TextStyle(color: _muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              _flipHint(Icons.flip_rounded, 'Spending'),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _dark
                    ? const [Color(0xFF203C39), Color(0xFF19302D)]
                    : const [Color(0xFFE0F8F1), Color(0xFFF0FAF6)],
              ),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR NET WORTH',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  _display(netWorth),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: netWorth < 0 ? _expense : _text,
                    fontSize: 29,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.9,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _netWorthDetail(
                  label: 'Total assets',
                  amount: assets,
                  icon: Icons.trending_up_rounded,
                  color: _income,
                ),
              ),
              Container(width: 1, height: 43, color: _border),
              const SizedBox(width: 14),
              Expanded(
                child: _netWorthDetail(
                  label: 'Card debt',
                  amount: debt,
                  icon: Icons.credit_card_rounded,
                  color: _expense,
                ),
              ),
            ],
          ),
          const Spacer(),
          Center(
            child: Text(
              'Tap or swipe to view spending activity',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _netWorthDetail({
    required String label,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 19),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: _muted, fontSize: 11)),
              const SizedBox(height: 5),
              Text(
                _display(amount),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _text,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _iconBox(IconData icon, Color color, {double size = 43}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: _dark ? 0.15 : 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }

  Widget _flipCard() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleFlipCard,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity.abs() > 100) _toggleFlipCard();
      },
      child: SizedBox(
        height: 370,
        child: AnimatedBuilder(
          animation: _flipAnimation,
          builder: (context, child) {
            final angle = _flipAnimation.value * math.pi;
            final showBack = angle >= math.pi / 2;

            final matrix = Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle);

            return Transform(
              alignment: Alignment.center,
              transform: matrix,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateY(showBack ? math.pi : 0),
                child: SizedBox.expand(
                  child: showBack ? _netWorthFace() : _spendingChartFace(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // EMPTY STATE
  // ------------------------------------------------------------

  Widget _emptyState(
    IconData icon,
    String title,
    String message, {
    String? buttonLabel,
    VoidCallback? onTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _decoration(),
      child: Column(
        children: [
          _iconBox(icon, _teal, size: 49),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(color: _text, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 12),
          ),
          if (buttonLabel != null) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: onTap, child: Text(buttonLabel)),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // RECENT TRANSACTIONS
  // ------------------------------------------------------------

  Widget _transactions() {
    final transactions = _db.transactions.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final recent = transactions.take(4).toList();

    if (recent.isEmpty) {
      return _emptyState(
        Icons.receipt_long_outlined,
        'No transactions yet',
        'Your recent income and expenses will appear here.',
        buttonLabel: 'Add transaction',
        onTap: _openAdd,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      decoration: _decoration(),
      child: Column(
        children: [
          for (var i = 0; i < recent.length; i++) ...[
            _transactionRow(recent[i]),
            if (i < recent.length - 1) Divider(height: 1, color: _border),
          ],
        ],
      ),
    );
  }

  Widget _transactionRow(TransactionModel transaction) {
    final isIncome = transaction.type == TransactionType.income;
    final isTransfer = transaction.type == TransactionType.transfer;
    final isPayment = transaction.type == TransactionType.cardPayment;

    late final String title;
    late final String subtitle;
    late final String emoji;
    late final Color accent;

    if (isTransfer) {
      title = 'Transfer';
      subtitle =
          '${_accountName(transaction.accountId)} → '
          '${_accountName(transaction.toAccountId ?? '')}';
      emoji = '↔️';
      accent = _transfer;
    } else if (isPayment) {
      title = 'Credit card payment';
      subtitle =
          '${_accountName(transaction.accountId)} → '
          '${_accountName(transaction.toAccountId ?? '')}';
      emoji = '💳';
      accent = _payment;
    } else if (isIncome) {
      title = _incomeName(transaction.categoryId);
      subtitle = transaction.note.isNotEmpty
          ? transaction.note
          : _accountName(transaction.accountId);
      emoji = _incomeIcon(transaction.categoryId);
      accent = _income;
    } else {
      title = _categoryName(transaction.categoryId);
      subtitle = transaction.note.isNotEmpty
          ? transaction.note
          : _accountName(transaction.accountId);
      emoji = _categoryIcon(transaction.categoryId);
      accent = _expense;
    }

    final prefix = isIncome
        ? '+'
        : isTransfer || isPayment
        ? ''
        : '−';

    final amountColor = isIncome
        ? _income
        : isTransfer || isPayment
        ? _teal
        : _expense;

    return InkWell(
      onTap: _openTransactions,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: _dark ? 0.15 : 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 19)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _text,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$subtitle · ${_date(transaction.date)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: _muted, fontSize: 10),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                '$prefix${_display(transaction.amount)}',
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: amountColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
// ------------------------------------------------------------
// FLOATING PILL BOTTOM NAVIGATION
// ------------------------------------------------------------

Widget _bottomNavigation() {
  final accent = _dark
      ? const Color(0xFF35D6C3)
      : const Color(0xFF087F73);

  return Container(
    color: _background,
    child: SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: _dark ? 0.16 : 0.055,
              ),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _navItem(
                icon: Icons.account_balance_rounded,
                label: 'Accounts',
                onTap: _openAccounts,
              ),
            ),
            Expanded(
              child: _navItem(
                icon: Icons.receipt_long_rounded,
                label: 'Activity',
                onTap: _openTransactions,
              ),
            ),

            // Centered pill-shaped Add button
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 54,
                  height: 54,
                  child: Material(
                    color: accent,
                    borderRadius: BorderRadius.circular(27),
                    child: InkWell(
                      onTap: _openAdd,
                      borderRadius: BorderRadius.circular(27),
                      child: const Center(
                        child: Icon(
                          Icons.add_rounded,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              child: _navItem(
                icon: Icons.analytics_rounded,
                label: 'Analytics',
                onTap: _openAnalytics,
              ),
            ),
            Expanded(
              child: _navItem(
                icon: Icons.payments_outlined,
                label: 'Loans',
                onTap: _openLoans,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _navItem({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 21,
              color: _muted,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _muted,
                fontSize: 9,
                height: 1.1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
  // ------------------------------------------------------------
  // HOME SCREEN
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: TextStyle(
                color: _muted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Your finances',
              style: TextStyle(
                color: _text,
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.7,
              ),
            ),
          ],
        ),
        
actions: [
  IconButton(
    tooltip: 'Settings',
    onPressed: _openSettings,
    icon: Icon(Icons.tune_rounded, color: _text),
  ),
  const SizedBox(width: 6),
],

      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (mounted) setState(() {});
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(17, 7, 17, 24),
            children: [
              _overviewCard(),
              const SizedBox(height: 18),
              _flipCard(),
              const SizedBox(height: 25),
              _heading(
                'Recent activity',
                action: 'View all',
                onAction: _openTransactions,
              ),
              _transactions(),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _bottomNavigation(),
    );
  }
}

class _ChartPoint {
  final String label;
  final double amount;

  const _ChartPoint(this.label, this.amount);
}
