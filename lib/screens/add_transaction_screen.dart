import 'package:flutter/material.dart';

import '../data/categories.dart';
import '../data/income_sources.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';

class AddTransactionScreen extends StatefulWidget {
  final DatabaseService databaseService;

  const AddTransactionScreen({
    super.key,
    required this.databaseService,
  });

  @override
  State<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState
    extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  TransactionType _type = TransactionType.expense;

  String? _selectedAccountId;
  String? _selectedToAccountId;
  String? _selectedCategoryId;

  DateTime _selectedDate = DateTime.now();

  static const Color _expenseColor = Color(0xFFE5484D);
  static const Color _incomeColor = Color(0xFF16A34A);
  static const Color _transferColor = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();

    final accounts = widget.databaseService.accounts;

    if (accounts.isNotEmpty) {
      _selectedAccountId = accounts.first.id;
    }

    _selectedCategoryId = expenseCategories.first.id;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  List<Account> get _accounts =>
      widget.databaseService.accounts;

  List<ExpenseCategory> get _currentCategories {
    if (_type == TransactionType.income) {
      return incomeSources;
    }

    return expenseCategories;
  }

  Color _typeColor() {
    switch (_type) {
      case TransactionType.expense:
        return _expenseColor;

      case TransactionType.income:
        return _incomeColor;

      case TransactionType.transfer:
        return _transferColor;
    }
  }

  String _formatDate(DateTime date) {
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

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0
        ? 12
        : date.hour % 12;

    final minute = date.minute
        .toString()
        .padLeft(2, '0');

    final period = date.hour >= 12
        ? 'PM'
        : 'AM';

    return '$hour:$minute $period';
  }

  void _changeType(TransactionType type) {
    setState(() {
      _type = type;
      _selectedCategoryId = null;
      _selectedToAccountId = null;

      if (type == TransactionType.expense) {
        _selectedCategoryId =
            expenseCategories.first.id;
      }

      if (type == TransactionType.income) {
        _selectedCategoryId =
            incomeSources.first.id;
      }

      if (_accounts.isNotEmpty &&
          _selectedAccountId == null) {
        _selectedAccountId =
            _accounts.first.id;
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _selectedDate.hour,
        _selectedDate.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay.fromDateTime(_selectedDate),
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  String _accountName(String id) {
    final account =
        widget.databaseService.getAccount(id);

    return account?.name ?? 'Unknown account';
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount =
        double.tryParse(_amountController.text.trim());

    if (amount == null || amount <= 0) {
      return;
    }

    if (_accounts.isEmpty) {
      _showMessage(
        'Please add an account first.',
      );
      return;
    }

    if (_selectedAccountId == null) {
      _showMessage(
        'Please select an account.',
      );
      return;
    }

    if (_type == TransactionType.transfer) {
      if (_selectedToAccountId == null) {
        _showMessage(
          'Please select a destination account.',
        );
        return;
      }

      if (_selectedAccountId ==
          _selectedToAccountId) {
        _showMessage(
          'Source and destination accounts must be different.',
        );
        return;
      }
    }

    if (_type != TransactionType.transfer &&
        _selectedCategoryId == null) {
      _showMessage(
        'Please select a category.',
      );
      return;
    }

    final transaction = TransactionModel(
      id: DateTime.now()
          .microsecondsSinceEpoch
          .toString(),
      type: _type,
      amount: amount,
      categoryId:
          _selectedCategoryId ?? 'transfer',
      accountId: _selectedAccountId!,
      toAccountId:
          _type == TransactionType.transfer
              ? _selectedToAccountId
              : null,
      note: _noteController.text.trim(),
      date: _selectedDate,
    );

    await widget.databaseService
        .addTransaction(transaction);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(true);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(message),
      ),
    );
  }

  String _saveButtonText() {
    switch (_type) {
      case TransactionType.income:
        return 'Save Income';

      case TransactionType.expense:
        return 'Save Expense';

      case TransactionType.transfer:
        return 'Save Transfer';
    }
  }

  Widget _buildTypeSelector(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant
              .withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeButton(
              context,
              type: TransactionType.expense,
              label: 'Expense',
              icon: Icons.arrow_upward_rounded,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildTypeButton(
              context,
              type: TransactionType.income,
              label: 'Income',
              icon: Icons.arrow_downward_rounded,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildTypeButton(
              context,
              type: TransactionType.transfer,
              label: 'Transfer',
              icon: Icons.swap_horiz_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(
    BuildContext context, {
    required TransactionType type,
    required String label,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final selected = _type == type;

    Color selectedColor;

    switch (type) {
      case TransactionType.expense:
        selectedColor = _expenseColor;
        break;

      case TransactionType.income:
        selectedColor = _incomeColor;
        break;

      case TransactionType.transfer:
        selectedColor = _transferColor;
        break;
    }

    return GestureDetector(
      onTap: () => _changeType(type),
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          vertical: 13,
          horizontal: 6,
        ),
        decoration: BoxDecoration(
          color: selected
              ? selectedColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected
                  ? Colors.white
                  : colorScheme.onSurface
                      .withValues(alpha: 0.58),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style:
                  theme.textTheme.labelMedium?.copyWith(
                color: selected
                    ? Colors.white
                    : colorScheme.onSurface
                        .withValues(alpha: 0.70),
                fontWeight: selected
                    ? FontWeight.w800
                    : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountField(BuildContext context) {
    final theme = Theme.of(context);
    final color = _typeColor();

    return AnimatedContainer(
      duration:
          const Duration(milliseconds: 180),
      padding: const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        16,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: color.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.currency_rupee_rounded,
                size: 17,
                color: color,
              ),
              const SizedBox(width: 7),
              Text(
                'Amount',
                style:
                    theme.textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _amountController,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
            style:
                theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
            decoration: InputDecoration(
              hintText: '0.00',
              prefixText: '₹ ',
              prefixStyle:
                  theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
                color: color,
              ),
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'Enter an amount';
              }

              final amount =
                  double.tryParse(value.trim());

              if (amount == null) {
                return 'Enter a valid amount';
              }

              if (amount <= 0) {
                return 'Amount must be greater than zero';
              }

              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Text(
        title,
        style:
            theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.1,
        ),
      ),
    );
  }

  Widget _buildAccountSelector(
    BuildContext context,
  ) {
    final accounts = _accounts;

    return DropdownButtonFormField<String>(
      initialValue: _selectedAccountId,
      decoration: const InputDecoration(
        prefixIcon: Icon(
          Icons.account_balance_wallet_outlined,
        ),
        hintText: 'Select account',
      ),
      items: accounts.map((account) {
        return DropdownMenuItem<String>(
          value: account.id,
          child: Text(
            account.name,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedAccountId = value;
          _selectedToAccountId = null;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Select an account';
        }

        return null;
      },
    );
  }

  Widget _buildDestinationSelector(
    BuildContext context,
  ) {
    final destinationAccounts = _accounts
        .where(
          (account) =>
              account.id != _selectedAccountId,
        )
        .toList();

    return DropdownButtonFormField<String>(
      initialValue: _selectedToAccountId,
      decoration: const InputDecoration(
        prefixIcon: Icon(
          Icons.account_balance_outlined,
        ),
        hintText: 'Select destination account',
      ),
      items: destinationAccounts.map((account) {
        return DropdownMenuItem<String>(
          value: account.id,
          child: Text(
            account.name,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedToAccountId = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Select destination account';
        }

        return null;
      },
    );
  }

  Widget _buildCategorySelector(
    BuildContext context,
  ) {
    final categories = _currentCategories;

    return DropdownButtonFormField<String>(
      initialValue: _selectedCategoryId,
      decoration: InputDecoration(
        prefixIcon: Icon(
          _type == TransactionType.income
              ? Icons.payments_outlined
              : Icons.category_outlined,
        ),
        hintText: _type == TransactionType.income
            ? 'Select income source'
            : 'Select category',
      ),
      items: categories.map((category) {
        return DropdownMenuItem<String>(
          value: category.id,
          child: Row(
            children: [
              Text(
                category.icon,
                style:
                    const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 10),
              Text(category.name),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategoryId = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return _type == TransactionType.income
              ? 'Select an income source'
              : 'Select a category';
        }

        return null;
      },
    );
  }

  Widget _buildDateTimeCard(
    BuildContext context,
  ) {
    final color = _typeColor();

    return Row(
      children: [
        Expanded(
          child: _buildDateTimeButton(
            context,
            icon: Icons.calendar_today_rounded,
            title: 'Date',
            value: _formatDate(_selectedDate),
            color: color,
            onTap: _pickDate,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildDateTimeButton(
            context,
            icon: Icons.access_time_rounded,
            title: 'Time',
            value: _formatTime(_selectedDate),
            color: color,
            onTap: _pickTime,
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest
          .withValues(alpha: 0.30),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: color.withValues(alpha: 0.11),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color:
                      color.withValues(alpha: 0.09),
                  borderRadius:
                      BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  size: 18,
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
                      style: theme
                          .textTheme.labelSmall
                          ?.copyWith(
                        color: colorScheme.onSurface
                            .withValues(alpha: 0.52),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: theme
                          .textTheme.bodySmall
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
      ),
    );
  }

  Widget _buildTransferInfo(
    BuildContext context,
  ) {
    if (_type != TransactionType.transfer ||
        _selectedAccountId == null ||
        _selectedToAccountId == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color:
            _transferColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              _transferColor.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _transferColor.withValues(
                alpha: 0.10,
              ),
              borderRadius:
                  BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.swap_horiz_rounded,
              color: _transferColor,
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
                  'Transfer route',
                  style: theme
                      .textTheme.labelSmall
                      ?.copyWith(
                    color: theme
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.50),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_accountName(_selectedAccountId!)} → '
                  '${_accountName(_selectedToAccountId!)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme
                      .textTheme.bodySmall
                      ?.copyWith(
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

  Widget _buildSaveButton(
    BuildContext context,
  ) {
    final color = _typeColor();

    return SizedBox(
      height: 56,
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              color.withValues(alpha: 0.35),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(18),
          ),
        ),
        onPressed:
            _accounts.isNotEmpty
                ? _saveTransaction
                : null,
        icon: const Icon(
          Icons.check_rounded,
        ),
        label: Text(
          _saveButtonText(),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final hasAccounts = _accounts.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Transaction',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              120,
            ),
            children: [
              _buildTypeSelector(context),

              const SizedBox(height: 18),

              _buildAmountField(context),

              const SizedBox(height: 25),

              _buildSectionTitle(
                context,
                'Account',
              ),

              if (!hasAccounts)
                Container(
                  padding:
                      const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color:
                        colorScheme.errorContainer,
                    borderRadius:
                        BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons
                            .warning_amber_rounded,
                        color: colorScheme
                            .onErrorContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No accounts available. '
                          'Please add an account first.',
                          style: theme
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                            color: colorScheme
                                .onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                _buildAccountSelector(context),

              if (_type ==
                  TransactionType.transfer) ...[
                const SizedBox(height: 20),

                _buildSectionTitle(
                  context,
                  'Destination Account',
                ),

                _buildDestinationSelector(
                  context,
                ),

                const SizedBox(height: 13),

                _buildTransferInfo(context),
              ],

              if (_type !=
                  TransactionType.transfer) ...[
                const SizedBox(height: 20),

                _buildSectionTitle(
                  context,
                  _type ==
                          TransactionType.income
                      ? 'Income Source'
                      : 'Category',
                ),

                _buildCategorySelector(
                  context,
                ),
              ],

              const SizedBox(height: 25),

              _buildSectionTitle(
                context,
                'Date & Time',
              ),

              _buildDateTimeCard(context),

              const SizedBox(height: 25),

              _buildSectionTitle(
                context,
                'Note',
              ),

              TextFormField(
                controller: _noteController,
                minLines: 2,
                maxLines: 4,
                textCapitalization:
                    TextCapitalization.sentences,
                decoration:
                    const InputDecoration(
                  hintText:
                      'Add a note (optional)',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(
                      bottom: 30,
                    ),
                    child: Icon(
                      Icons.notes_rounded,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              _buildSaveButton(context),
            ],
          ),
        ),
      ),
    );
  }
}