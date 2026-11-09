import '../services/permission_service.dart';
import 'main_viewmodel.dart';

/// Pantalla principal del estudiante: antes de las pestañas revisa si faltan
/// permisos, para mostrar primero "Antes de empezar".
class StudentMainViewModel extends MainViewModel {
  final PermissionService _permissions;

  StudentMainViewModel(super.repo, this._permissions) {
    _check();
  }

  bool isChecking = true;
  bool showPermissions = false;

  Future<void> _check() async {
    try {
      final hasBluetooth = await _permissions.hasBluetooth();
      final hasCamera = await _permissions.hasCamera();
      showPermissions = !hasBluetooth || !hasCamera;
    } catch (e) {
      // Si no se pudo revisar, se sigue: la cámara vuelve a pedirlo al escanear.
      showPermissions = false;
    }
    isChecking = false;
    notify();
  }

  void permissionsDone() {
    showPermissions = false;
    notify();
  }
}
