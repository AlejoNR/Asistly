import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Bluetooth del celular del estudiante.
///
/// Revisar y prender el Bluetooth es real. La búsqueda de la señal del docente
/// todavía NO: [searchClassSignal] está SIMULADA hasta conectar el BLE real, que
/// necesita dos celulares Android (especificación, sección 11, paso 4). Por eso,
/// mientras tanto, las reglas de Firestore solo validan el QR.
class BluetoothService {
  /// El celular tiene Bluetooth.
  Future<bool> isSupported() => FlutterBluePlus.isSupported;

  /// true si está prendido. El primer estado puede tardar un momento en llegar.
  Future<bool> isOn() async {
    final state = await FlutterBluePlus.adapterState
        .where((state) => state != BluetoothAdapterState.unknown)
        .first
        .timeout(const Duration(seconds: 3), onTimeout: () => BluetoothAdapterState.off);
    return state == BluetoothAdapterState.on;
  }

  /// Avisa cada vez que se prende o se apaga.
  Stream<bool> watchIsOn() {
    return FlutterBluePlus.adapterState.map((state) => state == BluetoothAdapterState.on);
  }

  /// Muestra el diálogo del sistema para prenderlo.
  Future<void> turnOn() => FlutterBluePlus.turnOn();

  /// SIMULADO: siempre encuentra la señal. Devuelve true si la detecta.
  Future<bool> searchClassSignal() async {
    await Future.delayed(const Duration(seconds: 2));
    return true;
  }
}

/// Bluetooth de prueba para el modo demo: empieza apagado para poder ver la
/// pantalla "Activa el Bluetooth", y se prende al tocar el botón.
class FakeBluetoothService implements BluetoothService {
  bool _on = false;

  @override
  Future<bool> isSupported() async => true;

  @override
  Future<bool> isOn() async => _on;

  @override
  Stream<bool> watchIsOn() => const Stream.empty();

  @override
  Future<void> turnOn() async {
    _on = true;
  }

  @override
  Future<bool> searchClassSignal() async {
    await Future.delayed(const Duration(seconds: 2));
    return true;
  }
}
