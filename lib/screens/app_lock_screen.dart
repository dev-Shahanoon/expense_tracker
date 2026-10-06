import 'package:flutter/material.dart';

import '../services/biometric_service.dart';

class AppLockScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const AppLockScreen({
    super.key,
    required this.onAuthenticated,
  });

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final BiometricService _biometricService = BiometricService();

  bool _authenticating = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  Future<void> _authenticate() async {
    if (_authenticating) {
      return;
    }

    setState(() {
      _authenticating = true;
    });

    final authenticated =
        await _biometricService.authenticate();

    if (!mounted) {
      return;
    }

    setState(() {
      _authenticating = false;
    });

    if (authenticated) {
      widget.onAuthenticated();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    Icons.fingerprint_rounded,
                    size: 54,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Expense Tracker Locked',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Authenticate to access your accounts '
                  'and transactions.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                        color: colorScheme.onSurface
                            .withValues(alpha: 0.65),
                      ),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed:
                      _authenticating ? null : _authenticate,
                  icon: const Icon(
                    Icons.fingerprint_rounded,
                  ),
                  label: Text(
                    _authenticating
                        ? 'Authenticating...'
                        : 'Unlock App',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}