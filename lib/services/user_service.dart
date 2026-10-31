import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

/// Se lanza cuando el celular ya está vinculado a otra cuenta de estudiante.
class DeviceAlreadyLinkedException implements Exception {}

/// Lee y guarda los perfiles en Cloud Firestore.
///
/// Colecciones (en inglés porque AsistlyLogin usa la misma base de datos):
/// - `users/{uid}`: el perfil de cada persona.
/// - `devices/{deviceId}`: reserva cada celular para una sola cuenta de estudiante.
class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<AppUser?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  /// Guarda el perfil. Si es estudiante, también reserva su celular.
  ///
  /// Se hace en una transacción: o se guardan las dos cosas o ninguna.
  /// Así un celular nunca queda vinculado a dos cuentas.
  Future<void> createUser(AppUser user) {
    return _db.runTransaction((transaction) async {
      final deviceId = user.deviceId;
      if (deviceId != null) {
        final deviceRef = _db.collection('devices').doc(deviceId);
        final device = await transaction.get(deviceRef);
        if (device.exists) throw DeviceAlreadyLinkedException();

        transaction.set(deviceRef, {
          'uid': user.uid,
          'linkedAt': FieldValue.serverTimestamp(),
        });
      }
      transaction.set(_db.collection('users').doc(user.uid), user.toFirestore());
    });
  }
}
