import 'package:flutter/material.dart';

import '../services/biometric_service.dart';

class AppLockScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const AppLockScreen({super.key, required this.onAuthenticated});

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

    final authenticated = await _biometricService.authenticate();

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final heroColor = isDark
        ? const Color(0xFF182235)
        : const Color(0xFF17243A);

    final secondaryText = colorScheme.onSurface.withValues(alpha: 0.60);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App icon / lock container
                  Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      color: heroColor,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: heroColor.withValues(alpha: 0.18),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.fingerprint_rounded,
                      size: 58,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    'Expense Tracker',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Your finances are protected',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: secondaryText,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Authentication card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.38),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            Icons.lock_outline_rounded,
                            color: colorScheme.primary,
                            size: 23,
                          ),
                        ),

                        const SizedBox(height: 16),

                        const Text(
                          'App Locked',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 7),

                        Text(
                          'Authenticate to access your accounts '
                          'and transactions.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: secondaryText,
                          ),
                        ),

                        const SizedBox(height: 22),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: _authenticating ? null : _authenticate,
                            icon: const Icon(Icons.fingerprint_rounded),
                            label: Text(
                              _authenticating
                                  ? 'Authenticating...'
                                  : 'Unlock App',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Biometric authentication',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface.withValues(alpha: 0.42),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
