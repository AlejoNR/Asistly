import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/active_session.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/attendance_error_viewmodel.dart';
import '../../viewmodels/signal_search_viewmodel.dart';
import '../widgets/primary_button.dart';

/// Paso 1: "Buscando la señal" (mockup 26) o "Activa el Bluetooth" (mockup 27).
class SignalSearchView extends StatelessWidget {
  const SignalSearchView({super.key});

  void _close(BuildContext context) {
    Navigator.popUntil(context, ModalRoute.withName('student_home'));
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<SignalSearchViewModel>(context);
    final open = ModalRoute.of(context)!.settings.arguments as OpenClass;

    // Si no detectó la señal, va a la pantalla de error una sola vez.
    if (vm.takeFailure()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        // Devuelve true si tocó "Reintentar"; si cerró, ya se volvió al Inicio.
        Navigator.pushNamed(
          context,
          'attendance_error',
          arguments: AttendanceErrorInfo(
            openClass: open,
            cause: 'Fuera del rango de cobertura Bluetooth del aula.',
            isSignalError: true,
          ),
        ).then((retry) {
          if (retry == true) vm.retry();
        });
      });
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: vm.state == SignalState.bluetoothOff
            ? _BluetoothOff(open: open, vm: vm, onClose: () => _close(context))
            : _Searching(open: open, vm: vm, onClose: () => _close(context)),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _CloseButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      tooltip: 'Cerrar',
      style: IconButton.styleFrom(backgroundColor: AppColors.surfaceContainer, foregroundColor: AppColors.onSurface),
      icon: const Icon(Icons.close),
    );
  }
}

class _Searching extends StatelessWidget {
  final OpenClass open;
  final SignalSearchViewModel vm;
  final VoidCallback onClose;
  const _Searching({required this.open, required this.vm, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final detected = vm.state == SignalState.detected;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            _CloseButton(onPressed: onClose),
            Expanded(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(999)),
                  child: Text('PASO 1 DE 2',
                      style: AppText.labelMd.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
            const SizedBox(width: 48), // Compensa el botón de cerrar para centrar el paso
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(999)),
            child: Text('${open.course.name} · ${open.course.room}',
                textAlign: TextAlign.center,
                style: AppText.labelLg.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 16),
        _Radar(detected: detected),
        const SizedBox(height: 16),
        Text(detected ? '¡Señal detectada!' : 'Buscando la señal del docente…',
            textAlign: TextAlign.center,
            style: AppText.headlineSm.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Mantente dentro del salón con el Bluetooth activado',
            textAlign: TextAlign.center, style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(20)),
          child: Column(
            children: [
              const _StatusRow(icon: Icons.bluetooth, title: 'Bluetooth activado', done: true),
              const SizedBox(height: 10),
              _StatusRow(
                icon: Icons.settings_input_antenna,
                title: 'Señal de la clase',
                subtitle: detected ? 'Detectada' : 'Buscando…',
                done: detected,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton.dark(
          label: 'Escanear código QR',
          leadingIcon: Icons.qr_code_scanner,
          radius: 16,
          onPressed: detected ? () => Navigator.pushNamed(context, 'scan_qr', arguments: open) : null,
        ),
        const SizedBox(height: 8),
        if (!detected)
          Text('Disponible una vez detectada la señal del aula',
              textAlign: TextAlign.center, style: AppText.bodySm.copyWith(color: AppColors.outline)),
      ],
    );
  }
}

/// Círculos concéntricos; el del centro late mientras busca.
class _Radar extends StatefulWidget {
  final bool detected;
  const _Radar({required this.detected});

  @override
  State<_Radar> createState() => _RadarState();
}

class _RadarState extends State<_Radar> with SingleTickerProviderStateMixin {
  // Las animaciones sí van en un StatefulWidget: son cosa de la pantalla, no de la lógica.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _circle(186, AppColors.surfaceContainerLow),
          _circle(144, AppColors.surfaceContainer),
          ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.05).animate(_controller),
            child: _circle(100, AppColors.primaryFixed),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle),
            child: Icon(widget.detected ? Icons.check : Icons.bluetooth_searching, color: AppColors.onPrimary, size: 34),
          ),
          // Punto amarillo del mockup, en el borde del círculo central.
          Transform.translate(
            offset: const Offset(28, -28),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.tertiaryFixedDim.withValues(alpha: 0.85),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool done;
  const _StatusRow({required this.icon, required this.title, this.subtitle, required this.done});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: AppColors.surfaceContainer, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.titleMd.copyWith(color: AppColors.onSurface)),
                if (subtitle != null) Text(subtitle!, style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (done)
            const Icon(Icons.check_circle, color: AppColors.primaryContainer)
          else
            const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)),
        ],
      ),
    );
  }
}

class _BluetoothOff extends StatelessWidget {
  final OpenClass open;
  final SignalSearchViewModel vm;
  final VoidCallback onClose;
  const _BluetoothOff({required this.open, required this.vm, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Align(alignment: Alignment.centerRight, child: _CloseButton(onPressed: onClose)),
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 150,
            height: 150,
            decoration: const BoxDecoration(color: AppColors.surfaceContainerLow, shape: BoxShape.circle),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.bluetooth_disabled, size: 64, color: AppColors.primary),
                Positioned(
                  right: 38,
                  bottom: 38,
                  child: Container(
                    decoration: const BoxDecoration(color: AppColors.surfaceContainerLowest, shape: BoxShape.circle),
                    padding: const EdgeInsets.all(3),
                    child: const Icon(Icons.error, size: 22, color: AppColors.error),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Activa el Bluetooth',
            textAlign: TextAlign.center,
            style: AppText.headlineSm.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Lo necesitamos para confirmar que estás en el salón.',
            textAlign: TextAlign.center, style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('VERIFICACIÓN EN TIEMPO REAL',
                  style: AppText.labelMd.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  text: 'Asistly valida tu presencia física detectando la señal inalámbrica emitida por el docente en ',
                  children: [
                    TextSpan(text: open.course.room, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const TextSpan(text: '.'),
                  ],
                ),
                style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        if (vm.error != null) ...[
          const SizedBox(height: 12),
          Text(vm.error!, textAlign: TextAlign.center, style: AppText.bodySm.copyWith(color: AppColors.absent)),
        ],
        const SizedBox(height: 32),
        PrimaryButton(label: 'Activar Bluetooth', leadingIcon: Icons.bluetooth, radius: 16, onPressed: vm.turnOn),
        const SizedBox(height: 8),
        TextButton(onPressed: onClose, child: const Text('Cancelar')),
      ],
    );
  }
}
