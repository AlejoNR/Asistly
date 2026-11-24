import 'dart:typed_data';

import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../util/session_codes.dart';

/// Señal Bluetooth que emite el celular del docente durante la clase
/// (especificación, sección 4). Es un anuncio BLE: no hay conexión ni emparejamiento,
/// el celular solo "grita" unos bytes y los estudiantes cercanos los escuchan.
///
/// Usa `flutter_ble_peripheral` (fijado en la versión 2.x). El código cambia cada
/// 15 s, así que en cada ventana nueva se detiene el anuncio y se vuelve a empezar.
class BleAdvertiser {
  final _peripheral = FlutterBlePeripheral();

  /// Empieza (o cambia) el anuncio con el código Bluetooth vigente.
  /// Devuelve null si quedó emitiendo, o el motivo en español si no se pudo.
  Future<String?> advertise(String sessionId, String bleCode) async {
    try {
      if (!await _peripheral.isSupported) {
        return 'Este celular no puede emitir la señal Bluetooth.';
      }
      // En Android 12 o mayor emitir necesita su propio permiso.
      final permission = await Permission.bluetoothAdvertise.request();
      if (!permission.isGranted) {
        return 'Falta el permiso de Bluetooth para emitir la señal.';
      }
      if (FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on) {
        return 'Activa el Bluetooth para que los estudiantes capten la señal.';
      }

      if (await _peripheral.isAdvertising) await _peripheral.stop();
      await _peripheral.start(
        advertiseData: AdvertiseData(
          manufacturerId: SessionCodes.bleManufacturerId,
          manufacturerData: Uint8List.fromList(SessionCodes.blePayload(sessionId, bleCode)),
        ),
        // Anuncio clásico (no "advertising set"), sin límite de tiempo (timeout 0),
        // sin conexiones y con la potencia alta para cubrir el salón.
        advertiseSettings: AdvertiseSettings(
          advertiseSet: false,
          timeout: 0,
          connectable: false,
          advertiseMode: AdvertiseMode.advertiseModeLowLatency,
          txPowerLevel: AdvertiseTxPower.advertiseTxPowerHigh,
        ),
      );
      return null;
    } catch (e) {
      return 'No se pudo emitir la señal Bluetooth.';
    }
  }

  Future<void> stop() async {
    try {
      if (await _peripheral.isAdvertising) await _peripheral.stop();
    } catch (e) {
      // Si ya no estaba emitiendo, no hay nada que detener.
    }
  }
}
