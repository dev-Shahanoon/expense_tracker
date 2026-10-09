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

class _AddTransactionScreenState extends State<AddTransactionScreen> {
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
  static const Color _cardPaymentColor = Color(0xFF0D9488);

  @override
  void initState() {
    super.initState();
    final accounts = widget.databaseService.accounts;

    if (accounts.isNotEmpty) {
      _selectedAccountId = accounts.first.id;
    }

    if (expenseCategories.isNotEmpty) {
      _selectedCategoryId = expenseCategories.first.id;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  List<Account> get _accounts => widget.databaseService.accounts;

  List<Account> get _sourceAccounts {
    if (_type == TransactionType.cardPayment) {
      return _accounts.where((account) => !account.isCreditCard).toList();
    }
    return _accounts;
  }

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
      case TransactionType.cardPayment:
        return _cardPaymentColor;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
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

      final sources = type == TransactionType.cardPayment
          ? _accounts.where((account) => !account.isCreditCard).toList()
          : _accounts;

      if (sources.isNotEmpty &&
          !sources.any((account) => account.id == _selectedAccountId)) {
        _selectedAccountId = sources.first.id;
      } else if (sources.isEmpty) {
        _selectedAccountId = null;
      }

      if (type == TransactionType.expense && expenseCategories.isNotEmpty) {
        _selectedCategoryId = expenseCategories.first.id;
      } else if (type == TransactionType.income && incomeSources.isNotEmpty) {
        _selectedCategoryId = incomeSources.first.id;
      }

      if (type == TransactionType.cardPayment) {
        final cards = _accounts.where((account) => account.isCreditCard);
        if (cards.isNotEmpty) {
          _selectedToAccountId = cards.first.id;
        }
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

    if (picked == null || !mounted) return;

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

    if (picked == null || !mounted) return;

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
    return widget.databaseService.getAccount(id)?.name ?? 'Unknown account';
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;

    if (_accounts.isEmpty) {
      _showMessage('Please add an account first.');
      return;
    }

    if (_selectedAccountId == null ||
        !_sourceAccounts.any((account) => account.id == _selectedAccountId)) {
      _showMessage(
        _type == TransactionType.cardPayment
            ? 'Please select a bank or cash account.'
            : 'Please select an account.',
      );
      return;
    }

    final needsDestination = _type == TransactionType.transfer ||
        _type == TransactionType.cardPayment;

    if (needsDestination) {
      if (_selectedToAccountId == null) {
        _showMessage(
          _type == TransactionType.cardPayment
              ? 'Please select a credit card.'
              : 'Please select a destination account.',
        );
        return;
      }

      if (_selectedAccountId == _selectedToAccountId) {
        _showMessage('Source and destination accounts must be different.');
        return;
      }

      if (_type == TransactionType.cardPayment) {
        final destination =
            widget.databaseService.getAccount(_selectedToAccountId!);
        if (destination == null || !destination.isCreditCard) {
          _showMessage('Please select a valid credit card.');
          return;
        }
      }
    }

    if (!needsDestination && _selectedCategoryId == null) {
      _showMessage('Please select a category.');
      return;
    }

    final transaction = TransactionModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: _type,
      amount: amount,
      categoryId: _type == TransactionType.transfer
          ? 'transfer'
          : _type == TransactionType.cardPayment
              ? 'card_payment'
              : _selectedCategoryId!,
      accountId: _selectedAccountId!,
      toAccountId: needsDestination ? _selectedToAccountId : null,
      note: _noteController.text.trim(),
      date: _selectedDate,
    );

    await widget.databaseService.addTransaction(transaction);

    if (!mounted) return;
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
      case TransactionType.cardPayment:
        return 'Pay Credit Card';
    }
  }

  Widget _buildTypeSelector(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.22),
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
          const SizedBox(width: 4),
          Expanded(
            child: _buildTypeButton(
              context,
              type: TransactionType.cardPayment,
              label: 'Card Pay',
              icon: Icons.credit_card_rounded,
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

    final Color selectedColor;
    switch (type) {
      case TransactionType.expense:
        selectedColor = _expenseColor;
      case TransactionType.income:
        selectedColor = _incomeColor;
      case TransactionType.transfer:
        selectedColor = _transferColor;
      case TransactionType.cardPayment:
        selectedColor = _cardPaymentColor;
    }

    return GestureDetector(
      onTap: () => _changeType(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 3),
        decoration: BoxDecoration(
          color: selected ? selectedColor : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected
                  ? Colors.white
                  : colorScheme.onSurface.withValues(alpha: 0.58),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: selected
                    ? Colors.white
                    : colorScheme.onSurface.withValues(alpha: 0.70),
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
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
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.currency_rupee_rounded, size: 17, color: color),
              const SizedBox(width: 7),
              Text(
                'Amount',
                style: theme.textTheme.labelLarge?.copyWith(
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
            decoration: InputDecoration(
              hintText: '0.00',
              prefixText: '₹ ',
              prefixStyle: theme.textTheme.headlineLarge?.copyWith(
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
              if (value == null || value.trim().isEmpty) {
                return 'Enter an amount';
              }
              final amount = double.tryParse(value.trim());
              if (amount == null) return 'Enter a valid amount';
              if (amount <= 0) return 'Amount must be greater than zero';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.1,
        ),
      ),
    );
  }

  Widget _buildAccountSelector(BuildContext context) {
    final accounts = _sourceAccounts;

    return DropdownButtonFormField<String>(
      initialValue: accounts.any((account) => account.id == _selectedAccountId)
          ? _selectedAccountId
          : null,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.account_balance_wallet_outlined),
        hintText: 'Select account',
      ),
      items: accounts.map((account) {
        return DropdownMenuItem<String>(
          value: account.id,
          child: Text(account.name, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedAccountId = value;
          _selectedToAccountId = null;
          if (_type == TransactionType.cardPayment) {
            final cards = _accounts.where((account) => account.isCreditCard);
            if (cards.isNotEmpty) _selectedToAccountId = cards.first.id;
          }
        });
      },
      validator: (value) {
        if (value == null) return 'Select an account';
        return null;
      },
    );
  }

  Widget _buildDestinationSelector(BuildContext context) {
    final destinationAccounts = _accounts.where((account) {
      if (account.id == _selectedAccountId) return false;
      if (_type == TransactionType.cardPayment) return account.isCreditCard;
      return true;
    }).toList();

    return DropdownButtonFormField<String>(
      initialValue: destinationAccounts
              .any((account) => account.id == _selectedToAccountId)
          ? _selectedToAccountId
          : null,
      decoration: InputDecoration(
        prefixIcon: Icon(
          _type == TransactionType.cardPayment
              ? Icons.credit_card_rounded
              : Icons.account_balance_outlined,
        ),
        hintText: _type == TransactionType.cardPayment
            ? 'Select credit card'
            : 'Select destination account',
      ),
      items: destinationAccounts.map((account) {
        return DropdownMenuItem<String>(
          value: account.id,
          child: Text(account.name, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedToAccountId = value);
      },
      validator: (value) {
        if (value == null) {
          return _type == TransactionType.cardPayment
              ? 'Select a credit card'
              : 'Select destination account';
        }
        return null;
      },
    );
  }

  Widget _buildCategorySelector(BuildContext context) {
    final categories = _currentCategories;

    return DropdownButtonFormField<String>(
      initialValue: categories.any((item) => item.id == _selectedCategoryId)
          ? _selectedCategoryId
          : null,
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
              Text(category.icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Text(category.name),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedCategoryId = value),
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
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.30),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.11)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.52),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w800,
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

  Widget _buildTransferInfo(BuildContext context) {
    final needsDestination = _type == TransactionType.transfer ||
        _type == TransactionType.cardPayment;

    if (!needsDestination ||
        _selectedAccountId == null ||
        _selectedToAccountId == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final color = _typeColor();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              _type == TransactionType.cardPayment
                  ? Icons.credit_card_rounded
                  : Icons.swap_horiz_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _type == TransactionType.cardPayment
                      ? 'Card payment route'
                      : 'Transfer route',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.50),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_accountName(_selectedAccountId!)} → '
                  '${_accountName(_selectedToAccountId!)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
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

  Widget _buildSaveButton(BuildContext context) {
    final color = _typeColor();

    return SizedBox(
      height: 56,
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withValues(alpha: 0.35),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: _accounts.isNotEmpty ? _saveTransaction : null,
        icon: const Icon(Icons.check_rounded),
        label: Text(
          _saveButtonText(),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasAccounts = _accounts.isNotEmpty;
    final needsDestination = _type == TransactionType.transfer ||
        _type == TransactionType.cardPayment;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Transaction',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.2),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              _buildTypeSelector(context),
              const SizedBox(height: 18),
              _buildAmountField(context),
              const SizedBox(height: 25),
              _buildSectionTitle(context, 'Account'),
              if (!hasAccounts)
                Container(
                  padding: const EdgeInsets.all(17),
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
                          'No accounts available. Please add an account first.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                _buildAccountSelector(context),
              if (needsDestination) ...[
                const SizedBox(height: 20),
                _buildSectionTitle(
                  context,
                  _type == TransactionType.cardPayment
                      ? 'Credit Card to Pay'
                      : 'Destination Account',
                ),
                _buildDestinationSelector(context),
                const SizedBox(height: 13),
                _buildTransferInfo(context),
              ],
              if (!needsDestination) ...[
                const SizedBox(height: 20),
                _buildSectionTitle(
                  context,
                  _type == TransactionType.income ? 'Income Source' : 'Category',
                ),
                _buildCategorySelector(context),
              ],
              const SizedBox(height: 25),
              _buildSectionTitle(context, 'Date & Time'),
              _buildDateTimeCard(context),
              const SizedBox(height: 25),
              _buildSectionTitle(context, 'Note'),
              TextFormField(
                controller: _noteController,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Add a note (optional)',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 30),
                    child: Icon(Icons.notes_rounded),
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
