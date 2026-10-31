import 'package:cloud_functions/cloud_functions.dart';

/// Pide a las Cloud Functions que envíen los correos de verificación y de
/// recuperación con la plantilla de Asistly (salen desde asistlyapp@gmail.com).
class EmailService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  Future<void> sendVerification() async {
    await _functions.httpsCallable('sendVerificationEmail').call();
  }

  Future<void> sendPasswordReset(String email) async {
    await _functions.httpsCallable('sendPasswordResetEmail').call({'email': email});
  }
}
