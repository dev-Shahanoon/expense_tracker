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

    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (!mounted) {
      return;
    }

    setState(() {
      _searchQuery =
          _searchController.text.trim().toLowerCase();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();

    super.dispose();
  }

  // ==========================================================
  // FILTERING
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
          Duration(days: today.weekday - 1),
        );

        final endOfWeek = startOfWeek.add(
          const Duration(days: 7),
        );

        return !transactionDate.isBefore(startOfWeek) &&
            transactionDate.isBefore(endOfWeek);

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

    return transaction.accountId == _selectedAccountId ||
        transaction.toAccountId == _selectedAccountId;
  }

  // ==========================================================
  // HELPERS
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

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(2);
  }

  String _formatShortDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatDateTime(DateTime date) {
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;

    final minute =
        date.minute.toString().padLeft(2, '0');

    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} • $hour:$minute $period';
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
  // TRANSACTION COLORS
  // ==========================================================

  Color _getTransactionColor(
    BuildContext context,
    TransactionType type,
  ) {
    switch (type) {
      case TransactionType.income:
        return const Color(0xFF22C55E);

      case TransactionType.expense:
        return Theme.of(context).colorScheme.error;

      case TransactionType.transfer:
        return const Color(0xFF4F8CFF);
    }
  }

  Color _getTransactionBackground(
    BuildContext context,
    TransactionType type,
  ) {
    final color =
        _getTransactionColor(context, type);

    return color.withValues(alpha: 0.09);
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
      case TransactionType.expense:
        return _getCategoryName(
          transaction.categoryId,
        );

      case TransactionType.transfer:
        return 'Transfer';
    }
  }

  // ==========================================================
  // TYPE CHIPS
  // ==========================================================

  Widget _buildTypeChip({
    required BuildContext context,
    required String label,
    required TransactionType? type,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final selected = _selectedType == type;

    Color selectedColor = colorScheme.primary;

    if (type == TransactionType.income) {
      selectedColor = const Color(0xFF16A34A);
    } else if (type == TransactionType.expense) {
      selectedColor = colorScheme.error;
    } else if (type == TransactionType.transfer) {
      selectedColor = const Color(0xFF4F8CFF);
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: selected
              ? selectedColor
              : colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.28),
          borderRadius:
              BorderRadius.circular(13),
          border: Border.all(
            color: selected
                ? selectedColor
                : colorScheme.outlineVariant
                    .withValues(alpha: 0.28),
          ),
        ),
        child: Text(
          label,
          style:
              theme.textTheme.labelLarge?.copyWith(
            color: selected
                ? Colors.white
                : colorScheme.onSurface,
            fontWeight: selected
                ? FontWeight.w800
                : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // FILTER CHIPS
  // ==========================================================

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool active = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: active
            ? colorScheme.primary
                .withValues(alpha: 0.12)
            : colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.25),
        borderRadius:
            BorderRadius.circular(13),
        child: InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(13),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(13),
              border: Border.all(
                color: active
                    ? colorScheme.primary
                        .withValues(alpha: 0.35)
                    : colorScheme.outlineVariant
                        .withValues(alpha: 0.28),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: active
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  overflow:
                      TextOverflow.ellipsis,
                  style: theme
                      .textTheme.labelLarge
                      ?.copyWith(
                    color: active
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                    fontWeight: active
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // TRANSACTION CARD
  // ==========================================================

  Widget _buildTransactionCard(
    BuildContext context,
    TransactionModel transaction,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final color = _getTransactionColor(
      context,
      transaction.type,
    );

    final background =
        _getTransactionBackground(
      context,
      transaction.type,
    );

    final isIncome =
        transaction.type == TransactionType.income;

    final isExpense =
        transaction.type == TransactionType.expense;

    final accountName =
        _getAccountName(transaction.accountId);

    final destinationAccountName =
        transaction.toAccountId == null
            ? null
            : _getAccountName(
                transaction.toAccountId!,
              );

    final title =
        _getTransactionTitle(transaction);

    final subtitle =
        transaction.type == TransactionType.transfer
            ? '$accountName → '
                '${destinationAccountName ?? 'Unknown Account'}'
            : accountName;

    final amountPrefix = isIncome
        ? '+'
        : isExpense
            ? '-'
            : '';

    return Container(
      margin:
          const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.34),
        borderRadius:
            BorderRadius.circular(21),
        border: Border.all(
          color: colorScheme.outlineVariant
              .withValues(alpha: 0.18),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _openTransactionDetails(
              transaction,
            );
          },
          borderRadius:
              BorderRadius.circular(21),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              13,
              13,
              12,
              13,
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _getTransactionIcon(
                      transaction,
                    ),
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 13),
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
                            .titleSmall
                            ?.copyWith(
                          fontWeight:
                              FontWeight.w800,
                          letterSpacing: -0.15,
                        ),
                      ),
                      const SizedBox(height: 4),
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
                              .onSurfaceVariant,
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),
                      if (transaction.note
                          .trim()
                          .isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          transaction.note.trim(),
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: theme
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                            color: colorScheme
                                .onSurfaceVariant
                                .withValues(
                                  alpha: 0.75,
                                ),
                            fontSize: 11,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        _formatDateTime(
                          transaction.date,
                        ),
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: theme
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                          color: colorScheme
                              .onSurfaceVariant
                              .withValues(
                                alpha: 0.68,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.end,
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Text(
                      '$amountPrefix₹'
                      '${_formatAmount(transaction.amount)}',
                      maxLines: 1,
                      softWrap: false,
                      style: theme
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                        color: color,
                        fontWeight:
                            FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Material(
                      color: colorScheme
                          .surface
                          .withValues(
                        alpha: 0.45,
                      ),
                      borderRadius:
                          BorderRadius.circular(9),
                      child: InkWell(
                        onTap: () {
                          _deleteTransaction(
                            transaction,
                          );
                        },
                        borderRadius:
                            BorderRadius.circular(9),
                        child: Padding(
                          padding:
                              const EdgeInsets.all(6),
                          child: Icon(
                            Icons
                                .delete_outline_rounded,
                            size: 17,
                            color: colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
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

  // ==========================================================
  // PREMIUM SHEET HELPERS
  // ==========================================================

  Color _sheetSurface(BuildContext context) {
    final theme = Theme.of(context);

    if (theme.brightness ==
        Brightness.dark) {
      return const Color(0xFF15171D);
    }

    return theme.colorScheme.surface;
  }

  Color _sheetTileColor(BuildContext context) {
    final theme = Theme.of(context);

    if (theme.brightness ==
        Brightness.dark) {
      return const Color(0xFF1C1F27);
    }

    return theme
        .colorScheme
        .surfaceContainerHighest
        .withValues(alpha: 0.48);
  }

  Widget _buildPremiumSheet({
    required BuildContext context,
    required String title,
    required String subtitle,
    required List<Widget> children,
    double? maxHeight,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: maxHeight == null
          ? null
          : BoxConstraints(
              maxHeight: maxHeight,
            ),
      decoration: BoxDecoration(
        color: _sheetSurface(context),
        borderRadius:
            const BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            18,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.35),
                    borderRadius:
                        BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                title,
                style: theme
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                  fontWeight:
                      FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: theme
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                  color: colorScheme
                      .onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumOption({
    required BuildContext context,
    required String title,
    String? subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding:
          const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? colorScheme.primary
                .withValues(alpha: 0.10)
            : _sheetTileColor(context),
        borderRadius:
            BorderRadius.circular(17),
        child: InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(17),
          child: Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(17),
              border: Border.all(
                color: selected
                    ? colorScheme.primary
                        .withValues(alpha: 0.30)
                    : colorScheme
                        .outlineVariant
                        .withValues(alpha: 0.16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: selected
                        ? colorScheme.primary
                            .withValues(
                            alpha: 0.14,
                          )
                        : colorScheme.onSurface
                            .withValues(
                            alpha: 0.055,
                          ),
                    borderRadius:
                        BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: selected
                        ? colorScheme.primary
                        : colorScheme
                            .onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 13),
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
                            .titleSmall
                            ?.copyWith(
                          fontWeight:
                              FontWeight.w800,
                          letterSpacing: -0.1,
                        ),
                      ),
                      if (subtitle != null) ...[
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
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                trailing ??
                    AnimatedContainer(
                      duration:
                          const Duration(
                        milliseconds: 150,
                      ),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: selected
                            ? colorScheme.primary
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? colorScheme.primary
                              : colorScheme
                                  .outlineVariant
                                  .withValues(
                                  alpha: 0.55,
                                ),
                          width: 1.5,
                        ),
                      ),
                      child: selected
                          ? const Icon(
                              Icons.check_rounded,
                              size: 17,
                              color: Colors.white,
                            )
                          : null,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // DATE FILTER
  // ==========================================================

  Future<void> _showDateFilterSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _buildPremiumSheet(
          context: sheetContext,
          title: 'Date Filter',
          subtitle:
              'Choose when the transactions occurred',
          children: [
            _buildPremiumOption(
              context: sheetContext,
              title: 'All Dates',
              subtitle:
                  'Show transactions from every date',
              icon:
                  Icons.all_inclusive_rounded,
              selected: _dateFilter ==
                  TransactionDateFilter.all,
              onTap: () {
                Navigator.of(sheetContext).pop();

                setState(() {
                  _dateFilter =
                      TransactionDateFilter.all;
                  _customStartDate = null;
                  _customEndDate = null;
                });
              },
            ),
            _buildPremiumOption(
              context: sheetContext,
              title: 'Today',
              subtitle:
                  'Transactions from today',
              icon: Icons.today_rounded,
              selected: _dateFilter ==
                  TransactionDateFilter.today,
              onTap: () {
                Navigator.of(sheetContext).pop();

                setState(() {
                  _dateFilter =
                      TransactionDateFilter.today;
                  _customStartDate = null;
                  _customEndDate = null;
                });
              },
            ),
            _buildPremiumOption(
              context: sheetContext,
              title: 'This Week',
              subtitle:
                  'Transactions from this week',
              icon: Icons.view_week_rounded,
              selected: _dateFilter ==
                  TransactionDateFilter.thisWeek,
              onTap: () {
                Navigator.of(sheetContext).pop();

                setState(() {
                  _dateFilter =
                      TransactionDateFilter.thisWeek;
                  _customStartDate = null;
                  _customEndDate = null;
                });
              },
            ),
            _buildPremiumOption(
              context: sheetContext,
              title: 'This Month',
              subtitle:
                  'Transactions from this month',
              icon:
                  Icons.calendar_month_rounded,
              selected: _dateFilter ==
                  TransactionDateFilter.thisMonth,
              onTap: () {
                Navigator.of(sheetContext).pop();

                setState(() {
                  _dateFilter =
                      TransactionDateFilter.thisMonth;
                  _customStartDate = null;
                  _customEndDate = null;
                });
              },
            ),
            _buildPremiumOption(
              context: sheetContext,
              title: 'Custom Date Range',
              subtitle:
                  _dateFilter ==
                              TransactionDateFilter.custom &&
                          _customStartDate != null &&
                          _customEndDate != null
                      ? '${_formatShortDate(_customStartDate!)}'
                          ' → '
                          '${_formatShortDate(_customEndDate!)}'
                      : 'Choose a specific date range',
              icon: Icons.date_range_rounded,
              selected: _dateFilter ==
                  TransactionDateFilter.custom,
              onTap: () async {
                Navigator.of(sheetContext).pop();

                await _selectCustomDateRange();
              },
            ),
          ],
        );
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
      lastDate:
          DateTime(now.year + 10),
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
    final result =
        await showDialog<Map<String, double?>>(
      context: context,
      barrierColor:
          Colors.black.withValues(alpha: 0.65),
      builder: (dialogContext) {
        final theme =
            Theme.of(dialogContext);
        final colorScheme =
            theme.colorScheme;

        return Dialog(
          backgroundColor:
              Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(
            horizontal: 20,
          ),
          child: Container(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              16,
            ),
            decoration: BoxDecoration(
              color:
                  _sheetSurface(dialogContext),
              borderRadius:
                  BorderRadius.circular(28),
              border: Border.all(
                color: colorScheme
                    .outlineVariant
                    .withValues(alpha: 0.16),
              ),
            ),
            child: StatefulBuilder(
              builder: (
                dialogContext,
                setDialogState,
              ) {
                return Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration:
                              BoxDecoration(
                            color: colorScheme
                                .primary
                                .withValues(
                              alpha: 0.12,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(14),
                          ),
                          child: Icon(
                            Icons
                                .currency_rupee_rounded,
                            color: colorScheme
                                .primary,
                          ),
                        ),
                        const SizedBox(
                          width: 13,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                'Amount Filter',
                                style: theme
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                  fontWeight:
                                      FontWeight.w900,
                                  letterSpacing:
                                      -0.3,
                                ),
                              ),
                              const SizedBox(
                                height: 3,
                              ),
                              Text(
                                'Set a minimum or maximum amount',
                                style: theme
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                  color: colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 22,
                    ),
                    TextFormField(
                      initialValue:
                          _minimumAmount
                              ?.toStringAsFixed(2) ??
                              '',
                      keyboardType:
                          const TextInputType
                              .numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (value) {
                        setDialogState(() {});
                      },
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Minimum amount',
                        hintText:
                            'Example: 500',
                        prefixText: '₹ ',
                        prefixIcon:
                            Icon(
                          Icons
                              .south_west_rounded,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 13,
                    ),
                    TextFormField(
                      initialValue:
                          _maximumAmount
                              ?.toStringAsFixed(2) ??
                              '',
                      keyboardType:
                          const TextInputType
                              .numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (value) {
                        setDialogState(() {});
                      },
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Maximum amount',
                        hintText:
                            'Example: 5000',
                        prefixText: '₹ ',
                        prefixIcon:
                            Icon(
                          Icons
                              .north_east_rounded,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child:
                              OutlinedButton(
                            onPressed: () {
                              Navigator.of(
                                dialogContext,
                              ).pop(
                                <String,
                                    double?>{
                                  'minimum':
                                      null,
                                  'maximum':
                                      null,
                                },
                              );
                            },
                            child:
                                const Text(
                              'Clear',
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child:
                              FilledButton(
                            onPressed: () {
                              // Read current values
                              // directly from the
                              // form fields.
                              final minimumText =
                                  _minimumAmount
                                          ?.toStringAsFixed(
                                        2,
                                      ) ??
                                      '';

                              final maximumText =
                                  _maximumAmount
                                          ?.toStringAsFixed(
                                        2,
                                      ) ??
                                      '';

                              Navigator.of(
                                dialogContext,
                              ).pop(
                                <String,
                                    double?>{
                                  'minimum':
                                      double.tryParse(
                                    minimumText,
                                  ),
                                  'maximum':
                                      double.tryParse(
                                    maximumText,
                                  ),
                                },
                              );
                            },
                            child:
                                const Text(
                              'Apply',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _minimumAmount =
          result['minimum'];
      _maximumAmount =
          result['maximum'];
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
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent,
      builder: (sheetContext) {
        return _buildPremiumSheet(
          context: sheetContext,
          title: 'Account Filter',
          subtitle:
              'Filter transactions by account',
          maxHeight:
              MediaQuery.of(sheetContext)
                      .size
                      .height *
                  0.78,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildPremiumOption(
                      context: sheetContext,
                      title: 'All Accounts',
                      subtitle:
                          'Show every account',
                      icon: Icons
                          .account_balance_rounded,
                      selected:
                          _selectedAccountId ==
                              null,
                      onTap: () {
                        Navigator.of(
                          sheetContext,
                        ).pop();

                        setState(() {
                          _selectedAccountId =
                              null;
                        });
                      },
                    ),
                    if (accounts.isEmpty)
                      Padding(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          vertical: 24,
                        ),
                        child: Center(
                          child: Text(
                            'No accounts available.',
                            style: Theme.of(
                              sheetContext,
                            )
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                              color: Theme.of(
                                sheetContext,
                              )
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ...accounts.map(
                      (account) {
                        final selected =
                            _selectedAccountId ==
                                account.id;

                        return _buildPremiumOption(
                          context:
                              sheetContext,
                          title:
                              account.name,
                          subtitle:
                              account.bankName,
                          icon: Icons
                              .account_balance_rounded,
                          selected:
                              selected,
                          trailing: selected
                              ? const Icon(
                                  Icons
                                      .check_circle_rounded,
                                  color:
                                      Color(
                                    0xFF8B8CF6,
                                  ),
                                )
                              : account
                                          .lastFourDigits ==
                                      null
                                  ? null
                                  : Text(
                                      '•••• '
                                      '${account.lastFourDigits}',
                                      style:
                                          Theme.of(
                                        sheetContext,
                                      )
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                            color: Theme.of(
                                              sheetContext,
                                            )
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
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
            ),
          ],
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
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent,
      builder: (sheetContext) {
        return _buildPremiumSheet(
          context: sheetContext,
          title: 'Sort Transactions',
          subtitle:
              'Choose how your history is ordered',
          children: [
            _buildPremiumOption(
              context: sheetContext,
              title: 'Newest First',
              subtitle:
                  'Latest transactions first',
              icon:
                  Icons.arrow_downward_rounded,
              selected: _sortOption ==
                  TransactionSortOption
                      .newestFirst,
              onTap: () {
                Navigator.of(
                  sheetContext,
                ).pop();

                setState(() {
                  _sortOption =
                      TransactionSortOption
                          .newestFirst;
                });
              },
            ),
            _buildPremiumOption(
              context: sheetContext,
              title: 'Oldest First',
              subtitle:
                  'Earliest transactions first',
              icon:
                  Icons.arrow_upward_rounded,
              selected: _sortOption ==
                  TransactionSortOption
                      .oldestFirst,
              onTap: () {
                Navigator.of(
                  sheetContext,
                ).pop();

                setState(() {
                  _sortOption =
                      TransactionSortOption
                          .oldestFirst;
                });
              },
            ),
            _buildPremiumOption(
              context: sheetContext,
              title: 'Highest Amount',
              subtitle:
                  'Largest transactions first',
              icon:
                  Icons.trending_up_rounded,
              selected: _sortOption ==
                  TransactionSortOption
                      .highestAmount,
              onTap: () {
                Navigator.of(
                  sheetContext,
                ).pop();

                setState(() {
                  _sortOption =
                      TransactionSortOption
                          .highestAmount;
                });
              },
            ),
            _buildPremiumOption(
              context: sheetContext,
              title: 'Lowest Amount',
              subtitle:
                  'Smallest transactions first',
              icon:
                  Icons.trending_down_rounded,
              selected: _sortOption ==
                  TransactionSortOption
                      .lowestAmount,
              onTap: () {
                Navigator.of(
                  sheetContext,
                ).pop();

                setState(() {
                  _sortOption =
                      TransactionSortOption
                          .lowestAmount;
                });
              },
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // CLEAR FILTERS
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
  // DETAILS
  // ==========================================================

  Future<void> _openTransactionDetails(
    TransactionModel transaction,
  ) async {
    final changed =
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

    if (changed == true) {
      setState(() {});
    }
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
              child:
                  const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child:
                  const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!mounted ||
        confirmed != true) {
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

    ScaffoldMessenger.of(context)
        .showSnackBar(
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final hasFilters =
        _hasActiveFilters ||
            _searchQuery.isNotEmpty;

    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration:
                  BoxDecoration(
                color: colorScheme
                    .surfaceContainerHighest
                    .withValues(
                  alpha: 0.45,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme
                      .outlineVariant
                      .withValues(
                    alpha: 0.2,
                  ),
                ),
              ),
              child: Icon(
                hasFilters
                    ? Icons
                        .search_off_rounded
                    : Icons
                        .receipt_long_rounded,
                size: 36,
                color: colorScheme
                    .onSurfaceVariant,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Text(
              hasFilters
                  ? 'No matching transactions'
                  : 'No transactions yet',
              textAlign:
                  TextAlign.center,
              style: theme
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                fontWeight:
                    FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              hasFilters
                  ? 'Try changing or clearing your filters.'
                  : 'Your transactions will appear here.',
              textAlign:
                  TextAlign.center,
              style: theme
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                color: colorScheme
                    .onSurfaceVariant,
              ),
            ),
            if (hasFilters) ...[
              const SizedBox(
                height: 20,
              ),
              FilledButton.tonalIcon(
                onPressed:
                    _clearFilters,
                icon: const Icon(
                  Icons
                      .filter_alt_off_rounded,
                ),
                label: const Text(
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final transactions =
        _filteredTransactions;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transactions',
          style: TextStyle(
            fontWeight:
                FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          IconButton(
            tooltip:
                'Sort transactions',
            onPressed:
                _showSortSheet,
            icon: const Icon(
              Icons
                  .swap_vert_rounded,
            ),
          ),
          if (_hasActiveFilters ||
              _searchQuery.isNotEmpty)
            IconButton(
              tooltip:
                  'Clear filters',
              onPressed:
                  _clearFilters,
              icon: const Icon(
                Icons
                    .filter_alt_off_rounded,
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // SEARCH
          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              6,
              16,
              10,
            ),
            child: TextField(
              controller:
                  _searchController,
              decoration:
                  InputDecoration(
                hintText:
                    'Search transactions...',
                prefixIcon:
                    const Icon(
                  Icons.search_rounded,
                ),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController
                                  .clear();
                            },
                            icon:
                                const Icon(
                              Icons
                                  .close_rounded,
                            ),
                          )
                        : null,
              ),
            ),
          ),

          // TYPE FILTERS
          SizedBox(
            height: 43,
            child: ListView(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 16,
              ),
              scrollDirection:
                  Axis.horizontal,
              children: [
                _buildTypeChip(
                  context: context,
                  label: 'All',
                  type: null,
                ),
                const SizedBox(
                  width: 8,
                ),
                _buildTypeChip(
                  context: context,
                  label: 'Income',
                  type:
                      TransactionType
                          .income,
                ),
                const SizedBox(
                  width: 8,
                ),
                _buildTypeChip(
                  context: context,
                  label: 'Expense',
                  type:
                      TransactionType
                          .expense,
                ),
                const SizedBox(
                  width: 8,
                ),
                _buildTypeChip(
                  context: context,
                  label: 'Transfer',
                  type:
                      TransactionType
                          .transfer,
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 9,
          ),

          // FILTERS
          SizedBox(
            height: 43,
            child: ListView(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 16,
              ),
              scrollDirection:
                  Axis.horizontal,
              children: [
                _buildFilterChip(
                  context: context,
                  label:
                      _accountFilterLabel,
                  icon: Icons
                      .account_balance_rounded,
                  active:
                      _selectedAccountId !=
                          null,
                  onTap:
                      _showAccountFilterSheet,
                ),
                _buildFilterChip(
                  context: context,
                  label:
                      _dateFilterLabel,
                  icon: Icons
                      .calendar_month_rounded,
                  active:
                      _dateFilter !=
                          TransactionDateFilter
                              .all,
                  onTap:
                      _showDateFilterSheet,
                ),
                _buildFilterChip(
                  context: context,
                  label:
                      _amountFilterLabel,
                  icon: Icons
                      .currency_rupee_rounded,
                  active:
                      _minimumAmount !=
                              null ||
                          _maximumAmount !=
                              null,
                  onTap:
                      _showAmountFilterDialog,
                ),
                _buildFilterChip(
                  context: context,
                  label: _sortLabel,
                  icon:
                      Icons.sort_rounded,
                  active:
                      _sortOption !=
                          TransactionSortOption
                              .newestFirst,
                  onTap:
                      _showSortSheet,
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          // COUNT
          if (transactions.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                17,
                3,
                17,
                7,
              ),
              child: Row(
                children: [
                  Text(
                    '${transactions.length} '
                    '${transactions.length == 1 ? 'transaction' : 'transactions'}',
                    style: theme
                        .textTheme
                        .labelMedium
                        ?.copyWith(
                      color: colorScheme
                          .onSurfaceVariant,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _sortLabel,
                    style: theme
                        .textTheme
                        .labelMedium
                        ?.copyWith(
                      color: colorScheme
                          .onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

          // TRANSACTIONS
          Expanded(
            child: transactions.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    physics:
                        const BouncingScrollPhysics(),
                    padding:
                        const EdgeInsets
                            .fromLTRB(
                      16,
                      5,
                      16,
                      28,
                    ),
                    itemCount:
                        transactions.length,
                    itemBuilder:
                        (context, index) {
                      return _buildTransactionCard(
                        context,
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