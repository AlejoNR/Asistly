import 'package:firebase_auth/firebase_auth.dart';

/// Habla directamente con Firebase Authentication (cuentas y contraseñas).
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<User> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return credential.user!;
  }

  Future<User> createAccount(String email, String password) async {
    final credential =
        await _auth.createUserWithEmailAndPassword(email: email, password: password);
    return credential.user!;
  }

  /// Pide a Firebase los datos frescos del usuario y dice si ya verificó su correo.
  Future<bool> reloadAndCheckVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<void> deleteCurrentUser() async {
    await _auth.currentUser?.delete();
  }

  Future<void> signOut() => _auth.signOut();
}
