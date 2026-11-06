import '../services/permission_service.dart';
import 'base_viewmodel.dart';

/// ViewModel de "Antes de empezar" (mockup 08): pide Bluetooth y cámara.
class PermissionsViewModel extends BaseViewModel {
  final PermissionService _service;

  PermissionsViewModel(this._service) {
    _load();
  }

  bool bluetoothGranted = false;
  bool cameraGranted = false;
  bool isBlocked = false; // Se negó para siempre: solo se cambia en los ajustes

  Future<void> _load() async {
    bluetoothGranted = await _service.hasBluetooth();
    cameraGranted = await _service.hasCamera();
    isBlocked = await _service.isBlocked();
    notify();
  }

  Future<void> requestBluetooth() async {
    bluetoothGranted = await _service.requestBluetooth();
    isBlocked = await _service.isBlocked();
    notify();
  }

  Future<void> requestCamera() async {
    cameraGranted = await _service.requestCamera();
    isBlocked = await _service.isBlocked();
    notify();
  }

  Future<void> openSettings() => _service.openSettings();
}
