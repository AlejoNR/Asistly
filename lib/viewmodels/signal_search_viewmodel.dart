import 'dart:async';

import '../services/bluetooth_service.dart';
import 'base_viewmodel.dart';

/// En qué va la búsqueda de la señal del docente.
enum SignalState { checking, bluetoothOff, searching, detected, failed }

/// ViewModel de "Buscando la señal" (mockup 26) y "Activa el Bluetooth" (mockup 27).
/// La búsqueda está simulada: ver [BluetoothService.searchClassSignal].
class SignalSearchViewModel extends BaseViewModel {
  final BluetoothService _bluetooth;

  SignalSearchViewModel(this._bluetooth) {
    _start();
  }

  SignalState state = SignalState.checking;
  String? error;

  StreamSubscription<bool>? _bluetoothSub;
  bool _failureTaken = false;

  Future<void> _start() async {
    try {
      // Un celular sin Bluetooth no puede pasar este paso: sigue solo con el QR.
      if (!await _bluetooth.isSupported()) {
        state = SignalState.detected;
        notify();
        return;
      }
      if (await _bluetooth.isOn()) {
        await _search();
      } else {
        state = SignalState.bluetoothOff;
        notify();
        // Si lo prende desde el celular (o con el botón), sigue solo.
        _bluetoothSub = _bluetooth.watchIsOn().listen((isOn) {
          if (isOn && state == SignalState.bluetoothOff) _search();
        });
      }
    } catch (e) {
      error = errorMessage(e);
      state = SignalState.bluetoothOff;
      notify();
    }
  }

  Future<void> _search() async {
    state = SignalState.searching;
    error = null;
    notify();
    final found = await _bluetooth.searchClassSignal();
    state = found ? SignalState.detected : SignalState.failed;
    notify();
  }

  /// Botón "Activar Bluetooth".
  Future<void> turnOn() async {
    error = null;
    notify();
    try {
      await _bluetooth.turnOn();
      if (await _bluetooth.isOn() && state == SignalState.bluetoothOff) await _search();
    } catch (e) {
      error = 'No se pudo activar. Actívalo desde los ajustes del celular.';
      notify();
    }
  }

  /// true solo la primera vez: la vista navega una sola vez a la pantalla de error.
  bool takeFailure() {
    if (state != SignalState.failed || _failureTaken) return false;
    _failureTaken = true;
    return true;
  }

  @override
  void dispose() {
    _bluetoothSub?.cancel();
    super.dispose();
  }
}
