import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
  final BiometricService _biometricService =
      BiometricService();

  bool _appLockEnabled = false;
  bool _settingsReady = false;

  bool _exporting = false;
  bool _backingUp = false;
  bool _restoring = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final box = Hive.box('app_settings');

    final enabled =
        box.get('appLockEnabled', defaultValue: false) as bool;

    if (!mounted) {
      return;
    }

    setState(() {
      _appLockEnabled = enabled;
      _settingsReady = true;
    });
  }

  String _themeName() {
    switch (widget.themeController.themeMode) {
      case ThemeMode.system:
        return 'System default';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  Future<void> _showThemeDialog() async {
    final selected = await showDialog<ThemeMode>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Choose Theme',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _themeOption(
                context: dialogContext,
                mode: ThemeMode.system,
                title: 'System default',
                subtitle: 'Follow your device theme',
                icon: Icons.brightness_auto_rounded,
              ),
              _themeOption(
                context: dialogContext,
                mode: ThemeMode.light,
                title: 'Light',
                subtitle: 'Bright and clean',
                icon: Icons.light_mode_rounded,
              ),
              _themeOption(
                context: dialogContext,
                mode: ThemeMode.dark,
                title: 'Dark',
                subtitle: 'Easy on the eyes',
                icon: Icons.dark_mode_rounded,
              ),
            ],
          ),
        );
      },
    );

    if (selected == null) {
      return;
    }

    widget.themeController.setThemeMode(selected);
  }

  Widget _themeOption({
    required BuildContext context,
    required ThemeMode mode,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final selected =
        widget.themeController.themeMode == mode;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 2,
      ),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary
              .withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(
          icon,
          color: theme.colorScheme.primary,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(
        selected
            ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked_rounded,
        color: selected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
      onTap: () {
        Navigator.of(context).pop(mode);
      },
    );
  }

  Future<void> _showCurrencyDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Currency',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: _dialogIcon(
                  context,
                  Icons.currency_rupee_rounded,
                ),
                title: const Text(
                  'Indian Rupee',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text('INR • ₹'),
                trailing: Icon(
                  Icons.check_circle_rounded,
                  color:
                      Theme.of(context).colorScheme.primary,
                ),
                onTap: () {
                  Navigator.of(dialogContext).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _dialogIcon(
    BuildContext context,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary
            .withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(
        icon,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Future<void> _showNotificationsInfo() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Notifications',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            'Expense reminders and smart alerts '
            'will be available in a future update.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleAppLock(bool enabled) async {
    if (!_settingsReady) {
      return;
    }

    final box = Hive.box('app_settings');

    if (!enabled) {
      await box.put(
        'appLockEnabled',
        false,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _appLockEnabled = false;
      });

      return;
    }

    final available =
        await _biometricService.isAvailable();

    if (!mounted) {
      return;
    }

    if (!available) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text(
              'Biometrics unavailable',
            ),
            content: const Text(
              'Your device does not have a supported '
              'biometric authentication method available.',
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      return;
    }

    final authenticated =
        await _biometricService.authenticate();

    if (!mounted) {
      return;
    }

    if (!authenticated) {
      return;
    }

    await box.put(
      'appLockEnabled',
      true,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _appLockEnabled = true;
    });
  }

  Future<void> _showDataInfo() async {
    final accounts =
        widget.databaseService.accounts.length;

    final transactions =
        widget.databaseService.transactions.length;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Your Data',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dataRow(
                context,
                Icons.account_balance_rounded,
                'Accounts',
                '$accounts',
              ),
              const SizedBox(height: 12),
              _dataRow(
                context,
                Icons.receipt_long_rounded,
                'Transactions',
                '$transactions',
              ),
              const SizedBox(height: 18),
              Text(
                'Your financial data is stored locally '
                'on this device.',
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  Widget _dataRow(
    BuildContext context,
    IconData icon,
    String title,
    String value,
  ) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary
                .withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Future<void> _exportData() async {
    if (_exporting) {
      return;
    }

    setState(() {
      _exporting = true;
    });

    try {
      final transactions =
          widget.databaseService.transactions;

      final buffer = StringBuffer();

      buffer.writeln(
        'Date,Type,Amount,Account,To Account,Category,Note',
      );

      for (final transaction in transactions) {
        final account =
            widget.databaseService.getAccount(
          transaction.accountId,
        );

        Account? destination;

        if (transaction.toAccountId != null) {
          destination =
              widget.databaseService.getAccount(
            transaction.toAccountId!,
          );
        }

        final type = transaction.type.name;

        final accountName =
            account?.name ?? 'Unknown';

        final destinationName =
            destination?.name ?? '';

        final category =
            transaction.categoryId;

        final note =
            transaction.note.replaceAll(
          '"',
          '""',
        );

        buffer.writeln(
          '"${transaction.date.toIso8601String()}",'
          '"$type",'
          '"${transaction.amount.toStringAsFixed(2)}",'
          '"$accountName",'
          '"$destinationName",'
          '"$category",'
          '"$note"',
        );
      }

      final directory =
          await getTemporaryDirectory();

      final file = File(
        '${directory.path}/expense_tracker_export.csv',
      );

      await file.writeAsString(
        buffer.toString(),
      );

      if (!mounted) {
        return;
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(file.path),
          ],
          text: 'Expense Tracker data export',
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Export failed: $error',
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
    if (_backingUp) {
      return;
    }

    setState(() {
      _backingUp = true;
    });

    try {
      final backup = {
        'app': 'Expense Tracker',
        'version': '1.0.0',
        'createdAt':
            DateTime.now().toIso8601String(),
        'accounts': widget.databaseService.accounts
            .map((account) => account.toMap())
            .toList(),
        'transactions':
            widget.databaseService.transactions
                .map((transaction) =>
                    transaction.toMap())
                .toList(),
      };

      final jsonString =
          const JsonEncoder.withIndent('  ')
              .convert(backup);

      final directory =
          await getTemporaryDirectory();

      final file = File(
        '${directory.path}/expense_tracker_backup.json',
      );

      await file.writeAsString(
        jsonString,
      );

      if (!mounted) {
        return;
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(file.path),
          ],
          text: 'Expense Tracker backup',
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Backup failed: $error',
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
    if (_restoring) {
      return;
    }

    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (!mounted) {
      return;
    }

    if (files.isEmpty) {
      return;
    }

    final path = files.first.path;

    if (path == null || path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not access the selected backup file.',
          ),
        ),
      );

      return;
    }

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Restore Backup?',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            'Restoring this backup will replace your '
            'current accounts and transactions. '
            'This action cannot be undone.',
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
              child: const Text('Restore'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    setState(() {
      _restoring = true;
    });

    try {
      final file = File(path);

      final jsonString =
          await file.readAsString();

      final decoded =
          jsonDecode(jsonString);

      if (decoded is! Map) {
        throw const FormatException(
          'Invalid backup format.',
        );
      }

      final accountsData =
          decoded['accounts'];

      final transactionsData =
          decoded['transactions'];

      if (accountsData is! List ||
          transactionsData is! List) {
        throw const FormatException(
          'Invalid backup file.',
        );
      }

      final accounts = accountsData
          .map(
            (item) => Account.fromMap(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();

      final transactions = transactionsData
          .map(
            (item) => TransactionModel.fromMap(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();

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

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Backup restored successfully.',
          ),
        ),
      );

      setState(() {});
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Restore failed: $error',
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

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Expense Tracker',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .primary
              .withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.account_balance_wallet_rounded,
          color:
              Theme.of(context).colorScheme.primary,
          size: 30,
        ),
      ),
      children: const [
        Text(
          'A simple and modern personal finance '
          'manager built with Flutter.',
        ),
      ],
    );
  }

  Widget _sectionTitle(
    BuildContext context,
    String title,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 10,
      ),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _iconBox({
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }

  Widget _settingsTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
    bool showArrow = true,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        child: Row(
          children: [
            _iconBox(
              icon: icon,
              color: iconColor,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: theme.colorScheme
                          .onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing ??
                (showArrow
                    ? Icon(
                        Icons.chevron_right_rounded,
                        size: 27,
                        color: theme.colorScheme
                            .onSurfaceVariant,
                      )
                    : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  Widget _settingsGroup({
    required BuildContext context,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.outline
              .withValues(alpha: 0.16),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: children,
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 82,
      color: Theme.of(context)
          .colorScheme
          .outline
          .withValues(alpha: 0.12),
    );
  }

  Widget _buildAppHeader(BuildContext context) {
    final theme = Theme.of(context);

    final cardColor =
        theme.brightness == Brightness.dark
            ? const Color(0xFF182235)
            : const Color(0xFF17243A);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color:
                    Colors.white.withValues(alpha: 0.10),
              ),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 31,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Expense Tracker',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Manage your money simply.',
                  style: TextStyle(
                    color: Colors.white.withValues(
                      alpha: 0.68,
                    ),
                    fontSize: 14.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color:
                  Colors.white.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text(
              '1.0.0',
              style: TextStyle(
                color: Colors.white.withValues(
                  alpha: 0.82,
                ),
                fontWeight: FontWeight.w700,
                fontSize: 12,
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

    if (!_settingsReady) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            36,
          ),
          children: [
            _buildAppHeader(context),

            const SizedBox(height: 28),

            _sectionTitle(
              context,
              'Appearance',
            ),

            _settingsGroup(
              context: context,
              children: [
                _settingsTile(
                  context: context,
                  icon: Icons.contrast_rounded,
                  iconColor: const Color(0xFF8B83FF),
                  title: 'Theme',
                  subtitle: _themeName(),
                  onTap: _showThemeDialog,
                ),
              ],
            ),

            const SizedBox(height: 28),

            _sectionTitle(
              context,
              'Preferences',
            ),

            _settingsGroup(
              context: context,
              children: [
                _settingsTile(
                  context: context,
                  icon: Icons.payments_rounded,
                  iconColor: const Color(0xFF43C6AC),
                  title: 'Currency',
                  subtitle: 'Indian Rupee (INR)',
                  onTap: _showCurrencyDialog,
                ),
                _divider(context),
                _settingsTile(
                  context: context,
                  icon:
                      Icons.notifications_active_rounded,
                  iconColor: const Color(0xFFFFB84D),
                  title: 'Notifications',
                  subtitle:
                      'Expense reminders and alerts',
                  onTap: _showNotificationsInfo,
                ),
              ],
            ),

            const SizedBox(height: 28),

            _sectionTitle(
              context,
              'Security',
            ),

            _settingsGroup(
              context: context,
              children: [
                _settingsTile(
                  context: context,
                  icon: Icons.fingerprint_rounded,
                  iconColor: const Color(0xFF6FA8FF),
                  title: 'Biometric App Lock',
                  subtitle:
                      'Require biometrics to open the app',
                  showArrow: false,
                  trailing: Switch.adaptive(
                    value: _appLockEnabled,
                    onChanged: _toggleAppLock,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            _sectionTitle(
              context,
              'Data',
            ),

            _settingsGroup(
              context: context,
              children: [
                _settingsTile(
                  context: context,
                  icon: Icons.storage_rounded,
                  iconColor: const Color(0xFFB58CFF),
                  title: 'Your Data',
                  subtitle:
                      'View your local accounts and transactions',
                  onTap: _showDataInfo,
                ),
                _divider(context),
                _settingsTile(
                  context: context,
                  icon: Icons.ios_share_rounded,
                  iconColor: const Color(0xFF4DB6FF),
                  title: 'Export Data',
                  subtitle:
                      'Export financial records as CSV',
                  onTap:
                      _exporting ? null : _exportData,
                  showArrow: false,
                  trailing: _exporting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2.5,
                          ),
                        )
                      : Icon(
                          Icons.chevron_right_rounded,
                          size: 27,
                          color: theme.colorScheme
                              .onSurfaceVariant,
                        ),
                ),
                _divider(context),
                _settingsTile(
                  context: context,
                  icon: Icons.cloud_upload_rounded,
                  iconColor: const Color(0xFF63C5DA),
                  title: 'Backup Data',
                  subtitle:
                      'Create a JSON backup of your data',
                  onTap:
                      _backingUp ? null : _backupData,
                  showArrow: false,
                  trailing: _backingUp
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2.5,
                          ),
                        )
                      : Icon(
                          Icons.chevron_right_rounded,
                          size: 27,
                          color: theme.colorScheme
                              .onSurfaceVariant,
                        ),
                ),
                _divider(context),
                _settingsTile(
                  context: context,
                  icon: Icons.cloud_download_rounded,
                  iconColor: const Color(0xFF8FA7FF),
                  title: 'Restore Data',
                  subtitle:
                      'Restore accounts and transactions',
                  onTap:
                      _restoring ? null : _restoreData,
                  showArrow: false,
                  trailing: _restoring
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2.5,
                          ),
                        )
                      : Icon(
                          Icons.chevron_right_rounded,
                          size: 27,
                          color: theme.colorScheme
                              .onSurfaceVariant,
                        ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            _sectionTitle(
              context,
              'About',
            ),

            _settingsGroup(
              context: context,
              children: [
                _settingsTile(
                  context: context,
                  icon: Icons.auto_awesome_rounded,
                  iconColor: const Color(0xFFFF8FC7),
                  title: 'About Expense Tracker',
                  subtitle:
                      'Version 1.0.0 • Built with Flutter',
                  onTap: _showAbout,
                ),
              ],
            ),

            const SizedBox(height: 28),

            Center(
              child: Text(
                'Expense Tracker',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.55),
                ),
              ),
            ),

            const SizedBox(height: 4),

            Center(
              child: Text(
                'Manage your money simply.',
                style: TextStyle(
                  fontSize: 11.5,
                  color: theme.colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.40),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}