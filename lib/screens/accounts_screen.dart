
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/account.dart';
import '../services/database_service.dart';

class AccountsScreen extends StatefulWidget {
  final DatabaseService databaseService;

  const AccountsScreen({
    super.key,
    required this.databaseService,
  });

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _bankController = TextEditingController();
  final _balanceController = TextEditingController();
  final _lastFourController = TextEditingController();
  final _creditLimitController = TextEditingController();

  String _selectedType = 'Bank Account';

  final List<String> _accountTypes = [
    'Bank Account',
    'Savings',
    'Cash',
    'Credit Card',
    'Wallet',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _bankController.dispose();
    _balanceController.dispose();
    _lastFourController.dispose();
    _creditLimitController.dispose();
    super.dispose();
  }

  String _formatAmount(double amount) =>
      '₹${amount.toStringAsFixed(2)}';

  double get _totalBalance =>
      widget.databaseService.totalBalance;

  IconData _accountIcon(String type) {
    switch (type) {
      case 'Bank Account':
        return Icons.account_balance_rounded;
      case 'Savings':
        return Icons.savings_rounded;
      case 'Cash':
        return Icons.payments_rounded;
      case 'Credit Card':
        return Icons.credit_card_rounded;
      case 'Wallet':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.account_balance_rounded;
    }
  }

  Color _accountIconColor(BuildContext context, String type) {
    final colors = Theme.of(context).colorScheme;

    switch (type) {
      case 'Bank Account':
        return colors.primary;
      case 'Savings':
        return Colors.green;
      case 'Cash':
        return Colors.orange;
      case 'Credit Card':
        return Colors.redAccent;
      case 'Wallet':
        return Colors.purple;
      default:
        return colors.primary;
    }
  }

  void _showAccountSheet({Account? account}) {
    final isEditing = account != null;

    _nameController.text = account?.name ?? '';
    _bankController.text = account?.bankName ?? '';
    _balanceController.text =
        account?.openingBalance.toString() ?? '';
    _lastFourController.text = account?.lastFourDigits ?? '';
    _creditLimitController.text =
        account?.creditLimit?.toString() ?? '';

    _selectedType = account?.type ?? 'Bank Account';

    if (!_accountTypes.contains(_selectedType)) {
      _selectedType = 'Bank Account';
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final theme = Theme.of(context);
            final colors = theme.colorScheme;
            final isCreditCard = _selectedType == 'Credit Card';

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colors.outlineVariant,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Icon(
                            isEditing
                                ? Icons.edit_rounded
                                : Icons.account_balance_wallet_rounded,
                            size: 28,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isEditing ? 'Edit Account' : 'Add Account',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      _label(context, 'Account Name'),
                      const SizedBox(height: 7),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Main Account',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Enter an account name'
                                : null,
                      ),

                      const SizedBox(height: 16),
                      _label(context, 'Bank / Provider'),
                      const SizedBox(height: 7),
                      TextFormField(
                        controller: _bankController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'e.g. HDFC Bank',
                          prefixIcon:
                              Icon(Icons.account_balance_outlined),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Enter the bank or provider'
                                : null,
                      ),

                      const SizedBox(height: 16),
                      _label(context, 'Account Type'),
                      const SizedBox(height: 7),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedType,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: _accountTypes
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          setSheetState(() {
                            _selectedType = value;
                          });
                        },
                      ),

                      const SizedBox(height: 16),
                      _label(
                        context,
                        isCreditCard
                            ? 'Current Outstanding at Setup'
                            : 'Opening Balance',
                      ),
                      const SizedBox(height: 7),
                      TextFormField(
                        controller: _balanceController,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        decoration: InputDecoration(
                          hintText: '0.00',
                          prefixIcon: const Icon(
                            Icons.currency_rupee_rounded,
                          ),
                          helperText: isCreditCard
                              ? 'Existing card debt before tracked transactions'
                              : null,
                        ),
                        validator: (value) {
                          final amount = double.tryParse(
                            value?.trim() ?? '',
                          );

                          if (amount == null) {
                            return 'Enter a valid amount';
                          }

                          if (!amount.isFinite || amount < 0) {
                            return 'Enter a valid non-negative amount';
                          }

                          return null;
                        },
                      ),

                      if (isCreditCard) ...[
                        const SizedBox(height: 16),
                        _label(context, 'Credit Limit'),
                        const SizedBox(height: 7),
                        TextFormField(
                          controller: _creditLimitController,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}'),
                            ),
                          ],
                          decoration: const InputDecoration(
                            hintText: 'e.g. 50000',
                            prefixIcon:
                                Icon(Icons.credit_card_rounded),
                            helperText:
                                'Enter the total limit provided by your bank',
                          ),
                          validator: (value) {
                            if (!isCreditCard) return null;

                            final limit = double.tryParse(
                              value?.trim() ?? '',
                            );

                            if (limit == null ||
                                !limit.isFinite ||
                                limit <= 0) {
                              return 'Enter a credit limit greater than zero';
                            }

                            return null;
                          },
                        ),
                      ],

                      const SizedBox(height: 16),
                      _label(context, 'Last 4 Digits (Optional)'),
                      const SizedBox(height: 7),
                      TextFormField(
                        controller: _lastFourController,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          hintText: '1234',
                          prefixIcon: Icon(Icons.password_rounded),
                          counterText: '',
                        ),
                        validator: (value) {
                          final digits = value?.trim() ?? '';

                          if (digits.isEmpty) return null;

                          if (digits.length != 4) {
                            return 'Enter exactly 4 digits';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: () => _saveAccount(account),
                          icon: Icon(
                            isEditing
                                ? Icons.save_rounded
                                : Icons.add_rounded,
                          ),
                          label: Text(
                            isEditing ? 'Save Changes' : 'Add Account',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _label(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }

  Future<void> _saveAccount(Account? existingAccount) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final isCreditCard = _selectedType == 'Credit Card';

    final account = Account(
      id: existingAccount?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      bankName: _bankController.text.trim(),
      type: _selectedType,
      openingBalance: double.parse(_balanceController.text.trim()),
      lastFourDigits: _lastFourController.text.trim().isEmpty
          ? null
          : _lastFourController.text.trim(),
      creditLimit: isCreditCard
          ? double.parse(_creditLimitController.text.trim())
          : null,
      billingDueDate: existingAccount?.billingDueDate,
    );

    try {
      await widget.databaseService.addAccount(account);

      if (!mounted) return;

      Navigator.of(context).pop();

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existingAccount == null
                ? 'Account added successfully'
                : 'Account updated successfully',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save account: $error')),
      );
    }
  }

  Future<void> _deleteAccount(Account account) async {
    final linkedTransactions =
        widget.databaseService.getAccountTransactions(account.id);

    if (linkedTransactions.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot delete "${account.name}" because it has '
            '${linkedTransactions.length} linked transactions.',
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Account?'),
        content: Text('Delete "${account.name}"?'),
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

    if (confirmed != true) return;

    try {
      await widget.databaseService.deleteAccount(account.id);

      if (!mounted) return;

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${account.name} deleted')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete account: $error')),
      );
    }
  }

  Widget _buildTotalBalanceCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF17243A),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.account_balance_wallet_rounded,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(height: 16),
          Text(
            'Total Balance',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            _formatAmount(_totalBalance),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.databaseService.accounts.length} accounts connected',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, Account account) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isCreditCard = account.isCreditCard;
    final balance =
        widget.databaseService.getAccountBalance(account.id);

    final availableCredit =
        widget.databaseService.getAvailableCredit(account.id);

    final creditLimit = account.creditLimit ?? 0;
    final iconColor = _accountIconColor(context, account.type);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: colors.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    _accountIcon(account.type),
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        account.bankName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Account options',
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showAccountSheet(account: account);
                    } else if (value == 'delete') {
                      _deleteAccount(account);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined),
                          SizedBox(width: 10),
                          Text('Edit Account'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.red,
                          ),
                          SizedBox(width: 10),
                          Text('Delete Account'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(
                  alpha: 0.30,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${account.type}'
                    '${account.lastFourDigits == null ? '' : ' •••• ${account.lastFourDigits}'}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isCreditCard
                                  ? 'Credit Limit'
                                  : 'Balance',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colors.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatAmount(
                                isCreditCard ? creditLimit : balance,
                              ),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isCreditCard) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Outstanding Debt',
                                textAlign: TextAlign.end,
                                style:
                                    theme.textTheme.labelSmall?.copyWith(
                                  color: colors.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatAmount(balance),
                                textAlign: TextAlign.end,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (isCreditCard) ...[
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 18,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Available Credit',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          _formatAmount(availableCredit),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 45, horizontal: 20),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 58,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'No accounts yet',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your first account to start tracking your money.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _showAccountSheet(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Account'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accounts = widget.databaseService.accounts;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Accounts',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (mounted) setState(() {});
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
            children: [
              _buildTotalBalanceCard(context),
              const SizedBox(height: 26),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Your Accounts',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '${accounts.length}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (accounts.isEmpty)
                _buildEmptyState(context)
              else
                ...accounts.map(
                  (account) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildAccountCard(context, account),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAccountSheet(),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Account',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
