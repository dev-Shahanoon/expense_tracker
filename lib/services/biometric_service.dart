import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();

      return canCheck && supported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      final available = await isAvailable();

      if (!available) {
        return false;
      }

      return await _auth.authenticate(
        localizedReason: 'Authenticate to open your Expense Tracker',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }
}
