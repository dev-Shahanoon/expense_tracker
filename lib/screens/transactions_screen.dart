import 'package:flutter/material.dart';

import '../data/categories.dart';
import '../data/income_sources.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import 'transaction_details_screen.dart';

enum TransactionDateFilter { all, today, thisWeek, thisMonth, custom }

enum TransactionSortOption {
  newestFirst,
  oldestFirst,
  highestAmount,
  lowestAmount,
}

class TransactionsScreen extends StatefulWidget {
  final DatabaseService databaseService;

  const TransactionsScreen({super.key, required this.databaseService});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  TransactionType? _selectedType;
  TransactionDateFilter _dateFilter = TransactionDateFilter.all;
  TransactionSortOption _sortOption = TransactionSortOption.newestFirst;

  DateTime? _customStartDate;
  DateTime? _customEndDate;
  double? _minimumAmount;
  double? _maximumAmount;
  String? _selectedAccountId;

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (!mounted) return;

    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------

  String _formatAmount(double amount) => amount.toStringAsFixed(2);

  String _formatShortDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';

  String _formatDateTime(DateTime date) {
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
        ? date.hour - 12
        : date.hour;

    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${_formatShortDate(date)} • $hour:$minute $period';
  }

  String _getAccountName(String id) =>
      widget.databaseService.getAccount(id)?.name ?? 'Unknown Account';

  String _getCategoryName(String id) {
    for (final category in expenseCategories) {
      if (category.id == id) {
        return '${category.icon} ${category.name}';
      }
    }

    for (final source in incomeSources) {
      if (source.id == id) {
        return '${source.icon} ${source.name}';
      }
    }

    return 'Other';
  }

  String _getTransactionTitle(TransactionModel transaction) {
    switch (transaction.type) {
      case TransactionType.income:
      case TransactionType.expense:
        return _getCategoryName(transaction.categoryId);
      case TransactionType.transfer:
        return 'Transfer';
      case TransactionType.cardPayment:
        return 'Credit Card Payment';
    }
  }

  IconData _getTransactionIcon(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return Icons.arrow_downward_rounded;
      case TransactionType.expense:
        return Icons.arrow_upward_rounded;
      case TransactionType.transfer:
        return Icons.swap_horiz_rounded;
      case TransactionType.cardPayment:
        return Icons.credit_card_rounded;
    }
  }

  Color _getTransactionColor(BuildContext context, TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return const Color(0xFF22C55E);
      case TransactionType.expense:
        return Theme.of(context).colorScheme.error;
      case TransactionType.transfer:
        return const Color(0xFF4F8CFF);
      case TransactionType.cardPayment:
        return const Color(0xFF9B7BEE);
    }
  }

  // ------------------------------------------------------------
  // FILTERING AND SORTING
  // ------------------------------------------------------------

  List<TransactionModel> get _filteredTransactions {
    final filtered = widget.databaseService.transactions.where((transaction) {
      if (_selectedType != null && transaction.type != _selectedType) {
        return false;
      }

      if (!_matchesSearch(transaction) ||
          !_matchesDateFilter(transaction) ||
          !_matchesAmountFilter(transaction) ||
          !_matchesAccountFilter(transaction)) {
        return false;
      }

      return true;
    }).toList();

    switch (_sortOption) {
      case TransactionSortOption.newestFirst:
        filtered.sort((a, b) => b.date.compareTo(a.date));
        break;
      case TransactionSortOption.oldestFirst:
        filtered.sort((a, b) => a.date.compareTo(b.date));
        break;
      case TransactionSortOption.highestAmount:
        filtered.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case TransactionSortOption.lowestAmount:
        filtered.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }

    return filtered;
  }

  bool _matchesSearch(TransactionModel transaction) {
    if (_searchQuery.isEmpty) return true;

    final destination = transaction.toAccountId == null
        ? ''
        : _getAccountName(transaction.toAccountId!);

    final searchable = [
      _getTransactionTitle(transaction),
      _getAccountName(transaction.accountId),
      destination,
      transaction.type.name,
      transaction.amount.toStringAsFixed(2),
      transaction.note,
    ].join(' ').toLowerCase();

    return searchable.contains(_searchQuery);
  }

  bool _matchesDateFilter(TransactionModel transaction) {
    final date = transaction.date;
    final now = DateTime.now();

    switch (_dateFilter) {
      case TransactionDateFilter.all:
        return true;

      case TransactionDateFilter.today:
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;

      case TransactionDateFilter.thisWeek:
        final today = DateTime(now.year, now.month, now.day);
        final start = today.subtract(Duration(days: today.weekday - 1));
        final end = start.add(const Duration(days: 7));

        return !date.isBefore(start) && date.isBefore(end);

      case TransactionDateFilter.thisMonth:
        return date.year == now.year && date.month == now.month;

      case TransactionDateFilter.custom:
        if (_customStartDate == null || _customEndDate == null) {
          return true;
        }

        final start = DateTime(
          _customStartDate!.year,
          _customStartDate!.month,
          _customStartDate!.day,
        );

        final end = DateTime(
          _customEndDate!.year,
          _customEndDate!.month,
          _customEndDate!.day,
          23,
          59,
          59,
          999,
        );

        return !date.isBefore(start) && !date.isAfter(end);
    }
  }

  bool _matchesAmountFilter(TransactionModel transaction) {
    if (_minimumAmount != null && transaction.amount < _minimumAmount!) {
      return false;
    }

    if (_maximumAmount != null && transaction.amount > _maximumAmount!) {
      return false;
    }

    return true;
  }

  bool _matchesAccountFilter(TransactionModel transaction) {
    if (_selectedAccountId == null) return true;

    return transaction.accountId == _selectedAccountId ||
        transaction.toAccountId == _selectedAccountId;
  }

  // ------------------------------------------------------------
  // FILTER LABELS
  // ------------------------------------------------------------

  String get _dateFilterLabel {
    switch (_dateFilter) {
      case TransactionDateFilter.all:
        return 'Date';
      case TransactionDateFilter.today:
        return 'Today';
      case TransactionDateFilter.thisWeek:
        return 'This Week';
      case TransactionDateFilter.thisMonth:
        return 'This Month';
      case TransactionDateFilter.custom:
        if (_customStartDate == null || _customEndDate == null) {
          return 'Custom';
        }
        return '${_formatShortDate(_customStartDate!)} - '
            '${_formatShortDate(_customEndDate!)}';
    }
  }

  String get _amountFilterLabel {
    if (_minimumAmount != null && _maximumAmount != null) {
      return '₹${_formatAmount(_minimumAmount!)} - '
          '₹${_formatAmount(_maximumAmount!)}';
    }
    if (_minimumAmount != null) {
      return 'Min ₹${_formatAmount(_minimumAmount!)}';
    }
    if (_maximumAmount != null) {
      return 'Max ₹${_formatAmount(_maximumAmount!)}';
    }
    return 'Amount';
  }

  String get _accountFilterLabel {
    if (_selectedAccountId == null) return 'Account';
    return _getAccountName(_selectedAccountId!);
  }

  String get _sortLabel {
    switch (_sortOption) {
      case TransactionSortOption.newestFirst:
        return 'Newest';
      case TransactionSortOption.oldestFirst:
        return 'Oldest';
      case TransactionSortOption.highestAmount:
        return 'Highest';
      case TransactionSortOption.lowestAmount:
        return 'Lowest';
    }
  }

  bool get _hasActiveFilters =>
      _selectedType != null ||
      _dateFilter != TransactionDateFilter.all ||
      _minimumAmount != null ||
      _maximumAmount != null ||
      _selectedAccountId != null;

  // ------------------------------------------------------------
  // TYPE FILTER CHIPS
  // ------------------------------------------------------------

  Widget _buildTypeChip({
    required String label,
    required TransactionType? type,
  }) {
    final theme = Theme.of(context);
    final selected = _selectedType == type;

    Color color = theme.colorScheme.primary;

    if (type == TransactionType.income) {
      color = const Color(0xFF16A34A);
    } else if (type == TransactionType.expense) {
      color = theme.colorScheme.error;
    } else if (type == TransactionType.transfer) {
      color = const Color(0xFF4F8CFF);
    } else if (type == TransactionType.cardPayment) {
      color = const Color(0xFF9B7BEE);
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? color
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected
                ? color
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: selected ? Colors.white : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool active = false,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: active
            ? scheme.primary.withValues(alpha: 0.12)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: active
                    ? scheme.primary.withValues(alpha: 0.35)
                    : scheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: active ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: active ? scheme.primary : scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // TRANSACTION CARD
  // ------------------------------------------------------------

  Widget _buildTransactionCard(TransactionModel transaction) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = _getTransactionColor(context, transaction.type);

    final isIncome = transaction.type == TransactionType.income;
    final isExpense = transaction.type == TransactionType.expense;

    final sourceName = _getAccountName(transaction.accountId);
    final destinationName = transaction.toAccountId == null
        ? null
        : _getAccountName(transaction.toAccountId!);

    final hasDestination =
        transaction.type == TransactionType.transfer ||
        transaction.type == TransactionType.cardPayment;

    final subtitle = hasDestination
        ? '$sourceName → ${destinationName ?? 'Unknown Account'}'
        : sourceName;

    final prefix = isIncome
        ? '+'
        : isExpense
        ? '-'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openTransactionDetails(transaction),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    _getTransactionIcon(transaction.type),
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTransactionTitle(transaction),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      if (transaction.note.trim().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          transaction.note.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        _formatDateTime(transaction.date),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$prefix₹${_formatAmount(transaction.amount)}',
                      maxLines: 1,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Delete transaction',
                      onPressed: () => _deleteTransaction(transaction),
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 19,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // DATE FILTER
  // ------------------------------------------------------------

  Future<void> _showDateFilterSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Filter by date',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              _dateOption(sheetContext, 'All Dates', TransactionDateFilter.all),
              _dateOption(sheetContext, 'Today', TransactionDateFilter.today),
              _dateOption(
                sheetContext,
                'This Week',
                TransactionDateFilter.thisWeek,
              ),
              _dateOption(
                sheetContext,
                'This Month',
                TransactionDateFilter.thisMonth,
              ),
              ListTile(
                leading: const Icon(Icons.date_range_rounded),
                title: const Text('Custom Date Range'),
                selected: _dateFilter == TransactionDateFilter.custom,
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _selectCustomDateRange();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _dateOption(
    BuildContext sheetContext,
    String label,
    TransactionDateFilter filter,
  ) {
    return ListTile(
      leading: const Icon(Icons.calendar_today_rounded),
      title: Text(label),
      selected: _dateFilter == filter,
      trailing: _dateFilter == filter ? const Icon(Icons.check_rounded) : null,
      onTap: () {
        Navigator.pop(sheetContext);
        setState(() {
          _dateFilter = filter;
          _customStartDate = null;
          _customEndDate = null;
        });
      },
    );
  }

  Future<void> _selectCustomDateRange() async {
    final now = DateTime.now();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 10),
      initialDateRange: DateTimeRange(
        start: _customStartDate ?? now,
        end: _customEndDate ?? now,
      ),
    );

    if (!mounted || picked == null) return;

    setState(() {
      _dateFilter = TransactionDateFilter.custom;
      _customStartDate = picked.start;
      _customEndDate = picked.end;
    });
  }

  // ------------------------------------------------------------
  // AMOUNT FILTER
  // ------------------------------------------------------------

  Future<void> _showAmountFilterDialog() async {
    final minimumController = TextEditingController(
      text: _minimumAmount?.toString() ?? '',
    );
    final maximumController = TextEditingController(
      text: _maximumAmount?.toString() ?? '',
    );

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Filter by amount'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: minimumController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Minimum amount',
                    prefixText: '₹ ',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: maximumController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Maximum amount',
                    prefixText: '₹ ',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  minimumController.clear();
                  maximumController.clear();
                  Navigator.pop(dialogContext, true);
                },
                child: const Text('Clear'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final minimum = minimumController.text.trim();
                  final maximum = maximumController.text.trim();

                  final minValue = minimum.isEmpty
                      ? null
                      : double.tryParse(minimum);
                  final maxValue = maximum.isEmpty
                      ? null
                      : double.tryParse(maximum);

                  if ((minimum.isNotEmpty && minValue == null) ||
                      (maximum.isNotEmpty && maxValue == null) ||
                      (minValue != null && minValue < 0) ||
                      (maxValue != null && maxValue < 0) ||
                      (minValue != null &&
                          maxValue != null &&
                          minValue > maxValue)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Enter valid amounts. Minimum must not exceed maximum.',
                        ),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(dialogContext, true);
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      );

      if (!mounted || result != true) return;

      setState(() {
        _minimumAmount = minimumController.text.trim().isEmpty
            ? null
            : double.tryParse(minimumController.text.trim());

        _maximumAmount = maximumController.text.trim().isEmpty
            ? null
            : double.tryParse(maximumController.text.trim());
      });
    } finally {
      minimumController.dispose();
      maximumController.dispose();
    }
  }

  // ------------------------------------------------------------
  // ACCOUNT FILTER
  // ------------------------------------------------------------

  Future<void> _showAccountFilterSheet() async {
    final accounts = widget.databaseService.accounts;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Filter by account',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.account_balance_rounded),
                title: const Text('All Accounts'),
                selected: _selectedAccountId == null,
                trailing: _selectedAccountId == null
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() => _selectedAccountId = null);
                },
              ),
              ...accounts.map((account) {
                final selected = _selectedAccountId == account.id;

                return ListTile(
                  leading: Icon(
                    account.isCreditCard
                        ? Icons.credit_card_rounded
                        : Icons.account_balance_rounded,
                  ),
                  title: Text(account.name),
                  subtitle: account.bankName.isNotEmpty
                      ? Text(account.bankName)
                      : null,
                  selected: selected,
                  trailing: selected ? const Icon(Icons.check_rounded) : null,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    setState(() {
                      _selectedAccountId = account.id;
                    });
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // SORT
  // ------------------------------------------------------------

  Future<void> _showSortSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Sort transactions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              _sortOptionTile(
                sheetContext,
                'Newest First',
                TransactionSortOption.newestFirst,
                Icons.arrow_downward_rounded,
              ),
              _sortOptionTile(
                sheetContext,
                'Oldest First',
                TransactionSortOption.oldestFirst,
                Icons.arrow_upward_rounded,
              ),
              _sortOptionTile(
                sheetContext,
                'Highest Amount',
                TransactionSortOption.highestAmount,
                Icons.trending_up_rounded,
              ),
              _sortOptionTile(
                sheetContext,
                'Lowest Amount',
                TransactionSortOption.lowestAmount,
                Icons.trending_down_rounded,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sortOptionTile(
    BuildContext sheetContext,
    String label,
    TransactionSortOption option,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: _sortOption == option,
      trailing: _sortOption == option ? const Icon(Icons.check_rounded) : null,
      onTap: () {
        Navigator.pop(sheetContext);
        setState(() => _sortOption = option);
      },
    );
  }

  // ------------------------------------------------------------
  // CLEAR FILTERS
  // ------------------------------------------------------------

  void _clearFilters() {
    setState(() {
      _selectedType = null;
      _dateFilter = TransactionDateFilter.all;
      _customStartDate = null;
      _customEndDate = null;
      _minimumAmount = null;
      _maximumAmount = null;
      _selectedAccountId = null;
      _sortOption = TransactionSortOption.newestFirst;
      _searchController.clear();
      _searchQuery = '';
    });
  }

  // ------------------------------------------------------------
  // DETAILS AND DELETE
  // ------------------------------------------------------------

  Future<void> _openTransactionDetails(TransactionModel transaction) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TransactionDetailsScreen(
          databaseService: widget.databaseService,
          transaction: transaction,
        ),
      ),
    );

    if (!mounted) return;

    if (changed == true) {
      setState(() {});
    }
  }

  Future<void> _deleteTransaction(TransactionModel transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: const Text('This transaction will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    await widget.databaseService.deleteTransaction(transaction.id);

    if (!mounted) return;

    setState(() {});

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Transaction deleted.')));
  }

  // ------------------------------------------------------------
  // EMPTY STATE
  // ------------------------------------------------------------

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    final hasFilters = _hasActiveFilters || _searchQuery.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilters
                  ? Icons.search_off_rounded
                  : Icons.receipt_long_rounded,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 18),
            Text(
              hasFilters ? 'No matching transactions' : 'No transactions yet',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Try changing or clearing your filters.'
                  : 'Your transactions will appear here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (hasFilters) ...[
              const SizedBox(height: 18),
              FilledButton.tonalIcon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.filter_alt_off_rounded),
                label: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transactions = _filteredTransactions;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transactions',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.4),
        ),
        actions: [
          IconButton(
            tooltip: 'Sort transactions',
            onPressed: _showSortSheet,
            icon: const Icon(Icons.swap_vert_rounded),
          ),
          if (_hasActiveFilters || _searchQuery.isNotEmpty)
            IconButton(
              tooltip: 'Clear filters',
              onPressed: _clearFilters,
              icon: const Icon(Icons.filter_alt_off_rounded),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: _searchController.clear,
                        icon: const Icon(Icons.close_rounded),
                      )
                    : null,
              ),
            ),
          ),

          SizedBox(
            height: 43,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                _buildTypeChip(label: 'All', type: null),
                const SizedBox(width: 8),
                _buildTypeChip(label: 'Income', type: TransactionType.income),
                const SizedBox(width: 8),
                _buildTypeChip(label: 'Expense', type: TransactionType.expense),
                const SizedBox(width: 8),
                _buildTypeChip(
                  label: 'Transfer',
                  type: TransactionType.transfer,
                ),
                const SizedBox(width: 8),
                _buildTypeChip(
                  label: 'Card Payment',
                  type: TransactionType.cardPayment,
                ),
              ],
            ),
          ),

          const SizedBox(height: 9),

          SizedBox(
            height: 43,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip(
                  label: _accountFilterLabel,
                  icon: Icons.account_balance_rounded,
                  active: _selectedAccountId != null,
                  onTap: _showAccountFilterSheet,
                ),
                _buildFilterChip(
                  label: _dateFilterLabel,
                  icon: Icons.calendar_month_rounded,
                  active: _dateFilter != TransactionDateFilter.all,
                  onTap: _showDateFilterSheet,
                ),
                _buildFilterChip(
                  label: _amountFilterLabel,
                  icon: Icons.currency_rupee_rounded,
                  active: _minimumAmount != null || _maximumAmount != null,
                  onTap: _showAmountFilterDialog,
                ),
                _buildFilterChip(
                  label: _sortLabel,
                  icon: Icons.sort_rounded,
                  active: _sortOption != TransactionSortOption.newestFirst,
                  onTap: _showSortSheet,
                ),
              ],
            ),
          ),

          const SizedBox(height: 5),

          if (transactions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(17, 3, 17, 7),
              child: Row(
                children: [
                  Text(
                    '${transactions.length} '
                    '${transactions.length == 1 ? 'transaction' : 'transactions'}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _sortLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: transactions.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 5, 16, 28),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) =>
                        _buildTransactionCard(transactions[index]),
                  ),
          ),
        ],
      ),
    );
  }
}
