import 'package:permission_handler/permission_handler.dart';

/// Los dos permisos que pide Asistly: Bluetooth y cámara (especificación, sección 3).
/// `permission_handler` muestra el diálogo del sistema.
class PermissionService {
  // En Android 11 o anterior estos permisos no se piden: el sistema responde "concedido".
  static const _bluetoothPermissions = [Permission.bluetoothScan, Permission.bluetoothConnect];

  Future<bool> hasBluetooth() async {
    for (final permission in _bluetoothPermissions) {
      if (!await permission.isGranted) return false;
    }
    return true;
  }

  Future<bool> hasCamera() => Permission.camera.isGranted;

  /// Devuelve true si quedó concedido.
  Future<bool> requestBluetooth() async {
    final results = await _bluetoothPermissions.request();
    for (final status in results.values) {
      if (!status.isGranted) return false;
    }
    return true;
  }

  Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Si la persona lo negó para siempre, el sistema ya no muestra el diálogo:
  /// solo se puede cambiar en los ajustes del celular.
  Future<bool> isBlocked() async {
    if (await Permission.camera.isPermanentlyDenied) return true;
    for (final permission in _bluetoothPermissions) {
      if (await permission.isPermanentlyDenied) return true;
    }
    return false;
  }

  Future<void> openSettings() => openAppSettings();
}
