import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/app_lock_screen.dart';
import 'screens/home_screen.dart';
import 'services/biometric_service.dart';
import 'services/database_service.dart';
import 'services/theme_controller.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final databaseService = DatabaseService();

  await databaseService.init();

  await Hive.openBox('app_settings');

  final themeController = ThemeController();

  runApp(
    ExpenseTrackerApp(
      databaseService: databaseService,
      themeController: themeController,
    ),
  );
}

class ExpenseTrackerApp extends StatelessWidget {
  final DatabaseService databaseService;
  final ThemeController themeController;

  const ExpenseTrackerApp({
    super.key,
    required this.databaseService,
    required this.themeController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Expense Tracker',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeController.themeMode,
          home: AppLockGate(
            databaseService: databaseService,
            themeController: themeController,
          ),
        );
      },
    );
  }
}

class AppLockGate extends StatefulWidget {
  final DatabaseService databaseService;
  final ThemeController themeController;

  const AppLockGate({
    super.key,
    required this.databaseService,
    required this.themeController,
  });

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate>
    with WidgetsBindingObserver {
  static const String _settingsBoxName = 'app_settings';
  static const String _appLockKey = 'appLockEnabled';

  final BiometricService _biometricService =
      BiometricService();

  bool _locked = true;
  bool _checkingLock = true;
  bool _authenticating = false;
  bool _hasStarted = false;

  // Only re-authenticate after the app was actually paused/backgrounded.
  // Do NOT use AppLifecycleState.inactive because the biometric dialog
  // itself can cause the app to become inactive.
  bool _wasBackgrounded = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLockStatus();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool _isAppLockEnabled() {
    if (!Hive.isBoxOpen(_settingsBoxName)) {
      return false;
    }

    final box = Hive.box(_settingsBoxName);

    return box.get(
          _appLockKey,
          defaultValue: false,
        ) ==
        true;
  }

  Future<void> _checkLockStatus() async {
    if (!mounted) {
      return;
    }

    final enabled = _isAppLockEnabled();

    if (!enabled) {
      setState(() {
        _locked = false;
        _checkingLock = false;
      });

      _hasStarted = true;
      return;
    }

    setState(() {
      _locked = true;
      _checkingLock = false;
    });

    await _authenticate();

    _hasStarted = true;
  }

  Future<void> _authenticate() async {
    if (_authenticating || !mounted) {
      return;
    }

    if (!_isAppLockEnabled()) {
      if (mounted) {
        setState(() {
          _locked = false;
        });
      }

      return;
    }

    setState(() {
      _authenticating = true;
      _locked = true;
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
      setState(() {
        _locked = false;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    // IMPORTANT:
    // Do not authenticate on "inactive".
    // Android can enter "inactive" while the biometric
    // authentication dialog is already showing.

    if (state == AppLifecycleState.paused) {
      if (_isAppLockEnabled()) {
        _wasBackgrounded = true;

        if (mounted && !_authenticating) {
          setState(() {
            _locked = true;
          });
        }
      }
    }

    if (state == AppLifecycleState.resumed) {
      if (_hasStarted &&
          _wasBackgrounded &&
          _isAppLockEnabled()) {
        _wasBackgrounded = false;
        _authenticate();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingLock) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_locked) {
      return AppLockScreen(
        onAuthenticated: () {
          if (!mounted) {
            return;
          }

          setState(() {
            _locked = false;
          });
        },
      );
    }

    return HomeScreen(
      databaseService: widget.databaseService,
      themeController: widget.themeController,
    );
  }
}