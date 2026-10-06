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
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  void _changeType(TransactionType type) {
    setState(() {
      _type = type;
      _selectedCategoryId = null;
      _selectedToAccountId = null;

      if (type == TransactionType.expense) {
        _selectedCategoryId = expenseCategories.first.id;
      }

      if (type == TransactionType.income) {
        _selectedCategoryId = incomeSources.first.id;
      }

      if (_accounts.isNotEmpty &&
          _selectedAccountId == null) {
        _selectedAccountId = _accounts.first.id;
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
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
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
      toAccountId: _type == TransactionType.transfer
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
        content: Text(message),
      ),
    );
  }

  Widget _buildTypeSelector(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
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

    return GestureDetector(
      onTap: () => _changeType(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 6,
        ),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurface
                      .withValues(alpha: 0.65),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface
                        .withValues(alpha: 0.7),
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountField(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer
            .withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Amount',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _amountController,
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              hintText: '0.00',
              prefixText: '₹ ',
              prefixStyle:
                  theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
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
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildAccountSelector(BuildContext context) {
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
          Icons.account_balance_rounded,
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

  Widget _buildCategorySelector(BuildContext context) {
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
                style: const TextStyle(
                  fontSize: 18,
                ),
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

  Widget _buildDateTimeCard(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildDateTimeButton(
            context,
            icon: Icons.calendar_today_rounded,
            title: 'Date',
            value: _formatDate(_selectedDate),
            onTap: _pickDate,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildDateTimeButton(
            context,
            icon: Icons.access_time_rounded,
            title: 'Time',
            value: _formatTime(_selectedDate),
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
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 21,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                        theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
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

  Widget _buildTransferInfo(BuildContext context) {
    if (_type != TransactionType.transfer ||
        _selectedAccountId == null ||
        _selectedToAccountId == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer
            .withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            Icons.swap_horiz_rounded,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${_accountName(_selectedAccountId!)} → '
              '${_accountName(_selectedToAccountId!)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
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
    final colorScheme = theme.colorScheme;

    final hasAccounts = _accounts.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Transaction',
          style: TextStyle(
            fontWeight: FontWeight.w700,
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

              const SizedBox(height: 20),

              _buildAmountField(context),

              const SizedBox(height: 24),

              _buildSectionTitle(
                context,
                'Account',
              ),

              if (!hasAccounts)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No accounts available. '
                          'Please add an account first.',
                          style:
                              theme.textTheme.bodyMedium?.copyWith(
                            color:
                                colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                _buildAccountSelector(context),

              if (_type == TransactionType.transfer) ...[
                const SizedBox(height: 18),

                _buildSectionTitle(
                  context,
                  'Destination Account',
                ),

                _buildDestinationSelector(context),

                const SizedBox(height: 14),

                _buildTransferInfo(context),
              ],

              if (_type != TransactionType.transfer) ...[
                const SizedBox(height: 20),

                _buildSectionTitle(
                  context,
                  _type == TransactionType.income
                      ? 'Income Source'
                      : 'Category',
                ),

                _buildCategorySelector(context),
              ],

              const SizedBox(height: 24),

              _buildSectionTitle(
                context,
                'Date & Time',
              ),

              _buildDateTimeCard(context),

              const SizedBox(height: 24),

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
                decoration: const InputDecoration(
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

              SizedBox(
                height: 56,
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed:
                      hasAccounts
                          ? _saveTransaction
                          : null,
                  icon: const Icon(
                    Icons.check_rounded,
                  ),
                  label: Text(
                    _type == TransactionType.transfer
                        ? 'Save Transfer'
                        : _type ==
                                TransactionType.income
                            ? 'Save Income'
                            : 'Save Expense',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}