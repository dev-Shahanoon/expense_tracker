import 'package:flutter/material.dart';

import '../data/categories.dart';
import '../data/income_sources.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import 'transaction_details_screen.dart';

enum TransactionDateFilter {
  all,
  today,
  thisWeek,
  thisMonth,
  custom,
}

enum TransactionSortOption {
  newestFirst,
  oldestFirst,
  highestAmount,
  lowestAmount,
}

class TransactionsScreen extends StatefulWidget {
  final DatabaseService databaseService;

  const TransactionsScreen({
    super.key,
    required this.databaseService,
  });

  @override
  State<TransactionsScreen> createState() =>
      _TransactionsScreenState();
}

class _TransactionsScreenState
    extends State<TransactionsScreen> {
  TransactionType? _selectedType;

  TransactionDateFilter _dateFilter =
      TransactionDateFilter.all;

  TransactionSortOption _sortOption =
      TransactionSortOption.newestFirst;

  DateTime? _customStartDate;
  DateTime? _customEndDate;

  double? _minimumAmount;
  double? _maximumAmount;

  String? _selectedAccountId;

  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        _searchQuery =
            _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================================
  // FILTERING + SORTING
  // ==========================================================

  List<TransactionModel> get _filteredTransactions {
    final transactions = List<TransactionModel>.from(
      widget.databaseService.transactions,
    );

    final filtered = transactions.where((transaction) {
      if (_selectedType != null &&
          transaction.type != _selectedType) {
        return false;
      }

      if (!_matchesSearch(transaction)) {
        return false;
      }

      if (!_matchesDateFilter(transaction)) {
        return false;
      }

      if (!_matchesAmountFilter(transaction)) {
        return false;
      }

      if (!_matchesAccountFilter(transaction)) {
        return false;
      }

      return true;
    }).toList();

    _sortTransactions(filtered);

    return filtered;
  }

  void _sortTransactions(
    List<TransactionModel> transactions,
  ) {
    switch (_sortOption) {
      case TransactionSortOption.newestFirst:
        transactions.sort(
          (a, b) => b.date.compareTo(a.date),
        );
        break;

      case TransactionSortOption.oldestFirst:
        transactions.sort(
          (a, b) => a.date.compareTo(b.date),
        );
        break;

      case TransactionSortOption.highestAmount:
        transactions.sort(
          (a, b) => b.amount.compareTo(a.amount),
        );
        break;

      case TransactionSortOption.lowestAmount:
        transactions.sort(
          (a, b) => a.amount.compareTo(b.amount),
        );
        break;
    }
  }

  // ==========================================================
  // SEARCH
  // ==========================================================

  bool _matchesSearch(
    TransactionModel transaction,
  ) {
    if (_searchQuery.isEmpty) {
      return true;
    }

    final categoryName =
        _getCategoryName(transaction.categoryId);

    final accountName =
        _getAccountName(transaction.accountId);

    final destinationAccountName =
        transaction.toAccountId == null
            ? ''
            : _getAccountName(
                transaction.toAccountId!,
              );

    final typeName =
        transaction.type.name.toLowerCase();

    final amountText =
        transaction.amount.toStringAsFixed(2);

    final note =
        transaction.note.toLowerCase();

    final searchableText = [
      categoryName,
      accountName,
      destinationAccountName,
      typeName,
      amountText,
      note,
    ].join(' ').toLowerCase();

    return searchableText.contains(_searchQuery);
  }

  // ==========================================================
  // DATE FILTER
  // ==========================================================

  bool _matchesDateFilter(
    TransactionModel transaction,
  ) {
    final transactionDate = transaction.date;
    final now = DateTime.now();

    switch (_dateFilter) {
      case TransactionDateFilter.all:
        return true;

      case TransactionDateFilter.today:
        return transactionDate.year == now.year &&
            transactionDate.month == now.month &&
            transactionDate.day == now.day;

      case TransactionDateFilter.thisWeek:
        final today = DateTime(
          now.year,
          now.month,
          now.day,
        );

        final startOfWeek = today.subtract(
          Duration(
            days: today.weekday - 1,
          ),
        );

        final endOfWeek = startOfWeek.add(
          const Duration(days: 7),
        );

        return !transactionDate.isBefore(
              startOfWeek,
            ) &&
            transactionDate.isBefore(
              endOfWeek,
            );

      case TransactionDateFilter.thisMonth:
        return transactionDate.year == now.year &&
            transactionDate.month == now.month;

      case TransactionDateFilter.custom:
        if (_customStartDate == null ||
            _customEndDate == null) {
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

        return !transactionDate.isBefore(start) &&
            !transactionDate.isAfter(end);
    }
  }

  // ==========================================================
  // AMOUNT FILTER
  // ==========================================================

  bool _matchesAmountFilter(
    TransactionModel transaction,
  ) {
    if (_minimumAmount != null &&
        transaction.amount < _minimumAmount!) {
      return false;
    }

    if (_maximumAmount != null &&
        transaction.amount > _maximumAmount!) {
      return false;
    }

    return true;
  }

  // ==========================================================
  // ACCOUNT FILTER
  // ==========================================================

  bool _matchesAccountFilter(
    TransactionModel transaction,
  ) {
    if (_selectedAccountId == null) {
      return true;
    }

    return transaction.accountId ==
            _selectedAccountId ||
        transaction.toAccountId ==
            _selectedAccountId;
  }

  // ==========================================================
  // NAMES
  // ==========================================================

  String _getAccountName(String accountId) {
    final account =
        widget.databaseService.getAccount(accountId);

    return account?.name ?? 'Unknown Account';
  }

  String _getCategoryName(String categoryId) {
    for (final category in expenseCategories) {
      if (category.id == categoryId) {
        return '${category.icon} ${category.name}';
      }
    }

    for (final source in incomeSources) {
      if (source.id == categoryId) {
        return '${source.icon} ${source.name}';
      }
    }

    return 'Other';
  }

  // ==========================================================
  // LABELS
  // ==========================================================

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
        if (_customStartDate == null ||
            _customEndDate == null) {
          return 'Custom';
        }

        return '${_formatShortDate(_customStartDate!)} - '
            '${_formatShortDate(_customEndDate!)}';
    }
  }

  String get _amountFilterLabel {
    if (_minimumAmount != null &&
        _maximumAmount != null) {
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
    if (_selectedAccountId == null) {
      return 'Account';
    }

    final account =
        widget.databaseService.getAccount(
      _selectedAccountId!,
    );

    return account?.name ?? 'Account';
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

  bool get _hasActiveFilters {
    return _selectedType != null ||
        _dateFilter != TransactionDateFilter.all ||
        _minimumAmount != null ||
        _maximumAmount != null ||
        _selectedAccountId != null;
  }

  // ==========================================================
  // DATE FILTER
  // ==========================================================

  Future<void> _showDateFilterSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Date Filter',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDateOption(
                  sheetContext,
                  'All Dates',
                  TransactionDateFilter.all,
                ),
                _buildDateOption(
                  sheetContext,
                  'Today',
                  TransactionDateFilter.today,
                ),
                _buildDateOption(
                  sheetContext,
                  'This Week',
                  TransactionDateFilter.thisWeek,
                ),
                _buildDateOption(
                  sheetContext,
                  'This Month',
                  TransactionDateFilter.thisMonth,
                ),
                ListTile(
                  leading: const Icon(
                    Icons.date_range_rounded,
                  ),
                  title: const Text(
                    'Custom Date Range',
                  ),
                  trailing: _dateFilter ==
                          TransactionDateFilter.custom
                      ? const Icon(
                          Icons.check_rounded,
                        )
                      : null,
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await _selectCustomDateRange();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateOption(
    BuildContext context,
    String title,
    TransactionDateFilter filter,
  ) {
    final selected = _dateFilter == filter;

    return ListTile(
      leading: Icon(
        selected
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_off_rounded,
      ),
      title: Text(title),
      onTap: () {
        Navigator.of(context).pop();

        setState(() {
          _dateFilter = filter;

          if (filter !=
              TransactionDateFilter.custom) {
            _customStartDate = null;
            _customEndDate = null;
          }
        });
      },
    );
  }

  Future<void> _selectCustomDateRange() async {
    final now = DateTime.now();

    final initialStart =
        _customStartDate ?? now;

    final initialEnd =
        _customEndDate ?? now;

    final picked =
        await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(
        now.year + 10,
      ),
      initialDateRange: DateTimeRange(
        start: initialStart.isAfter(initialEnd)
            ? initialEnd
            : initialStart,
        end: initialEnd.isBefore(initialStart)
            ? initialStart
            : initialEnd,
      ),
    );

    if (!mounted || picked == null) {
      return;
    }

    setState(() {
      _dateFilter =
          TransactionDateFilter.custom;
      _customStartDate = picked.start;
      _customEndDate = picked.end;
    });
  }

  // ==========================================================
  // AMOUNT FILTER
  // ==========================================================

  Future<void> _showAmountFilterDialog() async {
    String minimumText =
        _minimumAmount?.toStringAsFixed(2) ?? '';

    String maximumText =
        _maximumAmount?.toStringAsFixed(2) ?? '';

    final result =
        await showDialog<Map<String, double?>>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Amount Filter',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: minimumText,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration:
                      const InputDecoration(
                    labelText: 'Minimum amount',
                    prefixText: '₹ ',
                    hintText: 'Example: 500',
                  ),
                  onChanged: (value) {
                    minimumText = value;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: maximumText,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration:
                      const InputDecoration(
                    labelText: 'Maximum amount',
                    prefixText: '₹ ',
                    hintText: 'Example: 5000',
                  ),
                  onChanged: (value) {
                    maximumText = value;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(
                  <String, double?>{
                    'minimum': null,
                    'maximum': null,
                  },
                );
              },
              child: const Text('Clear'),
            ),
            FilledButton(
              onPressed: () {
                final minimum =
                    double.tryParse(
                  minimumText.trim(),
                );

                final maximum =
                    double.tryParse(
                  maximumText.trim(),
                );

                if (minimumText.trim().isNotEmpty &&
                    minimum == null) {
                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Enter a valid minimum amount.',
                      ),
                    ),
                  );
                  return;
                }

                if (maximumText.trim().isNotEmpty &&
                    maximum == null) {
                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Enter a valid maximum amount.',
                      ),
                    ),
                  );
                  return;
                }

                if (minimum != null &&
                    maximum != null &&
                    minimum > maximum) {
                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Minimum amount cannot be greater than maximum amount.',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.of(dialogContext).pop(
                  <String, double?>{
                    'minimum': minimum,
                    'maximum': maximum,
                  },
                );
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _minimumAmount = result['minimum'];
      _maximumAmount = result['maximum'];
    });
  }

  // ==========================================================
  // ACCOUNT FILTER
  // ==========================================================

  Future<void> _showAccountFilterSheet() async {
    final accounts =
        widget.databaseService.accounts;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Account Filter',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: Icon(
                    _selectedAccountId == null
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                  ),
                  title: const Text(
                    'All Accounts',
                  ),
                  onTap: () {
                    Navigator.of(
                      sheetContext,
                    ).pop();

                    setState(() {
                      _selectedAccountId = null;
                    });
                  },
                ),
                if (accounts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No accounts available.',
                    ),
                  ),
                ...accounts.map(
                  (account) {
                    final selected =
                        _selectedAccountId ==
                            account.id;

                    return ListTile(
                      leading: Icon(
                        selected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                      ),
                      title: Text(
                        account.name,
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        account.bankName,
                      ),
                      trailing:
                          account.lastFourDigits ==
                                  null
                              ? null
                              : Text(
                                  '•••• ${account.lastFourDigits}',
                                ),
                      onTap: () {
                        Navigator.of(
                          sheetContext,
                        ).pop();

                        setState(() {
                          _selectedAccountId =
                              account.id;
                        });
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // SORT
  // ==========================================================

  Future<void> _showSortSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sort Transactions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSortOption(
                  sheetContext,
                  'Newest First',
                  'Latest transactions first',
                  TransactionSortOption.newestFirst,
                  Icons.arrow_downward_rounded,
                ),
                _buildSortOption(
                  sheetContext,
                  'Oldest First',
                  'Earliest transactions first',
                  TransactionSortOption.oldestFirst,
                  Icons.arrow_upward_rounded,
                ),
                _buildSortOption(
                  sheetContext,
                  'Highest Amount',
                  'Largest transactions first',
                  TransactionSortOption.highestAmount,
                  Icons.trending_up_rounded,
                ),
                _buildSortOption(
                  sheetContext,
                  'Lowest Amount',
                  'Smallest transactions first',
                  TransactionSortOption.lowestAmount,
                  Icons.trending_down_rounded,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortOption(
    BuildContext context,
    String title,
    String subtitle,
    TransactionSortOption option,
    IconData icon,
  ) {
    final selected =
        _sortOption == option;

    return ListTile(
      leading: Icon(icon),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: selected
          ? const Icon(
              Icons.check_rounded,
            )
          : null,
      onTap: () {
        Navigator.of(context).pop();

        setState(() {
          _sortOption = option;
        });
      },
    );
  }

  // ==========================================================
  // CLEAR
  // ==========================================================

  void _clearFilters() {
    setState(() {
      _selectedType = null;

      _dateFilter =
          TransactionDateFilter.all;

      _customStartDate = null;
      _customEndDate = null;

      _minimumAmount = null;
      _maximumAmount = null;

      _selectedAccountId = null;

      _sortOption =
          TransactionSortOption.newestFirst;

      _searchController.clear();
      _searchQuery = '';
    });
  }

  // ==========================================================
  // OPEN DETAILS
  // ==========================================================

  Future<void> _openTransactionDetails(
    TransactionModel transaction,
  ) async {
    final deleted =
        await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) {
          return TransactionDetailsScreen(
            databaseService:
                widget.databaseService,
            transaction: transaction,
          );
        },
      ),
    );

    if (!mounted) {
      return;
    }

    if (deleted == true) {
      setState(() {});
    }
  }

  // ==========================================================
  // HELPERS
  // ==========================================================

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(2);
  }

  String _formatShortDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatDateTime(DateTime date) {
    final hour =
        date.hour == 0
            ? 12
            : date.hour > 12
                ? date.hour - 12
                : date.hour;

    final minute =
        date.minute.toString().padLeft(2, '0');

    final period =
        date.hour >= 12 ? 'PM' : 'AM';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} • '
        '$hour:$minute $period';
  }

  IconData _getTransactionIcon(
    TransactionModel transaction,
  ) {
    switch (transaction.type) {
      case TransactionType.income:
        return Icons.arrow_downward_rounded;

      case TransactionType.expense:
        return Icons.arrow_upward_rounded;

      case TransactionType.transfer:
        return Icons.swap_horiz_rounded;
    }
  }

  String _getTransactionTitle(
    TransactionModel transaction,
  ) {
    switch (transaction.type) {
      case TransactionType.income:
        return _getCategoryName(
          transaction.categoryId,
        );

      case TransactionType.expense:
        return _getCategoryName(
          transaction.categoryId,
        );

      case TransactionType.transfer:
        return 'Transfer';
    }
  }

  // ==========================================================
  // FILTER CHIP
  // ==========================================================

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        right: 8,
      ),
      child: FilterChip(
        avatar: Icon(
          icon,
          size: 18,
        ),
        label: Text(
          label,
          overflow: TextOverflow.ellipsis,
        ),
        selected: active,
        onSelected: (_) {
          onTap();
        },
      ),
    );
  }

  // ==========================================================
  // TRANSACTION CARD
  // ==========================================================

  Widget _buildTransactionCard(
    TransactionModel transaction,
  ) {
    final isIncome =
        transaction.type ==
            TransactionType.income;

    final isExpense =
        transaction.type ==
            TransactionType.expense;

    final isTransfer =
        transaction.type ==
            TransactionType.transfer;

    final accountName =
        _getAccountName(
      transaction.accountId,
    );

    final destinationAccountName =
        transaction.toAccountId == null
            ? null
            : _getAccountName(
                transaction.toAccountId!,
              );

    final title =
        _getTransactionTitle(
      transaction,
    );

    String subtitle;

    if (isTransfer) {
      subtitle =
          '$accountName → '
          '${destinationAccountName ?? 'Unknown Account'}';
    } else {
      subtitle = accountName;
    }

    if (transaction.note.isNotEmpty) {
      subtitle +=
          '\n${transaction.note}';
    }

    final amountText =
        '${isIncome ? '+' : isExpense ? '-' : ''}'
        '₹${_formatAmount(transaction.amount)}';

    final amountColor = isIncome
        ? Colors.green
        : isExpense
            ? Colors.red
            : Colors.blue;

    return Card(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _openTransactionDetails(
            transaction,
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(16),
                  color: isIncome
                      ? Colors.green.withValues(
                          alpha: 0.12,
                        )
                      : isExpense
                          ? Colors.red.withValues(
                              alpha: 0.12,
                            )
                          : Colors.blue.withValues(
                              alpha: 0.12,
                            ),
                ),
                child: Icon(
                  _getTransactionIcon(
                    transaction,
                  ),
                  color: amountColor,
                  size: 28,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.25,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      _formatDateTime(
                        transaction.date,
                      ),
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  Text(
                    amountText,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontWeight:
                          FontWeight.w800,
                      fontSize: 16,
                      color: amountColor,
                    ),
                  ),

                  const SizedBox(height: 6),

                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      tooltip: 'Delete',
                      padding: EdgeInsets.zero,
                      visualDensity:
                          VisualDensity.compact,
                      onPressed: () {
                        _deleteTransaction(
                          transaction,
                        );
                      },
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 21,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // DELETE
  // ==========================================================

  Future<void> _deleteTransaction(
    TransactionModel transaction,
  ) async {
    final confirmed =
        await showDialog<bool>(
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
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    await widget.databaseService
        .deleteTransaction(
      transaction.id,
    );

    if (!mounted) {
      return;
    }

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Transaction deleted.',
        ),
      ),
    );
  }

  // ==========================================================
  // EMPTY STATE
  // ==========================================================

  Widget _buildEmptyState() {
    final hasFilters =
        _hasActiveFilters ||
            _searchQuery.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              hasFilters
                  ? Icons.search_off_rounded
                  : Icons.receipt_long_rounded,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant,
            ),

            const SizedBox(height: 16),

            Text(
              hasFilters
                  ? 'No matching transactions'
                  : 'No transactions yet',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              hasFilters
                  ? 'Try changing or clearing your filters.'
                  : 'Your transactions will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),

            if (hasFilters) ...[
              const SizedBox(height: 20),
              FilledButton.tonal(
                onPressed: _clearFilters,
                child: const Text(
                  'Clear Filters',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final transactions =
        _filteredTransactions;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transactions',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Sort transactions',
            onPressed: _showSortSheet,
            icon: const Icon(
              Icons.sort_rounded,
            ),
          ),
          if (_hasActiveFilters ||
              _searchQuery.isNotEmpty)
            IconButton(
              tooltip: 'Clear filters',
              onPressed: _clearFilters,
              icon: const Icon(
                Icons.filter_alt_off_rounded,
              ),
            ),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              8,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText:
                    'Search transactions...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                ),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController
                                  .clear();
                            },
                            icon: const Icon(
                              Icons.clear_rounded,
                            ),
                          )
                        : null,
              ),
            ),
          ),

          SizedBox(
            height: 48,
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              scrollDirection:
                  Axis.horizontal,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected:
                      _selectedType == null,
                  onSelected: (_) {
                    setState(() {
                      _selectedType = null;
                    });
                  },
                ),

                const SizedBox(width: 8),

                ChoiceChip(
                  label: const Text('Income'),
                  selected:
                      _selectedType ==
                          TransactionType.income,
                  onSelected: (_) {
                    setState(() {
                      _selectedType =
                          TransactionType.income;
                    });
                  },
                ),

                const SizedBox(width: 8),

                ChoiceChip(
                  label: const Text('Expense'),
                  selected:
                      _selectedType ==
                          TransactionType.expense,
                  onSelected: (_) {
                    setState(() {
                      _selectedType =
                          TransactionType.expense;
                    });
                  },
                ),

                const SizedBox(width: 8),

                ChoiceChip(
                  label: const Text('Transfer'),
                  selected:
                      _selectedType ==
                          TransactionType.transfer,
                  onSelected: (_) {
                    setState(() {
                      _selectedType =
                          TransactionType.transfer;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          SizedBox(
            height: 52,
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              scrollDirection:
                  Axis.horizontal,
              children: [
                _buildFilterChip(
                  label: _accountFilterLabel,
                  icon:
                      Icons.account_balance_rounded,
                  active:
                      _selectedAccountId != null,
                  onTap:
                      _showAccountFilterSheet,
                ),

                _buildFilterChip(
                  label: _dateFilterLabel,
                  icon:
                      Icons.calendar_month_rounded,
                  active:
                      _dateFilter !=
                          TransactionDateFilter.all,
                  onTap:
                      _showDateFilterSheet,
                ),

                _buildFilterChip(
                  label: _amountFilterLabel,
                  icon:
                      Icons.currency_rupee_rounded,
                  active:
                      _minimumAmount != null ||
                          _maximumAmount != null,
                  onTap:
                      _showAmountFilterDialog,
                ),

                _buildFilterChip(
                  label: _sortLabel,
                  icon: Icons.sort_rounded,
                  active:
                      _sortOption !=
                          TransactionSortOption.newestFirst,
                  onTap:
                      _showSortSheet,
                ),

                if (_hasActiveFilters ||
                    _searchQuery.isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.only(
                      left: 4,
                    ),
                    child: ActionChip(
                      avatar: const Icon(
                        Icons.clear_rounded,
                        size: 18,
                      ),
                      label:
                          const Text('Clear'),
                      onPressed:
                          _clearFilters,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          Expanded(
            child: transactions.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      24,
                    ),
                    itemCount:
                        transactions.length,
                    itemBuilder:
                        (context, index) {
                      return _buildTransactionCard(
                        transactions[index],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}