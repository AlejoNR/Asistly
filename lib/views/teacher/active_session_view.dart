import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/active_session.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/active_session_viewmodel.dart';
import '../widgets/app_card.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/detail_app_bar.dart';
import '../widgets/initials_avatar.dart';
import '../widgets/load_error.dart';
import '../widgets/common.dart';

/// Sesión activa del docente (mockup 17): QR que cambia cada 15 s,
/// asistentes en vivo, tiempo restante y cierre de la asistencia.
class ActiveSessionView extends StatelessWidget {
  const ActiveSessionView({super.key});

  Future<void> _confirmClose(BuildContext context, ActiveSessionViewModel vm) async {
    final missing = vm.enrolledCount - vm.presentCount;
    String message;
    if (missing == 0) {
      message = 'Todos los inscritos ya registraron su asistencia.';
    } else if (missing == 1) {
      message = 'El inscrito sin registro quedará como ausente.';
    } else {
      message = 'Los $missing inscritos sin registro quedarán como ausentes.';
    }
    final ok = await showConfirmDialog(
      context,
      title: '¿Cerrar la asistencia?',
      message: message,
      confirmLabel: 'Cerrar asistencia',
    );
    if (ok) vm.closeSession();
  }

  Future<void> _openManual(BuildContext context, ActiveSessionViewModel vm) async {
    final session = vm.session;
    if (session == null) return;
    // Al volver no hace falta recargar: la lista escucha a Firestore en tiempo real.
    await Navigator.pushNamed(context, 'manual_attendance', arguments: session);
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<ActiveSessionViewModel>(context);
    final session = vm.session;

    // Cuando la asistencia se cierra (a mano o sola) se pasa a "Asistencia cerrada".
    final closed = vm.closedSession;
    if (closed != null) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        if (context.mounted && ModalRoute.of(context)!.isCurrent) {
          Navigator.pushReplacementNamed(context, 'closed_session', arguments: closed);
        }
      });
    }

    if (session == null) {
      // No se pudo abrir la clase (por ejemplo, ya se dictó hoy): se explica por qué.
      final error = vm.error;
      return Scaffold(
        appBar: const DetailAppBar(title: 'Sesión activa'),
        body: Center(
          child: error == null
              ? const CircularProgressIndicator()
              : LoadError(message: error, onRetry: () => Navigator.pop(context)),
        ),
      );
    }

    return Scaffold(
      appBar: const DetailAppBar(title: 'Sesión activa'),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _LiveHeader(session: session),
          if (vm.error != null)
            Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), child: ErrorBanner(vm.error!)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                _QrCard(vm: vm, bluetooth: session.course.validateBluetooth),
                const SizedBox(height: 16),
                // IntrinsicHeight + stretch: las dos tarjetas quedan de la misma altura.
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'ASISTENCIA',
                          value: '${vm.presentCount}',
                          suffix: '/${vm.enrolledCount}',
                          footer: '${vm.presentPercent}% del aula',
                          footerColor: AppColors.tertiaryContainer,
                          icon: Icons.groups_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'TIEMPO RESTANTE',
                          value: vm.remainingLabel,
                          footer: 'Cierre automático',
                          footerColor: AppColors.onSurfaceVariant,
                          icon: Icons.timer_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
                if (vm.failReportCount > 0) ...[
                  const SizedBox(height: 16),
                  _FailReportBanner(count: vm.failReportCount, onTap: () => _openManual(context, vm)),
                ],
                const SizedBox(height: 24),
                // El título se parte en dos líneas si hace falta, con el contador al lado.
                // La palabra "Actualizando" solo se muestra si hay espacio (si no, queda el círculo).
                LayoutBuilder(
                  builder: (context, constraints) {
                    final showWord = constraints.maxWidth >= 360;
                    return Row(
                      children: [
                        // Expanded: el título y el contador usan todo el espacio libre
                        // (con Spacer, el espacio vacío se quedaba con la mitad del ancho).
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'Registros recientes',
                                  style: AppText.titleLg.copyWith(color: AppColors.onSurface),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryFixed,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${vm.presentCount}',
                                  style: AppText.labelLg.copyWith(color: AppColors.primaryContainer),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.outline),
                        ),
                        if (showWord) ...[
                          const SizedBox(width: 6),
                          Text('Actualizando', style: AppText.labelMd.copyWith(color: AppColors.primaryContainer)),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      if (vm.recentRecords.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Aún nadie ha registrado asistencia.',
                            style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                        ),
                      for (var i = 0; i < vm.recentRecords.length; i++) ...[
                        if (i > 0) const Divider(height: 1, color: AppColors.surfaceContainer),
                        _RecordRow(record: vm.recentRecords[i], timeAgo: vm.timeAgo(vm.recentRecords[i].markedAt)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: AppColors.surface,
          // LayoutBuilder mide el ancho: si cada botón queda angosto, el ícono va arriba
          // del texto (así "manualmente" no se parte a la mitad); si hay espacio, al lado.
          child: LayoutBuilder(
            builder: (context, constraints) {
              final vertical = (constraints.maxWidth - 12) / 2 < 170;
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.checklist,
                        label: 'Marcar manualmente',
                        background: AppColors.surfaceContainer,
                        foreground: AppColors.primaryContainer,
                        vertical: vertical,
                        onPressed: () => _openManual(context, vm),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.lock_outline,
                        label: 'Cerrar asistencia',
                        background: AppColors.primaryContainer,
                        foreground: AppColors.onPrimary,
                        vertical: vertical,
                        onPressed: vm.isClosing ? null : () => _confirmClose(context, vm),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Botón de la barra inferior. Con [vertical] el ícono va arriba del texto.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final bool vertical;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.vertical,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final text = Text(label, textAlign: TextAlign.center);
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        minimumSize: const Size(0, 56),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: AppText.labelLg,
      ),
      child: vertical
          ? Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 20), const SizedBox(height: 4), text])
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Flexible(child: text),
              ],
            ),
    );
  }
}

/// Encabezado azul: "EN VIVO", aula y nombre del curso.
class _LiveHeader extends StatelessWidget {
  final ActiveSession session;
  const _LiveHeader({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(color: AppColors.absent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                'EN VIVO',
                style: AppText.labelLg.copyWith(color: AppColors.onPrimary, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.meeting_room_outlined, size: 16, color: AppColors.primaryFixed),
                    const SizedBox(width: 4),
                    Text(session.course.room, style: AppText.labelMd.copyWith(color: AppColors.primaryFixed)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            session.course.fullName,
            style: AppText.headlineSm.copyWith(color: AppColors.onPrimary, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.school_outlined, size: 16, color: AppColors.onPrimaryContainer),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Clase #${session.number} · ${session.course.timeLabel}',
                  style: AppText.bodyMd.copyWith(color: AppColors.onPrimaryContainer),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tarjeta con el QR, el estado de la señal y la cuenta de "Se renueva en X s".
class _QrCard extends StatelessWidget {
  final ActiveSessionViewModel vm;
  final bool bluetooth;
  const _QrCard({required this.vm, required this.bluetooth});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(height: 6, color: AppColors.tertiaryFixedDim),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(bluetooth ? Icons.sensors : Icons.qr_code_2, size: 18, color: AppColors.primaryContainer),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          bluetooth ? 'Señal Bluetooth activa' : 'Solo QR (Bluetooth desactivado)',
                          textAlign: TextAlign.center,
                          style: AppText.labelLg.copyWith(color: AppColors.primaryContainer),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.surfaceContainer),
                  ),
                  // QR real generado con qr_flutter; su contenido cambia cada 15 s.
                  child: QrImageView(
                    data: vm.qrData,
                    size: 220,
                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.primary),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        value: vm.secondsToNewCode / 15,
                        strokeWidth: 3,
                        backgroundColor: AppColors.surfaceContainerHigh,
                        color: AppColors.tertiaryFixedDim,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text.rich(
                      TextSpan(
                        text: 'Se renueva en ',
                        children: [
                          TextSpan(
                            text: '${vm.secondsToNewCode} s',
                            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSurface),
                          ),
                        ],
                      ),
                      style: AppText.bodyLg.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Pida a los alumnos escanear desde su aplicación institucional dentro del aula.',
                  textAlign: TextAlign.center,
                  style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? suffix;
  final String footer;
  final Color footerColor;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    this.suffix,
    required this.footer,
    required this.footerColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    // La etiqueta va arriba a todo lo ancho y el ícono junto al número:
    // así "TIEMPO RESTANTE" y "04:52" no se parten en pantallas angostas.
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FittedBox(scaleDown) achica la etiqueta solo si no cabe en una línea.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(label, style: AppText.labelMd.copyWith(color: AppColors.onSurfaceVariant, letterSpacing: 1)),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text.rich(
                    TextSpan(
                      text: value,
                      children: [
                        if (suffix != null)
                          TextSpan(
                            text: suffix,
                            style: AppText.titleMd.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                      ],
                    ),
                    style: AppText.headlineMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(color: AppColors.primaryFixed, shape: BoxShape.circle),
                child: Icon(icon, size: 20, color: AppColors.primaryContainer),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            footer,
            style: AppText.labelMd.copyWith(color: footerColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Aviso amarillo: "2 estudiantes reportaron falla al registrarse · Revisar".
class _FailReportBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _FailReportBanner({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF8E6),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.tertiaryFixed),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.tertiaryContainer),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  count == 1
                      ? '1 estudiante reportó falla al registrarse'
                      : '$count estudiantes reportaron falla al registrarse',
                  style: AppText.bodyMd.copyWith(color: AppColors.onSurface),
                ),
              ),
              Text('Revisar', style: AppText.labelLg.copyWith(color: AppColors.primaryContainer)),
              const Icon(Icons.chevron_right, color: AppColors.primaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renglón de un registro: iniciales, nombre, matrícula, hace cuánto y check.
class _RecordRow extends StatelessWidget {
  final SessionAttendance record;
  final String timeAgo;
  const _RecordRow({required this.record, required this.timeAgo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      // El "hace cuánto" va debajo del check: deja más ancho para el nombre.
      child: Row(
        children: [
          InitialsAvatar(initials: record.initials, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.titleMd.copyWith(color: AppColors.onSurface),
                ),
                Text(
                  record.isManual ? 'Matrícula ${record.code} · Manual' : 'Matrícula ${record.code}',
                  style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(color: AppColors.primaryFixed, shape: BoxShape.circle),
                child: const Icon(Icons.check_circle, size: 20, color: AppColors.primaryContainer),
              ),
              const SizedBox(height: 4),
              Text(timeAgo, style: AppText.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}
