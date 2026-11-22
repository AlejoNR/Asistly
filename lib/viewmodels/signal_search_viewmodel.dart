import 'dart:async';

import '../models/active_session.dart';
import '../services/bluetooth_service.dart';
import 'base_viewmodel.dart';

/// En qué va la búsqueda de la señal del docente.
enum SignalState { checking, bluetoothOff, searching, detected, failed }

/// ViewModel de "Buscando la señal" (mockup 26) y "Activa el Bluetooth" (mockup 27).
class SignalSearchViewModel extends BaseViewModel {
  final BluetoothService _bluetooth;
  final OpenClass openClass;

  SignalSearchViewModel(this._bluetooth, this.openClass) {
    _start();
  }

  SignalState state = SignalState.checking;
  String? error;

  /// La señal captada; se le pasa a "Escanear QR" para guardarla con la asistencia.
  SignalCapture? signal;

  StreamSubscription<bool>? _bluetoothSub;
  bool _failureTaken = false;

  Future<void> _start() async {
    try {
      // Un celular sin Bluetooth no puede captar la señal: puede "Informar al docente"
      // desde la pantalla de error, y el docente decide si lo marca a mano.
      if (!await _bluetooth.isSupported()) {
        state = SignalState.failed;
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
    try {
      signal = await _bluetooth.searchClassSignal(openClass.sessionId);
    } catch (e) {
      signal = null; // Por ejemplo, sin permiso de Bluetooth: cuenta como no detectada
    }
    state = signal != null ? SignalState.detected : SignalState.failed;
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

  /// "Reintentar" desde la pantalla de error: busca la señal otra vez.
  Future<void> retry() async {
    _failureTaken = false;
    await _search();
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
