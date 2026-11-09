import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/attendance_error_viewmodel.dart';
import '../../viewmodels/scan_qr_viewmodel.dart';

/// Paso 2: leer el QR con la cámara (mockup 28).
///
/// `mobile_scanner` abre la cámara y avisa en `onDetect` cuando reconoce un código.
/// Es StatefulWidget porque el controlador de la cámara se crea y se cierra con la pantalla.
class ScanQrView extends StatefulWidget {
  const ScanQrView({super.key});

  @override
  State<ScanQrView> createState() => _ScanQrViewState();
}

class _ScanQrViewState extends State<ScanQrView> {
  // noDuplicates: el mismo código solo se avisa una vez, no en cada cuadro de la cámara.
  final _camera = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture, ScanQrViewModel vm) {
    if (capture.barcodes.isEmpty) return;
    final text = capture.barcodes.first.rawValue;
    if (text != null) _submit(text, vm);
  }

  Future<void> _submit(String text, ScanQrViewModel vm) async {
    final result = await vm.onQrRead(text);
    if (!mounted) return;
    if (result == ScanResult.success) {
      Navigator.pushReplacementNamed(context, 'attendance_done', arguments: vm.openClass);
    } else if (result == ScanResult.failed) {
      // Esta pantalla queda debajo de la de error: se detiene la cámara para que no
      // siga leyendo códigos sin que se vea. Devuelve true si tocó "Reintentar".
      await _camera.stop();
      if (!mounted) return;
      final retry = await Navigator.pushNamed(
        context,
        'attendance_error',
        arguments: AttendanceErrorInfo(openClass: vm.openClass, cause: vm.failure),
      );
      if (retry == true && mounted) await _camera.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<ScanQrViewModel>(context);
    final open = vm.openClass;

    // Fondo oscuro: la hora y los íconos de la barra de estado van en claro.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF2F3336),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: open.validateBluetooth
                            ? _DarkPill(dotColor: AppColors.tertiaryFixedDim, text: 'Paso 2 de 2')
                            : const SizedBox(),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.popUntil(context, ModalRoute.withName('student_home')),
                      tooltip: 'Cerrar',
                      icon: const Icon(Icons.close, color: AppColors.onPrimary, size: 28),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (open.validateBluetooth)
                  _DarkPill(
                    icon: Icons.bluetooth_audio,
                    text: 'Señal detectada · ${open.course.room}',
                    background: AppColors.primaryContainer,
                  ),
                const SizedBox(height: 16),
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            MobileScanner(
                              controller: _camera,
                              onDetect: (capture) => _onDetect(capture, vm),
                              errorBuilder: (context, error) => _CameraError(error: error),
                            ),
                            // Cruz central y las cuatro esquinas amarillas del visor.
                            const Center(child: Icon(Icons.add, size: 40, color: AppColors.tertiaryFixedDim)),
                            const _Corner(alignment: Alignment.topLeft),
                            const _Corner(alignment: Alignment.topRight),
                            const _Corner(alignment: Alignment.bottomLeft),
                            const _Corner(alignment: Alignment.bottomRight),
                            if (vm.isSubmitting)
                              Container(
                                color: Colors.black54,
                                child: const Center(
                                  child: CircularProgressIndicator(color: AppColors.tertiaryFixedDim),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  vm.hint ?? 'Apunta al código QR que muestra tu docente',
                  textAlign: TextAlign.center,
                  style: AppText.titleMd.copyWith(
                    color: vm.hint == null ? AppColors.onPrimary : AppColors.tertiaryFixed,
                  ),
                ),
                // Solo en el modo demo: no hay docente que muestre un QR de verdad.
                if (vm.isDemo) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: vm.isSubmitting ? null : () => _submit(vm.demoQrText, vm),
                    child: const Text(
                      'Simular lectura del QR (demo)',
                      style: TextStyle(color: AppColors.tertiaryFixed),
                    ),
                  ),
                  TextButton(
                    onPressed: vm.isSubmitting ? null : () => _submit(vm.demoWrongQrText, vm),
                    child: const Text('Simular QR no válido (demo)', style: TextStyle(color: AppColors.tertiaryFixed)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DarkPill extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color? dotColor;
  final Color background;

  const _DarkPill({required this.text, this.icon, this.dotColor, this.background = const Color(0xFF55595C)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
          ],
          if (icon != null) ...[Icon(icon, size: 18, color: AppColors.tertiaryFixedDim), const SizedBox(width: 8)],
          Flexible(
            child: Text(text, style: AppText.labelLg.copyWith(color: AppColors.onPrimary)),
          ),
        ],
      ),
    );
  }
}

/// Una esquina del visor: un cuadro con solo dos bordes pintados.
class _Corner extends StatelessWidget {
  final Alignment alignment;
  const _Corner({required this.alignment});

  @override
  Widget build(BuildContext context) {
    const line = BorderSide(color: AppColors.tertiaryFixedDim, width: 5);
    return Align(
      alignment: alignment,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          border: Border(
            top: alignment.y < 0 ? line : BorderSide.none,
            bottom: alignment.y > 0 ? line : BorderSide.none,
            left: alignment.x < 0 ? line : BorderSide.none,
            right: alignment.x > 0 ? line : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  final MobileScannerException error;
  const _CameraError({required this.error});

  @override
  Widget build(BuildContext context) {
    final message = error.errorCode == MobileScannerErrorCode.permissionDenied
        ? 'Asistly no tiene permiso para usar la cámara. Actívalo en los ajustes del celular.'
        : 'No se pudo abrir la cámara.';
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppText.bodyMd.copyWith(color: AppColors.onPrimary),
      ),
    );
  }
}
