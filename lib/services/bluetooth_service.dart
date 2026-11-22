import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/active_session.dart';
import '../util/app_config.dart';
import '../util/session_codes.dart';

/// Bluetooth del celular del estudiante: revisar si está prendido, prenderlo y
/// buscar la señal del docente con `flutter_blue_plus` (especificación, sección 4).
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

  /// Busca la señal que emite el celular del docente para la clase [sessionId].
  ///
  /// Escanea hasta [AppConfig.bleSearchSeconds] segundos. Devuelve la señal en cuanto
  /// llega una de esta clase con intensidad suficiente (estar cerca), o null si no.
  /// El RSSI se compara en el celular: es un filtro de cercanía, no una garantía
  /// (especificación, sección 4). Hay que calibrar [AppConfig.bleMinRssi] en el aula.
  Future<SignalCapture?> searchClassSignal(String sessionId) async {
    // Un Completer es una "promesa" que se cumple a mano: aquí, cuando llega la señal.
    final found = Completer<SignalCapture?>();
    final tag = SessionCodes.bleSessionTag(sessionId);

    final subscription = FlutterBluePlus.onScanResults.listen((results) {
      for (final result in results) {
        final bytes = result.advertisementData.manufacturerData[SessionCodes.bleManufacturerId];
        if (bytes == null) continue;
        final code = SessionCodes.parseBlePayload(sessionId, bytes);
        if (code == null || result.rssi < AppConfig.bleMinRssi) continue;
        if (!found.isCompleted) found.complete(SignalCapture(code: code, rssi: result.rssi));
      }
    });

    try {
      // El filtro deja pasar solo anuncios de Asistly de esta clase (los primeros 4 bytes).
      await FlutterBluePlus.startScan(
        withMsd: [
          MsdFilter(
            SessionCodes.bleManufacturerId,
            data: [0x41, 0x53, tag[0], tag[1], 0, 0, 0, 0],
            mask: [0xFF, 0xFF, 0xFF, 0xFF, 0, 0, 0, 0],
          ),
        ],
        // Repite el mismo aparato: así, si el estudiante se acerca, se ve el RSSI nuevo.
        continuousUpdates: true,
        timeout: Duration(seconds: AppConfig.bleSearchSeconds),
        // Asistly no usa la ubicación (BLUETOOTH_SCAN con neverForLocation): no exige
        // tener prendida la ubicación del celular para buscar la señal.
        androidCheckLocationServices: false,
      );
      // Si se acaba el tiempo del escaneo sin encontrarla, la respuesta es null.
      FlutterBluePlus.isScanning.where((scanning) => !scanning).first.then((_) {
        if (!found.isCompleted) found.complete(null);
      });
      return await found.future;
    } finally {
      await subscription.cancel();
      await FlutterBluePlus.stopScan();
    }
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
  Future<SignalCapture?> searchClassSignal(String sessionId) async {
    await Future.delayed(const Duration(seconds: 2));
    return const SignalCapture(code: 'DEMO0000', rssi: -55);
  }
}
