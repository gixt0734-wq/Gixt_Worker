import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> authenticate() async {
    try {
      final isSupported = await _auth.isDeviceSupported();

      if (!isSupported) {
        return false;
      }

      return await _auth.authenticate(
        localizedReason: 'Confirma tu identidad para continuar',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (e) {
      print('Error biométrico: $e');
      return false;
    }
  }
}