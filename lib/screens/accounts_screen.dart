import 'package:flutter/material.dart';

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

  String _selectedType = 'Bank Account';

  @override
  void dispose() {
    _nameController.dispose();
    _bankController.dispose();
    _balanceController.dispose();
    _lastFourController.dispose();
    super.dispose();
  }

  double get _totalBalance {
    return widget.databaseService.totalBalance;
  }

  String _formatAmount(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

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
    final colorScheme = Theme.of(context).colorScheme;

    switch (type) {
      case 'Bank Account':
        return colorScheme.primary;
      case 'Savings':
        return Colors.green;
      case 'Cash':
        return Colors.orange;
      case 'Credit Card':
        return Colors.redAccent;
      case 'Wallet':
        return Colors.purple;
      default:
        return colorScheme.primary;
    }
  }

  void _showAddAccountSheet() {
    _nameController.clear();
    _bankController.clear();
    _balanceController.clear();
    _lastFourController.clear();

    _selectedType = 'Bank Account';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final theme = Theme.of(context);
            final colorScheme = theme.colorScheme;

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 10,
                bottom:
                    MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colorScheme.outlineVariant,
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),

                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius:
                                  BorderRadius.circular(15),
                            ),
                            child: Icon(
                              Icons.account_balance_rounded,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Add Account',
                                  style: theme
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Add a bank, wallet or cash account',
                                  style: theme
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.55),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 26),

                      _buildFieldLabel(
                        context,
                        'Account Name',
                      ),
                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Main Account',
                          prefixIcon: Icon(
                            Icons.person_outline_rounded,
                          ),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Please enter an account name';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 17),

                      _buildFieldLabel(
                        context,
                        'Bank / Provider',
                      ),
                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _bankController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          hintText: 'e.g. HDFC Bank',
                          prefixIcon: Icon(
                            Icons.account_balance_outlined,
                          ),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Please enter bank or provider';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 17),

                      _buildFieldLabel(
                        context,
                        'Account Type',
                      ),
                      const SizedBox(height: 8),

                      DropdownButtonFormField<String>(
                        initialValue: _selectedType,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(
                            Icons.category_outlined,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Bank Account',
                            child: Text('Bank Account'),
                          ),
                          DropdownMenuItem(
                            value: 'Savings',
                            child: Text('Savings'),
                          ),
                          DropdownMenuItem(
                            value: 'Cash',
                            child: Text('Cash'),
                          ),
                          DropdownMenuItem(
                            value: 'Credit Card',
                            child: Text('Credit Card'),
                          ),
                          DropdownMenuItem(
                            value: 'Wallet',
                            child: Text('Wallet'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          setSheetState(() {
                            _selectedType = value;
                          });
                        },
                      ),

                      const SizedBox(height: 17),

                      _buildFieldLabel(
                        context,
                        'Opening Balance',
                      ),
                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _balanceController,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          hintText: '0.00',
                          prefixIcon: Icon(
                            Icons.currency_rupee_rounded,
                          ),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Please enter opening balance';
                          }

                          final amount =
                              double.tryParse(value.trim());

                          if (amount == null) {
                            return 'Enter a valid amount';
                          }

                          if (amount < 0) {
                            return 'Balance cannot be negative';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 17),

                      _buildFieldLabel(
                        context,
                        'Last 4 Digits',
                      ),
                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _lastFourController,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          hintText: 'Optional',
                          prefixIcon: Icon(
                            Icons.password_rounded,
                          ),
                          counterText: '',
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return null;
                          }

                          if (value.trim().length != 4) {
                            return 'Enter exactly 4 digits';
                          }

                          if (int.tryParse(value.trim()) == null) {
                            return 'Enter numbers only';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 26),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton.icon(
                          onPressed: _saveAccount,
                          icon: const Icon(
                            Icons.add_rounded,
                          ),
                          label: const Text(
                            'Add Account',
                            style: TextStyle(
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

  Widget _buildFieldLabel(
    BuildContext context,
    String text,
  ) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
    );
  }

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final account = Account(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      bankName: _bankController.text.trim(),
      type: _selectedType,
      openingBalance:
          double.parse(_balanceController.text.trim()),
      lastFourDigits:
          _lastFourController.text.trim().isEmpty
              ? null
              : _lastFourController.text.trim(),
    );

    await widget.databaseService.addAccount(account);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Account added successfully',
        ),
      ),
    );
  }

  Future<void> _deleteAccount(Account account) async {
    final accountTransactions =
        widget.databaseService.getAccountTransactions(
      account.id,
    );

    if (accountTransactions.isNotEmpty) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot delete "${account.name}" because it '
            'has ${accountTransactions.length} '
            '${accountTransactions.length == 1 ? 'transaction' : 'transactions'}.',
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);

        return AlertDialog(
          title: const Text('Delete Account?'),
          content: Text(
            'Are you sure you want to delete "${account.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await widget.databaseService.deleteAccount(
      account.id,
    );

    if (!mounted) {
      return;
    }

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${account.name} deleted',
        ),
      ),
    );
  }

  Widget _buildTotalBalanceCard(BuildContext context) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    final cardColor = isDark
        ? const Color(0xFF182235)
        : const Color(0xFF17243A);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Total Balance',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${widget.databaseService.accounts.length}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Text(
            _formatAmount(_totalBalance),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            widget.databaseService.accounts.length == 1
                ? '1 account connected'
                : '${widget.databaseService.accounts.length} accounts connected',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.58),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(
    BuildContext context,
    Account account,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final balance =
        widget.databaseService.getAccountBalance(account.id);

    final iconColor =
        _accountIconColor(context, account.type);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(
            alpha: theme.brightness == Brightness.dark
                ? 0.20
                : 0.35,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          17,
          17,
          12,
          17,
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    _accountIcon(account.type),
                    color: iconColor,
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
                        account.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        account.bankName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(
                            alpha: 0.55,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                PopupMenuButton<String>(
                  tooltip: 'Account options',
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    color: colorScheme.onSurface.withValues(
                      alpha: 0.55,
                    ),
                  ),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteAccount(account);
                    }
                  },
                  itemBuilder: (context) {
                    return const [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.red,
                            ),
                            SizedBox(width: 10),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.32),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.type,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.55,
                            ),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          account.lastFourDigits == null
                              ? 'Account'
                              : '•••• ${account.lastFourDigits}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    width: 1,
                    height: 30,
                    color: colorScheme.outlineVariant.withValues(
                      alpha: 0.35,
                    ),
                  ),

                  const SizedBox(width: 15),

                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Balance',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurface.withValues(
                            alpha: 0.55,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatAmount(balance),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
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
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 42,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.28,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: 0.25,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 33,
              color: colorScheme.primary,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            'No accounts yet',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Add your first account to start tracking '
            'your balance and transactions.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(
                alpha: 0.58,
              ),
              height: 1.45,
            ),
          ),

          const SizedBox(height: 22),

          FilledButton.icon(
            onPressed: _showAddAccountSheet,
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Add Account',
              style: TextStyle(
                fontWeight: FontWeight.w800,
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
    final accounts = widget.databaseService.accounts;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Accounts',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              110,
            ),
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
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${accounts.length}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (accounts.isEmpty)
                _buildEmptyState(context)
              else
                ...accounts.map(
                  (account) => Padding(
                    padding: const EdgeInsets.only(
                      bottom: 12,
                    ),
                    child: _buildAccountCard(
                      context,
                      account,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAccountSheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Account',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}