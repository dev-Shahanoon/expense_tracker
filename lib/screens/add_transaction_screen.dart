import 'package:flutter/material.dart';

import '../data/categories.dart';
import '../data/income_sources.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';

class AddTransactionScreen extends StatefulWidget {
  final DatabaseService databaseService;

  const AddTransactionScreen({super.key, required this.databaseService});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
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
  bool _isSaving = false;

  DatabaseService get databaseService => widget.databaseService;

  List<Account> get _accounts => databaseService.accounts;

  bool get _isTransfer => _type == TransactionType.transfer;

  bool get _isCardPayment => _type == TransactionType.cardPayment;

  bool get _needsDestination => _isTransfer || _isCardPayment;

  List<ExpenseCategory> get _currentCategories {
    if (_type == TransactionType.income) {
      return incomeSources;
    }

    if (_type == TransactionType.expense) {
      return expenseCategories;
    }

    return const <ExpenseCategory>[];
  }

  Color _typeColor() {
    switch (_type) {
      case TransactionType.income:
        return Colors.green;
      case TransactionType.expense:
        return Colors.redAccent;
      case TransactionType.transfer:
        return Colors.blue;
      case TransactionType.cardPayment:
        return Colors.deepPurple;
    }
  }

  bool _isCreditCard(Account account) {
    return account.type.toString().toLowerCase().contains('credit');
  }

  List<Account> get _sourceAccounts {
    if (_isCardPayment) {
      return _accounts.where((a) => !_isCreditCard(a)).toList();
    }
    return _accounts;
  }

  List<Account> get _destinationAccounts {
    if (_isCardPayment) {
      return _accounts.where(_isCreditCard).toList();
    }
    return _accounts.where((a) => a.id != _selectedAccountId).toList();
  }

  @override
  void initState() {
    super.initState();
    _syncSelections();
  }

  void _syncSelections() {
    final sources = _sourceAccounts;

    if (sources.isEmpty) {
      _selectedAccountId = null;
    } else if (_selectedAccountId == null ||
        !sources.any((a) => a.id == _selectedAccountId)) {
      _selectedAccountId = sources.first.id;
    }

    if (!_needsDestination) {
      _selectedToAccountId = null;
    } else {
      final destinations = _destinationAccounts;

      if (destinations.isEmpty) {
        _selectedToAccountId = null;
      } else if (_selectedToAccountId == null ||
          !destinations.any((a) => a.id == _selectedToAccountId)) {
        _selectedToAccountId = destinations.first.id;
      }
    }

    final categories = _currentCategories;

    if (categories.isEmpty) {
      _selectedCategoryId = null;
    } else if (_selectedCategoryId == null ||
        !categories.any((c) => c.id == _selectedCategoryId)) {
      _selectedCategoryId = categories.first.id;
    }
  }

  void _changeType(TransactionType? type) {
    if (type == null) return;

    setState(() {
      _type = type;
      _syncSelections();
    });
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (date == null || !mounted) return;

    setState(() {
      _selectedDate = DateTime(
        date.year,
        date.month,
        date.day,
        _selectedDate.hour,
        _selectedDate.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );

    if (time == null || !mounted) return;

    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _saveTransaction() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(
      _amountController.text.trim().replaceAll(',', ''),
    );

    if (amount == null || amount <= 0) {
      _showMessage('Enter a valid amount greater than zero.');
      return;
    }

    if (_accounts.isEmpty) {
      _showMessage('Please add an account first.');
      return;
    }

    if (_selectedAccountId == null ||
        !_accounts.any((a) => a.id == _selectedAccountId)) {
      _showMessage('Please select a valid source account.');
      return;
    }

    if (_needsDestination) {
      if (_selectedToAccountId == null) {
        _showMessage(
          _isCardPayment
              ? 'Add a credit card account first.'
              : 'Please select a destination account.',
        );
        return;
      }

      if (_selectedAccountId == _selectedToAccountId) {
        _showMessage('Source and destination must be different.');
        return;
      }

      final destination = _accounts.where((a) => a.id == _selectedToAccountId);

      if (destination.isEmpty) {
        _showMessage('Please select a valid destination account.');
        return;
      }

      if (_isCardPayment && !_isCreditCard(destination.first)) {
        _showMessage('Select a credit card as the destination.');
        return;
      }

      if (_isCardPayment) {
        final source = _accounts.firstWhere((a) => a.id == _selectedAccountId);

        if (_isCreditCard(source)) {
          _showMessage('Choose a bank or cash account to pay the credit card.');
          return;
        }
      }
    }

    if (!_isTransfer && !_isCardPayment) {
      if (_selectedCategoryId == null ||
          !_currentCategories.any((c) => c.id == _selectedCategoryId)) {
        _showMessage('Please select a category.');
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final transaction = TransactionModel(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        type: _type,
        amount: amount,
        categoryId: _isTransfer
            ? 'transfer'
            : _isCardPayment
            ? 'card_payment'
            : _selectedCategoryId!,
        accountId: _selectedAccountId!,
        toAccountId: _needsDestination ? _selectedToAccountId : null,
        note: _noteController.text.trim(),
        date: _selectedDate,
      );

      await databaseService.addTransaction(transaction);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        _showMessage('Could not save transaction. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _typeLabel(TransactionType type) {
    switch (type) {
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.income:
        return 'Income';
      case TransactionType.transfer:
        return 'Transfer';
      case TransactionType.cardPayment:
        return 'Card payment';
    }
  }

  IconData _typeIcon(TransactionType type) {
    switch (type) {
      case TransactionType.expense:
        return Icons.arrow_upward_rounded;
      case TransactionType.income:
        return Icons.arrow_downward_rounded;
      case TransactionType.transfer:
        return Icons.swap_horiz_rounded;
      case TransactionType.cardPayment:
        return Icons.credit_card_rounded;
    }
  }

  Widget _buildTypeSelector() {
    final color = _typeColor();
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: TransactionType.values.map((type) {
          final selected = _type == type;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _changeType(type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 2,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? colors.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _typeIcon(type),
                        size: 19,
                        color: selected ? color : colors.onSurfaceVariant,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _typeLabel(type),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected
                              ? colors.onSurface
                              : colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // One outer border only: the rupee symbol and input share the same field.
  Widget _buildAmountField() {
    final color = _typeColor();
    final colors = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AMOUNT',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.onSurfaceVariant,
              letterSpacing: 1.3,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '₹',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: TextStyle(
                      color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  validator: (value) {
                    final amount = double.tryParse(
                      (value ?? '').trim().replaceAll(',', ''),
                    );

                    if (amount == null || amount <= 0) {
                      return 'Enter a valid amount';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountDropdown({
    required String label,
    required String? value,
    required List<Account> accounts,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    final colors = Theme.of(context).colorScheme;

    return DropdownButtonFormField<String>(
      initialValue: accounts.any((a) => a.id == value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.65),
          ),
        ),
      ),
      items: accounts.map((account) {
        return DropdownMenuItem<String>(
          value: account.id,
          child: Row(
            children: [
              Icon(
                _isCreditCard(account)
                    ? Icons.credit_card_rounded
                    : Icons.account_balance_rounded,
                size: 20,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  account.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (selected) {
        if (selected == null || !accounts.any((a) => a.id == selected)) {
          return 'Please select an account';
        }
        return null;
      },
    );
  }

  Widget _buildCategorySelector() {
    final categories = _currentCategories;
    final colors = Theme.of(context).colorScheme;

    ExpenseCategory? selected;

    for (final category in categories) {
      if (category.id == _selectedCategoryId) {
        selected = category;
        break;
      }
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: categories.isEmpty
          ? null
          : () async {
              final result = await showModalBottomSheet<ExpenseCategory>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _CategoryPickerSheet(
                  categories: categories,
                  selectedCategoryId: _selectedCategoryId,
                  accentColor: _typeColor(),
                ),
              );

              if (result != null && mounted) {
                setState(() => _selectedCategoryId = result.id);
              }
            },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _typeColor().withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                selected?.icon ?? '📁',
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selected?.name ?? 'Choose category',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to browse categories',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSelector() {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_month_rounded),
            label: Text(
              '${_selectedDate.day.toString().padLeft(2, '0')}/'
              '${_selectedDate.month.toString().padLeft(2, '0')}/'
              '${_selectedDate.year}',
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              foregroundColor: colors.onSurface,
              side: BorderSide(color: colors.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: OutlinedButton.icon(
            onPressed: _pickTime,
            icon: const Icon(Icons.access_time_rounded),
            label: Text(TimeOfDay.fromDateTime(_selectedDate).format(context)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              foregroundColor: colors.onSurface,
              side: BorderSide(color: colors.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final sourceAccounts = _sourceAccounts;
    final destinationAccounts = _destinationAccounts;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction'), centerTitle: false),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              _buildTypeSelector(),
              const SizedBox(height: 22),
              _buildAmountField(),
              const SizedBox(height: 26),
              _buildSectionTitle('Account'),
              _buildAccountDropdown(
                label: _needsDestination ? 'Pay from' : 'Select account',
                value: _selectedAccountId,
                accounts: sourceAccounts,
                icon: Icons.account_balance_wallet_outlined,
                onChanged: (value) {
                  setState(() {
                    _selectedAccountId = value;

                    if (_needsDestination && _selectedToAccountId == value) {
                      final alternatives = destinationAccounts
                          .where((a) => a.id != value)
                          .toList();
                      _selectedToAccountId = alternatives.isEmpty
                          ? null
                          : alternatives.first.id;
                    }
                  });
                },
              ),
              if (_needsDestination) ...[
                const SizedBox(height: 16),
                _buildAccountDropdown(
                  label: _isCardPayment ? 'Credit card to pay' : 'Transfer to',
                  value: _selectedToAccountId,
                  accounts: destinationAccounts
                      .where((a) => a.id != _selectedAccountId)
                      .toList(),
                  icon: _isCardPayment
                      ? Icons.credit_card_rounded
                      : Icons.swap_horiz_rounded,
                  onChanged: (value) {
                    setState(() => _selectedToAccountId = value);
                  },
                ),
              ],
              if (_isCardPayment) ...[
                const SizedBox(height: 10),
                Text(
                  'Choose the bank or cash account paying the bill and the '
                  'credit card receiving the payment.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
              if (!_isTransfer && !_isCardPayment) ...[
                const SizedBox(height: 26),
                _buildSectionTitle('Category'),
                _buildCategorySelector(),
              ],
              const SizedBox(height: 26),
              _buildSectionTitle('Date and time'),
              _buildDateTimeSelector(),
              const SizedBox(height: 26),
              _buildSectionTitle('Note (optional)'),
              TextFormField(
                controller: _noteController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'What was this transaction for?',
                  prefixIcon: const Icon(Icons.notes_rounded),
                  filled: true,
                  fillColor: colors.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: colors.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: colors.outlineVariant),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveTransaction,
                  style: FilledButton.styleFrom(
                    backgroundColor: _typeColor(),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_typeIcon(_type), size: 20),
                            const SizedBox(width: 9),
                            Text(
                              'Save ${_typeLabel(_type)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
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

class _CategoryPickerSheet extends StatelessWidget {
  final List<ExpenseCategory> categories;
  final String? selectedCategoryId;
  final Color accentColor;

  const _CategoryPickerSheet({
    required this.categories,
    required this.selectedCategoryId,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: colors.onSurfaceVariant.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose category',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${categories.length} categories',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.outlineVariant),
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.92,
              ),
              itemBuilder: (context, index) {
                final category = categories[index];
                final selected = category.id == selectedCategoryId;

                return Material(
                  color: selected
                      ? accentColor.withValues(alpha: 0.10)
                      : colors.surfaceContainerHighest.withValues(alpha: 0.38),
                  borderRadius: BorderRadius.circular(17),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(17),
                    onTap: () => Navigator.pop(context, category),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(
                          color: selected
                              ? accentColor
                              : colors.outlineVariant.withValues(alpha: 0.5),
                          width: selected ? 1.5 : 0.8,
                        ),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Stack(
                        children: [
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? accentColor.withValues(alpha: 0.13)
                                        : colors.surface,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    category.icon,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                                const SizedBox(height: 9),
                                Text(
                                  category.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: selected
                                        ? accentColor
                                        : colors.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (selected)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Icon(
                                Icons.check_circle_rounded,
                                size: 17,
                                color: accentColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
