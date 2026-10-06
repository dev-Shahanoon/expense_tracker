import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/categories.dart';
import '../data/income_sources.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../services/biometric_service.dart';
import '../services/database_service.dart';
import '../services/theme_controller.dart';

class SettingsScreen extends StatefulWidget {
  final DatabaseService databaseService;
  final ThemeController themeController;

  const SettingsScreen({
    super.key,
    required this.databaseService,
    required this.themeController,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _settingsBoxName = 'app_settings';
  static const String _appLockKey = 'appLockEnabled';

  final BiometricService _biometricService = BiometricService();

  bool _appLockEnabled = false;
  bool _settingsReady = false;
  bool _exporting = false;
  bool _backingUp = false;
  bool _restoring = false;

  @override
  void initState() {
    super.initState();
    _loadAppLockSetting();
  }

  Future<void> _loadAppLockSetting() async {
    try {
      final box = await Hive.openBox(_settingsBoxName);

      if (!mounted) return;

      setState(() {
        _appLockEnabled =
            box.get(_appLockKey, defaultValue: false) as bool;
        _settingsReady = true;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _settingsReady = true;
      });
    }
  }

  Future<void> _toggleAppLock(bool value) async {
    if (!_settingsReady) return;

    final available = await _biometricService.isAvailable();

    if (!mounted) return;

    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Biometric authentication is not available on this device. '
            'Set up fingerprint or face authentication in device settings.',
          ),
        ),
      );
      return;
    }

    final authenticated =
        await _biometricService.authenticate();

    if (!mounted) return;

    if (!authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Authentication failed. App Lock was not changed.',
          ),
        ),
      );
      return;
    }

    try {
      final box = await Hive.openBox(_settingsBoxName);
      await box.put(_appLockKey, value);

      if (!mounted) return;

      setState(() {
        _appLockEnabled = value;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Biometric App Lock enabled.'
                : 'App Lock disabled.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not save the App Lock setting.',
          ),
        ),
      );
    }
  }

  String _themeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System Default';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  void _showThemeDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return AnimatedBuilder(
          animation: widget.themeController,
          builder: (context, child) {
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
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Theme',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _themeOption(
                      context,
                      mode: ThemeMode.system,
                      icon: Icons.brightness_auto_rounded,
                      title: 'System Default',
                      subtitle: 'Follow your device theme',
                    ),
                    _themeOption(
                      context,
                      mode: ThemeMode.light,
                      icon: Icons.light_mode_rounded,
                      title: 'Light',
                      subtitle: 'Use light theme',
                    ),
                    _themeOption(
                      context,
                      mode: ThemeMode.dark,
                      icon: Icons.dark_mode_rounded,
                      title: 'Dark',
                      subtitle: 'Use dark theme',
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _themeOption(
    BuildContext context, {
    required ThemeMode mode,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected =
        widget.themeController.themeMode == mode;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: colorScheme.primary,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: selected
          ? Icon(
              Icons.check_circle_rounded,
              color: colorScheme.primary,
            )
          : null,
      onTap: () {
        widget.themeController.setThemeMode(mode);
        Navigator.of(context).pop();
      },
    );
  }

  void _showCurrencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Currency'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Text(
                  '₹',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                title: Text('Indian Rupee'),
                subtitle: Text('INR'),
                trailing: Icon(
                  Icons.check_circle_rounded,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  void _showComingSoon(
    BuildContext context,
    String title,
    String message,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showDataInfo(BuildContext context) {
    final accountCount =
        widget.databaseService.accounts.length;
    final transactionCount =
        widget.databaseService.transactions.length;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Your Data'),
          content: Text(
            'Accounts: $accountCount\n'
            'Transactions: $transactionCount\n\n'
            'Your data is currently stored locally on this device.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _csvEscape(String value) {
    final escaped = value.replaceAll('"', '""');

    return '"$escaped"';
  }

  String _transactionTypeName(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.transfer:
        return 'Transfer';
    }
  }

  String _categoryName(TransactionModel transaction) {
    if (transaction.type == TransactionType.transfer) {
      return 'Transfer';
    }

    if (transaction.type == TransactionType.income) {
      for (final source in incomeSources) {
        if (source.id == transaction.categoryId) {
          return source.name;
        }
      }

      return 'Other Income';
    }

    for (final category in expenseCategories) {
      if (category.id == transaction.categoryId) {
        return category.name;
      }
    }

    return 'Other';
  }

  Future<void> _exportData() async {
    if (_exporting) return;

    final transactions =
        List<TransactionModel>.from(
      widget.databaseService.transactions,
    );

    if (transactions.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'There are no transactions to export yet.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _exporting = true;
    });

    try {
      transactions.sort(
        (a, b) => b.date.compareTo(a.date),
      );

      final buffer = StringBuffer();

      buffer.writeln(
        'Date,Type,Amount,Category,Source Account,'
        'Destination Account,Note',
      );

      for (final transaction in transactions) {
        final sourceAccount =
            widget.databaseService.getAccount(
          transaction.accountId,
        );

        final destinationAccount =
            transaction.toAccountId == null
                ? null
                : widget.databaseService.getAccount(
                    transaction.toAccountId!,
                  );

        final date =
            transaction.date.toIso8601String();

        final type =
            _transactionTypeName(transaction.type);

        final amount =
            transaction.amount.toStringAsFixed(2);

        final category =
            _categoryName(transaction);

        final source =
            sourceAccount?.name ?? 'Unknown';

        final destination =
            destinationAccount?.name ?? '';

        buffer.writeln(
          '${_csvEscape(date)},'
          '${_csvEscape(type)},'
          '${_csvEscape(amount)},'
          '${_csvEscape(category)},'
          '${_csvEscape(source)},'
          '${_csvEscape(destination)},'
          '${_csvEscape(transaction.note)}',
        );
      }

      final directory =
          await getTemporaryDirectory();

      final file = File(
        '${directory.path}/expense_tracker_export.csv',
      );

      await file.writeAsString(
        buffer.toString(),
        flush: true,
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              file.path,
              mimeType: 'text/csv',
            ),
          ],
          subject: 'Expense Tracker Data',
          text: 'My Expense Tracker transaction export.',
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Transaction data exported successfully.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not export data: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _exporting = false;
        });
      }
    }
  }

  Future<void> _backupData() async {
    if (_backingUp) return;

    if (widget.databaseService.accounts.isEmpty &&
        widget.databaseService.transactions.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'There is no data to back up yet.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _backingUp = true;
    });

    try {
      final backupData = {
        'app': 'Expense Tracker',
        'version': '1.0.0',
        'createdAt': DateTime.now().toIso8601String(),
        'accounts': widget.databaseService.accounts
            .map((account) => account.toMap())
            .toList(),
        'transactions': widget.databaseService.transactions
            .map((transaction) => transaction.toMap())
            .toList(),
      };

      final jsonString = const JsonEncoder.withIndent(
        '  ',
      ).convert(backupData);

      final directory =
          await getTemporaryDirectory();

      final file = File(
        '${directory.path}/expense_tracker_backup.json',
      );

      await file.writeAsString(
        jsonString,
        flush: true,
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              file.path,
              mimeType: 'application/json',
            ),
          ],
          subject: 'Expense Tracker Backup',
          text: 'Expense Tracker backup file.',
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Backup created successfully.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not create backup: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _backingUp = false;
        });
      }
    }
  }

  Future<void> _restoreData() async {
    if (_restoring) return;

   final files = await FilePicker.pickFiles(
  type: FileType.custom,
  allowedExtensions: ['json'],
);

if (files.isEmpty) {
  return;
}
final path = files.first.path;

if (path == null || path.isEmpty) {
  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Could not access the selected backup file.',
      ),
    ),
  );
  return;
}


    final shouldRestore =
        await _showRestoreConfirmation();

    if (!shouldRestore || !mounted) {
      return;
    }

    setState(() {
      _restoring = true;
    });

    try {
      final file = File(path);
      final jsonString = await file.readAsString();

      final decoded = jsonDecode(jsonString);

      if (decoded is! Map) {
        throw const FormatException(
          'Invalid backup format.',
        );
      }

      final backup = Map<String, dynamic>.from(
        decoded,
      );

      final accountsData = backup['accounts'];
      final transactionsData =
          backup['transactions'];

      if (accountsData is! List ||
          transactionsData is! List) {
        throw const FormatException(
          'This file is not a valid Expense Tracker backup.',
        );
      }

      final restoredAccounts = <Account>[];
      final restoredTransactions =
          <TransactionModel>[];

      for (final item in accountsData) {
        if (item is! Map) {
          throw const FormatException(
            'Invalid account data in backup.',
          );
        }

        restoredAccounts.add(
          Account.fromMap(
            Map<String, dynamic>.from(item),
          ),
        );
      }

      for (final item in transactionsData) {
        if (item is! Map) {
          throw const FormatException(
            'Invalid transaction data in backup.',
          );
        }

        restoredTransactions.add(
          TransactionModel.fromMap(
            Map<String, dynamic>.from(item),
          ),
        );
      }

      await _replaceDatabaseData(
        restoredAccounts,
        restoredTransactions,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Backup restored: '
            '${restoredAccounts.length} accounts and '
            '${restoredTransactions.length} transactions.',
          ),
        ),
      );

      setState(() {});
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not restore backup: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _restoring = false;
        });
      }
    }
  }

  Future<void> _replaceDatabaseData(
    List<Account> accounts,
    List<TransactionModel> transactions,
  ) async {
    final accountsBox =
        Hive.box('accounts');
    final transactionsBox =
        Hive.box('transactions');

    await accountsBox.clear();
    await transactionsBox.clear();

    for (final account in accounts) {
      await accountsBox.put(
        account.id,
        account.toMap(),
      );
    }

    for (final transaction in transactions) {
      await transactionsBox.put(
        transaction.id,
        transaction.toMap(),
      );
    }

    await widget.databaseService.init();
  }

  Future<bool> _showRestoreConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Restore Backup?'),
          content: const Text(
            'Restoring a backup will replace your current '
            'accounts and transactions with the data from '
            'the selected backup file.\n\n'
            'Make sure you have a backup of your current '
            'data before continuing.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(true),
              child: const Text('Restore'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Expense Tracker',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          Icons.account_balance_wallet_rounded,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      children: const [
        Text(
          'A simple personal finance app for '
          'managing accounts, income, expenses, '
          'transfers and spending analytics.',
        ),
      ],
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        4,
        20,
        4,
        9,
      ),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),
      ),
    );
  }

  Widget _buildSettingCard(
    BuildContext context,
    List<Widget> children,
  ) {
    return Card(
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 17,
        vertical: 5,
      ),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: colorScheme.primary,
          size: 21,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(subtitle),
      ),
      trailing: trailing ??
          const Icon(
            Icons.chevron_right_rounded,
          ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          32,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary
                        .withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(17),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: colorScheme.onPrimary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expense Tracker',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage your money simply.',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(
                          color: colorScheme.onPrimary
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          _buildSectionTitle(
            context,
            'Appearance',
          ),

          _buildSettingCard(
            context,
            [
              AnimatedBuilder(
                animation: widget.themeController,
                builder: (context, child) {
                  return _buildSettingTile(
                    context,
                    icon: Icons.palette_outlined,
                    title: 'Theme',
                    subtitle: _themeName(
                      widget.themeController.themeMode,
                    ),
                    onTap: () =>
                        _showThemeDialog(context),
                  );
                },
              ),
            ],
          ),

          _buildSectionTitle(
            context,
            'Preferences',
          ),

          _buildSettingCard(
            context,
            [
              _buildSettingTile(
                context,
                icon: Icons.currency_rupee_rounded,
                title: 'Currency',
                subtitle: 'Indian Rupee (INR)',
                onTap: () =>
                    _showCurrencyDialog(context),
              ),
              const Divider(height: 1),
              _buildSettingTile(
                context,
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                subtitle:
                    'Expense reminders and alerts',
                onTap: () => _showComingSoon(
                  context,
                  'Notifications',
                  'Notification controls will be added in a future update.',
                ),
              ),
            ],
          ),

          _buildSectionTitle(
            context,
            'Security',
          ),

          _buildSettingCard(
            context,
            [
              _buildSettingTile(
                context,
                icon: Icons.fingerprint_rounded,
                title: 'Biometric App Lock',
                subtitle: !_settingsReady
                    ? 'Loading security settings...'
                    : _appLockEnabled
                        ? 'Fingerprint or Face authentication enabled'
                        : 'Require biometrics to open the app',
                trailing: Switch(
                  value: _appLockEnabled,
                  onChanged: _settingsReady
                      ? _toggleAppLock
                      : null,
                ),
              ),
            ],
          ),

          _buildSectionTitle(
            context,
            'Data',
          ),

          _buildSettingCard(
            context,
            [
              _buildSettingTile(
                context,
                icon: Icons.storage_outlined,
                title: 'Your Data',
                subtitle:
                    'View your local account and transaction data',
                onTap: () =>
                    _showDataInfo(context),
              ),
              const Divider(height: 1),
              _buildSettingTile(
                context,
                icon: Icons.file_download_outlined,
                title: 'Export Data',
                subtitle: _exporting
                    ? 'Preparing CSV export...'
                    : 'Export your financial records as CSV',
                trailing: _exporting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(
                        Icons.chevron_right_rounded,
                      ),
                onTap:
                    _exporting ? null : _exportData,
              ),
              const Divider(height: 1),
              _buildSettingTile(
                context,
                icon: Icons.backup_outlined,
                title: 'Backup Data',
                subtitle: _backingUp
                    ? 'Creating backup...'
                    : 'Save your accounts and transactions',
                trailing: _backingUp
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(
                        Icons.chevron_right_rounded,
                      ),
                onTap:
                    _backingUp ? null : _backupData,
              ),
              const Divider(height: 1),
              _buildSettingTile(
                context,
                icon: Icons.restore_rounded,
                title: 'Restore Data',
                subtitle: _restoring
                    ? 'Restoring backup...'
                    : 'Restore from a backup file',
                trailing: _restoring
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(
                        Icons.chevron_right_rounded,
                      ),
                onTap:
                    _restoring ? null : _restoreData,
              ),
            ],
          ),

          _buildSectionTitle(
            context,
            'About',
          ),

          _buildSettingCard(
            context,
            [
              _buildSettingTile(
                context,
                icon: Icons.info_outline_rounded,
                title: 'About Expense Tracker',
                subtitle: 'Version 1.0.0',
                onTap: () =>
                    _showAbout(context),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Center(
            child: Text(
              'Expense Tracker • 2026',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface
                    .withValues(alpha: 0.45),
              ),
            ),
          ),
        ],
      ),
    );
  }
}