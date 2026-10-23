import 'package:flutter/material.dart';

import '../data/categories.dart';
import '../data/income_sources.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';

class TransactionDetailsScreen extends StatelessWidget {
  final DatabaseService databaseService;
  final TransactionModel transaction;

  const TransactionDetailsScreen({
    super.key,
    required this.databaseService,
    required this.transaction,
  });

  String _formatAmount(double amount) => '₹${amount.toStringAsFixed(2)}';

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';

  String _formatTime(DateTime date) {
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
        ? date.hour - 12
        : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  String _accountName(String id) =>
      databaseService.getAccount(id)?.name ?? 'Unknown Account';

  String _categoryName(String id) {
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

  String _transactionType() {
    switch (transaction.type) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.transfer:
        return 'Transfer';
      case TransactionType.cardPayment:
        return 'Credit Card Payment';
    }
  }

  IconData _transactionIcon() {
    switch (transaction.type) {
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

  Color _transactionColor() {
    switch (transaction.type) {
      case TransactionType.income:
        return Colors.green;
      case TransactionType.expense:
        return Colors.red;
      case TransactionType.transfer:
        return Colors.blue;
      case TransactionType.cardPayment:
        return Colors.deepPurple;
    }
  }

  String _amountText() {
    switch (transaction.type) {
      case TransactionType.income:
        return '+${_formatAmount(transaction.amount)}';
      case TransactionType.expense:
        return '-${_formatAmount(transaction.amount)}';
      case TransactionType.transfer:
      case TransactionType.cardPayment:
        return _formatAmount(transaction.amount);
    }
  }

  Future<void> _deleteTransaction(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: const Text(
          'Are you sure you want to delete this transaction?',
        ),
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

    if (confirmed != true || !context.mounted) return;

    await databaseService.deleteTransaction(transaction.id);

    if (!context.mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _editTransaction(BuildContext context) async {
    final updated = await showModalBottomSheet<TransactionModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _EditTransactionSheet(
        databaseService: databaseService,
        transaction: transaction,
      ),
    );

    if (updated == null) return;

    await databaseService.updateTransaction(updated);

    if (!context.mounted) return;
    Navigator.pop(context, true);
  }

  Widget _detailTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _transactionColor();
    final isTransfer = transaction.type == TransactionType.transfer;
    final isCardPayment = transaction.type == TransactionType.cardPayment;
    final hasDestination = isTransfer || isCardPayment;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            onPressed: () => _editTransaction(context),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: () => _deleteTransaction(context),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Icon(_transactionIcon(), color: color, size: 30),
                ),
                const SizedBox(height: 14),
                Text(
                  _transactionType(),
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                FittedBox(
                  child: Text(
                    _amountText(),
                    style: TextStyle(
                      color: color,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_formatDate(transaction.date)} • '
                  '${_formatTime(transaction.date)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Details',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _detailTile(
            context,
            icon: Icons.category_outlined,
            title: 'Type / Category',
            value: hasDestination
                ? _transactionType()
                : _categoryName(transaction.categoryId),
          ),
          _detailTile(
            context,
            icon: Icons.account_balance_outlined,
            title: hasDestination ? 'From Account' : 'Account',
            value: _accountName(transaction.accountId),
          ),
          if (hasDestination && transaction.toAccountId != null)
            _detailTile(
              context,
              icon: Icons.credit_card_outlined,
              title: isCardPayment ? 'Credit Card Paid' : 'To Account',
              value: _accountName(transaction.toAccountId!),
            ),
          _detailTile(
            context,
            icon: Icons.calendar_month_outlined,
            title: 'Date',
            value: _formatDate(transaction.date),
          ),
          _detailTile(
            context,
            icon: Icons.access_time_rounded,
            title: 'Time',
            value: _formatTime(transaction.date),
          ),
          if (transaction.note.trim().isNotEmpty)
            _detailTile(
              context,
              icon: Icons.notes_rounded,
              title: 'Note',
              value: transaction.note,
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _editTransaction(context),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Transaction'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _deleteTransaction(context),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete Transaction'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// EDIT TRANSACTION SHEET
// ============================================================

class _EditTransactionSheet extends StatefulWidget {
  final DatabaseService databaseService;
  final TransactionModel transaction;

  const _EditTransactionSheet({
    required this.databaseService,
    required this.transaction,
  });

  @override
  State<_EditTransactionSheet> createState() => _EditTransactionSheetState();
}

class _EditTransactionSheetState extends State<_EditTransactionSheet> {
  late TransactionType _type;
  late String _accountId;
  String? _toAccountId;
  String? _categoryId;
  late DateTime _date;

  late TextEditingController _amountController;
  late TextEditingController _noteController;

  List<Account> get _accounts => widget.databaseService.accounts;

  bool get _needsDestination =>
      _type == TransactionType.transfer || _type == TransactionType.cardPayment;

  List<Account> get _sourceAccounts {
    if (_type == TransactionType.cardPayment) {
      return _accounts.where((a) => !a.isCreditCard).toList();
    }

    return _accounts;
  }

  List<Account> get _destinationAccounts {
    return _accounts.where((account) {
      if (account.id == _accountId) return false;

      if (_type == TransactionType.cardPayment) {
        return account.isCreditCard;
      }

      return true;
    }).toList();
  }

  @override
  void initState() {
    super.initState();

    _type = widget.transaction.type;
    _accountId = widget.transaction.accountId;
    _toAccountId = widget.transaction.toAccountId;
    _categoryId = widget.transaction.categoryId;
    _date = widget.transaction.date;

    _amountController = TextEditingController(
      text: widget.transaction.amount.toStringAsFixed(2),
    );
    _noteController = TextEditingController(text: widget.transaction.note);

    if (_type == TransactionType.transfer ||
        _type == TransactionType.cardPayment) {
      _categoryId = null;
    }

    if (_sourceAccounts.isNotEmpty &&
        !_sourceAccounts.any((a) => a.id == _accountId)) {
      _accountId = _sourceAccounts.first.id;
    }

    if (_toAccountId != null &&
        !_destinationAccounts.any((a) => a.id == _toAccountId)) {
      _toAccountId = null;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _changeType(TransactionType type) {
    setState(() {
      _type = type;
      _toAccountId = null;
      _categoryId = null;

      if (_sourceAccounts.isNotEmpty &&
          !_sourceAccounts.any((a) => a.id == _accountId)) {
        _accountId = _sourceAccounts.first.id;
      }

      if (type == TransactionType.income && incomeSources.isNotEmpty) {
        _categoryId = incomeSources.first.id;
      } else if (type == TransactionType.expense &&
          expenseCategories.isNotEmpty) {
        _categoryId = expenseCategories.first.id;
      }

      if (type == TransactionType.cardPayment) {
        final cards = _accounts.where((a) => a.isCreditCard);
        if (cards.isNotEmpty) _toAccountId = cards.first.id;
      }
    });
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selected == null || !mounted) return;

    setState(() {
      _date = DateTime(
        selected.year,
        selected.month,
        selected.day,
        _date.hour,
        _date.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );

    if (selected == null || !mounted) return;

    setState(() {
      _date = DateTime(
        _date.year,
        _date.month,
        _date.day,
        selected.hour,
        selected.minute,
      );
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _save() {
    final amount = double.tryParse(_amountController.text.trim());

    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount.');
      return;
    }

    if (_sourceAccounts.isEmpty ||
        !_sourceAccounts.any((a) => a.id == _accountId)) {
      _showError('Please select a source account.');
      return;
    }

    if (_needsDestination) {
      if (_toAccountId == null) {
        _showError(
          _type == TransactionType.cardPayment
              ? 'Please select a credit card.'
              : 'Please select a destination account.',
        );
        return;
      }

      if (_toAccountId == _accountId) {
        _showError('Select two different accounts.');
        return;
      }

      final destination = widget.databaseService.getAccount(_toAccountId!);

      if (destination == null) {
        _showError('The destination account could not be found.');
        return;
      }

      if (_type == TransactionType.cardPayment && !destination.isCreditCard) {
        _showError('Select a credit card as the destination.');
        return;
      }
    } else if (_categoryId == null) {
      _showError('Please select a category.');
      return;
    }

    final updated = TransactionModel(
      id: widget.transaction.id,
      type: _type,
      amount: amount,
      categoryId: _type == TransactionType.transfer
          ? 'transfer'
          : _type == TransactionType.cardPayment
          ? 'card_payment'
          : _categoryId!,
      accountId: _accountId,
      toAccountId: _needsDestination ? _toAccountId : null,
      date: _date,
      note: _noteController.text.trim(),
    );

    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = _type == TransactionType.income
        ? incomeSources
        : expenseCategories;

    final selectedCategoryExists = categories.any(
      (category) => category.id == _categoryId,
    );

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Edit Transaction',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _typeChip(
                  label: 'Income',
                  value: TransactionType.income,
                  icon: Icons.arrow_downward_rounded,
                ),
                _typeChip(
                  label: 'Expense',
                  value: TransactionType.expense,
                  icon: Icons.arrow_upward_rounded,
                ),
                _typeChip(
                  label: 'Transfer',
                  value: TransactionType.transfer,
                  icon: Icons.swap_horiz_rounded,
                ),
                _typeChip(
                  label: 'Card Payment',
                  value: TransactionType.cardPayment,
                  icon: Icons.credit_card_rounded,
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _sourceAccounts.any((a) => a.id == _accountId)
                  ? _accountId
                  : null,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'From Account',
                border: OutlineInputBorder(),
              ),
              items: _sourceAccounts
                  .map(
                    (account) => DropdownMenuItem(
                      value: account.id,
                      child: Text(
                        account.isCreditCard
                            ? '${account.name} (Credit Card)'
                            : account.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _accountId = value;

                  if (_toAccountId == value) {
                    _toAccountId = null;
                  }
                });
              },
            ),
            if (_needsDestination) ...[
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue:
                    _destinationAccounts.any((a) => a.id == _toAccountId)
                    ? _toAccountId
                    : null,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: _type == TransactionType.cardPayment
                      ? 'Credit Card'
                      : 'To Account',
                  border: const OutlineInputBorder(),
                ),
                items: _destinationAccounts
                    .map(
                      (account) => DropdownMenuItem(
                        value: account.id,
                        child: Text(
                          account.isCreditCard
                              ? '${account.name} (Credit Card)'
                              : account.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() => _toAccountId = value);
                },
              ),
            ],
            if (!_needsDestination) ...[
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: selectedCategoryExists ? _categoryId : null,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: _type == TransactionType.income
                      ? 'Income Source'
                      : 'Category',
                  border: const OutlineInputBorder(),
                ),
                items: categories
                    .map(
                      (category) => DropdownMenuItem<String>(
                        value: category.id,
                        child: Text(
                          '${category.icon} ${category.name}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() => _categoryId = value);
                },
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(
                      '${_date.day.toString().padLeft(2, '0')}/'
                      '${_date.month.toString().padLeft(2, '0')}/'
                      '${_date.year}',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time_rounded),
                    label: Text(
                      '${_date.hour % 12 == 0 ? 12 : _date.hour % 12}:'
                      '${_date.minute.toString().padLeft(2, '0')} '
                      '${_date.hour >= 12 ? 'PM' : 'AM'}',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _save,
                child: const Text(
                  'Save Changes',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeChip({
    required String label,
    required TransactionType value,
    required IconData icon,
  }) {
    return ChoiceChip(
      selected: _type == value,
      avatar: Icon(icon, size: 17),
      label: Text(label),
      onSelected: (_) => _changeType(value),
    );
  }
}
