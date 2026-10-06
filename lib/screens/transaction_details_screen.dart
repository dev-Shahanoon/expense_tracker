import 'package:flutter/material.dart';

import '../data/categories.dart';
import '../data/income_sources.dart';
import '../models/account.dart';
import '../models/category.dart';
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

  String _formatAmount(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  String _formatDateTime(DateTime date) {
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;

    final minute = date.minute.toString().padLeft(2, '0');

    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} • '
        '$hour:$minute $period';
  }

  String _getAccountName(String accountId) {
    final account = databaseService.getAccount(accountId);

    return account?.name ?? 'Unknown Account';
  }

  String _getAccountSubtitle(String accountId) {
    final account = databaseService.getAccount(accountId);

    if (account == null) {
      return 'Unknown account';
    }

    if (account.lastFourDigits != null) {
      return '${account.bankName} •••• ${account.lastFourDigits}';
    }

    return account.bankName;
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

  String _getTransactionType() {
    switch (transaction.type) {
      case TransactionType.income:
        return 'Income';

      case TransactionType.expense:
        return 'Expense';

      case TransactionType.transfer:
        return 'Transfer';
    }
  }

  IconData _getTransactionIcon() {
    switch (transaction.type) {
      case TransactionType.income:
        return Icons.arrow_downward_rounded;

      case TransactionType.expense:
        return Icons.arrow_upward_rounded;

      case TransactionType.transfer:
        return Icons.swap_horiz_rounded;
    }
  }

  Color _getTransactionColor(BuildContext context) {
    switch (transaction.type) {
      case TransactionType.income:
        return Colors.green;

      case TransactionType.expense:
        return Colors.red;

      case TransactionType.transfer:
        return Colors.blue;
    }
  }

  String _getAmountText() {
    switch (transaction.type) {
      case TransactionType.income:
        return '+${_formatAmount(transaction.amount)}';

      case TransactionType.expense:
        return '-${_formatAmount(transaction.amount)}';

      case TransactionType.transfer:
        return _formatAmount(transaction.amount);
    }
  }

  Future<void> _deleteTransaction(
    BuildContext context,
  ) async {
    final confirmed = await showDialog<bool>(
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
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!context.mounted || confirmed != true) {
      return;
    }

    await databaseService.deleteTransaction(
      transaction.id,
    );

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).pop(true);
  }

  Future<void> _editTransaction(
    BuildContext context,
  ) async {
    final result = await showModalBottomSheet<TransactionModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (sheetContext) {
        return _EditTransactionSheet(
          databaseService: databaseService,
          transaction: transaction,
        );
      },
    );

    if (result == null) {
      return;
    }

    await databaseService.updateTransaction(result);

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).pop(true);
  }

  Widget _buildDetailTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    String? subtitle,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary
                  .withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transactionColor =
        _getTransactionColor(context);

    final isTransfer =
        transaction.type == TransactionType.transfer;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transaction Details',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Edit transaction',
            onPressed: () {
              _editTransaction(context);
            },
            icon: const Icon(
              Icons.edit_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Delete transaction',
            onPressed: () {
              _deleteTransaction(context);
            },
            icon: const Icon(
              Icons.delete_outline_rounded,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            32,
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 28,
              ),
              decoration: BoxDecoration(
                color: transactionColor.withValues(
                  alpha: 0.10,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: transactionColor.withValues(
                        alpha: 0.14,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getTransactionIcon(),
                      color: transactionColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getTransactionType(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: transactionColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getAmountText(),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: transactionColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDateTime(transaction.date),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 12),

            _buildDetailTile(
              context: context,
              icon: Icons.category_outlined,
              title: isTransfer
                  ? 'Transaction Type'
                  : transaction.type ==
                          TransactionType.income
                      ? 'Income Source'
                      : 'Category',
              value: isTransfer
                  ? 'Transfer'
                  : _getCategoryName(
                      transaction.categoryId,
                    ),
            ),

            _buildDetailTile(
              context: context,
              icon: Icons.account_balance_rounded,
              title: isTransfer
                  ? 'From Account'
                  : 'Account',
              value: _getAccountName(
                transaction.accountId,
              ),
              subtitle: _getAccountSubtitle(
                transaction.accountId,
              ),
            ),

            if (isTransfer &&
                transaction.toAccountId != null)
              _buildDetailTile(
                context: context,
                icon: Icons.account_balance_rounded,
                title: 'To Account',
                value: _getAccountName(
                  transaction.toAccountId!,
                ),
                subtitle: _getAccountSubtitle(
                  transaction.toAccountId!,
                ),
              ),

            _buildDetailTile(
              context: context,
              icon: Icons.schedule_rounded,
              title: 'Date & Time',
              value: _formatDateTime(
                transaction.date,
              ),
            ),

            if (transaction.note.trim().isNotEmpty)
              _buildDetailTile(
                context: context,
                icon: Icons.notes_rounded,
                title: 'Note',
                value: transaction.note,
              ),

            const SizedBox(height: 10),

            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  _editTransaction(context);
                },
                icon: const Icon(
                  Icons.edit_outlined,
                ),
                label: const Text(
                  'Edit Transaction',
                ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  _deleteTransaction(context);
                },
                icon: const Icon(
                  Icons.delete_outline_rounded,
                ),
                label: const Text(
                  'Delete Transaction',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditTransactionSheet extends StatefulWidget {
  final DatabaseService databaseService;
  final TransactionModel transaction;

  const _EditTransactionSheet({
    required this.databaseService,
    required this.transaction,
  });

  @override
  State<_EditTransactionSheet> createState() =>
      _EditTransactionSheetState();
}

class _EditTransactionSheetState
    extends State<_EditTransactionSheet> {
  late TransactionType _type;
  late String _accountId;
  String? _toAccountId;
  String? _categoryId;
  late DateTime _date;
  late TextEditingController _amountController;
  late TextEditingController _noteController;

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

    _noteController = TextEditingController(
      text: widget.transaction.note,
    );

    if (_type == TransactionType.transfer) {
      _categoryId = null;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

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

  List<ExpenseCategory> get _availableCategories {
    if (_type == TransactionType.income) {
      return incomeSources;
    }

    return expenseCategories;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _date = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _date.hour,
        _date.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _date = DateTime(
        _date.year,
        _date.month,
        _date.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  void _changeType(TransactionType type) {
    setState(() {
      _type = type;

      if (type == TransactionType.transfer) {
        _categoryId = null;
        _toAccountId = null;
      } else {
        _toAccountId = null;

        if (_categoryId == null ||
            !_availableCategories.any(
              (item) => item.id == _categoryId,
            )) {
          _categoryId = _availableCategories.first.id;
        }
      }
    });
  }

  void _save() {
    final amount = double.tryParse(
      _amountController.text.trim(),
    );

    if (amount == null || amount <= 0) {
      _showError('Enter a valid amount.');
      return;
    }

    if (_type != TransactionType.transfer &&
        _categoryId == null) {
      _showError('Please select a category.');
      return;
    }

    if (_type == TransactionType.transfer) {
      if (_toAccountId == null) {
        _showError('Please select a destination account.');
        return;
      }

      if (_toAccountId == _accountId) {
        _showError(
          'Source and destination accounts must be different.',
        );
        return;
      }
    }

    final updatedTransaction = TransactionModel(
      id: widget.transaction.id,
      type: _type,
      amount: amount,
      categoryId: _type == TransactionType.transfer
          ? 'transfer'
          : _categoryId!,
      accountId: _accountId,
      toAccountId:
          _type == TransactionType.transfer
              ? _toAccountId
              : null,
      note: _noteController.text.trim(),
      date: _date,
    );

    Navigator.of(context).pop(updatedTransaction);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accounts = widget.databaseService.accounts;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom:
            MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Edit Transaction',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 18),

            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('Expense'),
                  icon: Icon(
                    Icons.arrow_upward_rounded,
                  ),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text('Income'),
                  icon: Icon(
                    Icons.arrow_downward_rounded,
                  ),
                ),
                ButtonSegment(
                  value: TransactionType.transfer,
                  label: Text('Transfer'),
                  icon: Icon(
                    Icons.swap_horiz_rounded,
                  ),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (selection) {
                _changeType(selection.first);
              },
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(
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
              initialValue: _accountId,
              decoration: InputDecoration(
                labelText: _type == TransactionType.transfer
                    ? 'From Account'
                    : 'Account',
                border: const OutlineInputBorder(),
              ),
              items: accounts.map((Account account) {
                return DropdownMenuItem<String>(
                  value: account.id,
                  child: Text(account.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _accountId = value;

                  if (_toAccountId == value) {
                    _toAccountId = null;
                  }
                });
              },
            ),

            if (_type == TransactionType.transfer) ...[
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                initialValue: _toAccountId,
                decoration: const InputDecoration(
                  labelText: 'To Account',
                  border: OutlineInputBorder(),
                ),
                items: accounts
                    .where(
                      (account) =>
                          account.id != _accountId,
                    )
                    .map((Account account) {
                  return DropdownMenuItem<String>(
                    value: account.id,
                    child: Text(account.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _toAccountId = value;
                  });
                },
              ),
            ],

            if (_type != TransactionType.transfer) ...[
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                decoration: InputDecoration(
                  labelText:
                      _type == TransactionType.income
                          ? 'Income Source'
                          : 'Category',
                  border: const OutlineInputBorder(),
                ),
                items: _availableCategories
                    .map((ExpenseCategory category) {
                  return DropdownMenuItem<String>(
                    value: category.id,
                    child: Text(
                      '${category.icon} ${category.name}',
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _categoryId = value;
                  });
                },
              ),
            ],

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(
                      Icons.calendar_today_rounded,
                    ),
                    label: Text(
                      _formatDate(_date),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(
                      Icons.access_time_rounded,
                    ),
                    label: Text(
                      _formatTime(_date),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Note',
                hintText: 'Optional note',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(
                  Icons.check_rounded,
                ),
                label: const Text(
                  'Save Changes',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}