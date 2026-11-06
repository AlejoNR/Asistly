import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/active_session.dart';
import '../../models/student_course.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/student_home_viewmodel.dart';
import '../widgets/app_card.dart';
import '../widgets/initials_avatar.dart';
import '../widgets/load_error.dart';
import '../widgets/primary_button.dart';
import '../widgets/status_chip.dart';

/// Home del estudiante: sin clase (mockup 21) o con clase en curso (mockup 22).
class StudentHomeView extends StatelessWidget {
  const StudentHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<StudentHomeViewModel>(context);
    final open = vm.openClass;

    final children = <Widget>[
      if (open == null) _WelcomeCard(vm: vm) else _PlainGreeting(vm: vm),
      const SizedBox(height: 20),
      if (open == null) _NoClassCard(detail: vm.nextClassLabel) else _LiveClassCard(vm: vm, open: open),
      const SizedBox(height: 24),
      _SectionHeader(count: vm.enrolledCount, onJoin: () => _openJoin(context, vm)),
      const SizedBox(height: 16),
    ];

    if (vm.isLoading) {
      children.add(
        const Padding(padding: EdgeInsets.only(top: 32), child: Center(child: CircularProgressIndicator())),
      );
    } else if (vm.error != null) {
      children.add(LoadError(message: vm.error!, onRetry: vm.load));
    } else if (vm.courses.isEmpty) {
      children.add(_EmptyCourses(onJoin: () => _openJoin(context, vm)));
    } else {
      for (final item in vm.courses) {
        children.add(_StudentCourseCard(item: item, isLive: vm.isLive(item.course.id), onReturn: vm.load));
        children.add(const SizedBox(height: 16));
      }
    }

    return RefreshIndicator(
      onRefresh: vm.load,
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: children),
    );
  }

  void _openJoin(BuildContext context, StudentHomeViewModel vm) {
    Navigator.pushNamed(context, 'join_course').then((value) => vm.load());
  }
}

/// Tarjeta azul de saludo (mockup 21).
class _WelcomeCard extends StatelessWidget {
  final StudentHomeViewModel vm;
  const _WelcomeCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -20,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(color: AppColors.onPrimary.withValues(alpha: 0.07), shape: BoxShape.circle),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vm.todayLabel.toUpperCase(),
                          style: AppText.labelMd.copyWith(color: AppColors.secondaryContainer, letterSpacing: 0.6)),
                      const SizedBox(height: 6),
                      Text('¡Hola, ${vm.greetingName}!',
                          style: AppText.headlineMd.copyWith(color: AppColors.onPrimary, fontWeight: FontWeight.w700)),
                      if (vm.semesterLabel.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(vm.semesterLabel, style: AppText.bodyMd.copyWith(color: AppColors.secondaryContainer)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                InitialsAvatar(
                  initials: vm.initials,
                  size: 64,
                  background: AppColors.secondaryContainer,
                  foreground: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Saludo sencillo cuando hay clase: la protagonista es la tarjeta amarilla (mockup 22).
class _PlainGreeting extends StatelessWidget {
  final StudentHomeViewModel vm;
  const _PlainGreeting({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hola, ${vm.greetingName}',
                style: AppText.headlineMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.secondary),
                const SizedBox(width: 6),
                Text(vm.todayLabel, style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ],
        ),
        if (vm.semesterLabel.isNotEmpty)
          StatusChip(
            label: vm.semesterLabel,
            background: AppColors.surfaceContainerHigh,
            foreground: AppColors.onSurfaceVariant,
            dotColor: AppColors.tertiaryFixedDim,
          ),
      ],
    );
  }
}

/// Botón de escanear apagado o encendido, con el mismo tamaño en todos los estados.
class _ScanButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  const _ScanButton({required this.label, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          iconColor: AppColors.tertiaryFixedDim,
          disabledBackgroundColor: AppColors.surfaceContainerHighest,
          disabledForegroundColor: AppColors.outline,
          disabledIconColor: AppColors.outline,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: AppText.labelLg.copyWith(fontWeight: FontWeight.w700),
        ),
        icon: Icon(icon, size: 24),
        label: Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}

class _NoClassCard extends StatelessWidget {
  final String detail; // "Próxima clase: hoy 14:00 · Lab 3"
  const _NoClassCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(color: AppColors.surfaceContainer, shape: BoxShape.circle),
            child: const Icon(Icons.schedule, size: 30, color: AppColors.secondary),
          ),
          const SizedBox(height: 12),
          Text('No hay clase en curso',
              textAlign: TextAlign.center, style: AppText.titleLg.copyWith(color: AppColors.onSurface)),
          const SizedBox(height: 6),
          Text(
            'Cuando tu docente abra la asistencia aparecerá aquí.${detail.isEmpty ? '' : ' $detail'}',
            textAlign: TextAlign.center,
            style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          const _ScanButton(label: 'Escanear QR de asistencia', icon: Icons.qr_code_scanner, onPressed: null),
        ],
      ),
    );
  }
}

/// Tarjeta amarilla de la clase en curso (mockup 22). El texto sobre amarillo va en azul oscuro.
class _LiveClassCard extends StatelessWidget {
  final StudentHomeViewModel vm;
  final OpenClass open;
  const _LiveClassCard({required this.vm, required this.open});

  void _start(BuildContext context) {
    // Sin "Validar por Bluetooth" se va directo al QR (especificación, sección 4).
    final route = open.validateBluetooth ? 'signal_search' : 'scan_qr';
    Navigator.pushNamed(context, route, arguments: open).then((value) => vm.load());
  }

  @override
  Widget build(BuildContext context) {
    final course = open.course;
    final timeIsUp = vm.timeIsUp(open);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.tertiaryFixedDim,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusChip(
                label: 'CLASE EN CURSO',
                background: AppColors.onTertiaryFixed.withValues(alpha: 0.12),
                foreground: AppColors.primary,
                dotColor: AppColors.primary,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppColors.tertiaryFixed, borderRadius: BorderRadius.circular(999)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, size: 18, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text('Cierra en ${vm.remainingLabel(open)}',
                        style: AppText.labelMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(course.name, style: AppText.headlineSm.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            '${course.room} · ${course.teacherName} · ${course.timeLabel}',
            style: AppText.bodyMd.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 18),
          if (open.alreadyMarked)
            const _ScanButton(label: 'Ya registraste tu asistencia', icon: Icons.check_circle_outline, onPressed: null)
          else if (timeIsUp)
            const _ScanButton(label: 'Se acabó el tiempo para registrarse', icon: Icons.timer_off_outlined, onPressed: null)
          else
            _ScanButton(
              label: 'Escanear QR de asistencia',
              icon: Icons.qr_code_scanner,
              onPressed: () => _start(context),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final int count;
  final VoidCallback onJoin;
  const _SectionHeader({required this.count, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('Mis clases', style: AppText.titleLg.copyWith(color: AppColors.primary)),
            const SizedBox(width: 8),
            Text('($count ${count == 1 ? 'inscrita' : 'inscritas'})',
                style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
          ],
        ),
        OutlinedButton.icon(
          onPressed: onJoin,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryContainer,
            side: const BorderSide(color: AppColors.primaryContainer),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            textStyle: AppText.labelMd.copyWith(fontWeight: FontWeight.w600),
          ),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Unirme a un curso'),
        ),
      ],
    );
  }
}

class _EmptyCourses extends StatelessWidget {
  final VoidCallback onJoin;
  const _EmptyCourses({required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.menu_book_outlined, size: 48, color: AppColors.outline),
          const SizedBox(height: 12),
          Text('Aún no tienes cursos',
              textAlign: TextAlign.center, style: AppText.titleLg.copyWith(color: AppColors.onSurface)),
          const SizedBox(height: 6),
          Text('Pídele el código del curso a tu docente para unirte.',
              textAlign: TextAlign.center, style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 20),
          PrimaryButton(label: 'Unirme a un curso', leadingIcon: Icons.add, onPressed: onJoin, radius: 14),
        ],
      ),
    );
  }
}

class _StudentCourseCard extends StatelessWidget {
  final StudentCourse item;
  final bool isLive;
  final VoidCallback onReturn;
  const _StudentCourseCard({required this.item, required this.isLive, required this.onReturn});

  @override
  Widget build(BuildContext context) {
    final course = item.course;

    return AppCard(
      accentColor: isLive ? AppColors.tertiaryFixedDim : AppColors.primaryContainer,
      // Con la solicitud pendiente todavía no hay detalle que ver.
      onTap: item.isPending
          ? null
          : () => Navigator.pushNamed(context, 'student_course_detail', arguments: course).then((value) => onReturn()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLive) ...[
            const StatusChip(
              label: 'En curso hoy',
              background: AppColors.tertiaryFixed,
              foreground: AppColors.onTertiaryFixed,
              dotColor: AppColors.primary,
            ),
            const SizedBox(height: 8),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(course.name, style: AppText.titleLg.copyWith(color: AppColors.onSurface))),
              if (!item.isPending) ...[
                const SizedBox(width: 8),
                StatusChip(
                  label: item.hasClasses ? '${item.percent}%' : 'Sin clases',
                  background: item.isAtRisk ? AppColors.absentContainer : AppColors.surfaceContainerLow,
                  foreground: item.isAtRisk ? AppColors.absent : AppColors.primaryContainer,
                  dotColor: item.isAtRisk ? AppColors.absent : AppColors.primaryContainer,
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          _InfoLine(icon: Icons.person_outline, text: course.teacherName),
          const SizedBox(height: 4),
          _InfoLine(icon: Icons.calendar_today_outlined, text: course.scheduleLabel),
          const SizedBox(height: 10),
          if (item.isPending)
            const StatusChip(
              label: 'Pendiente de aprobación del docente',
              background: AppColors.surfaceContainer,
              foreground: AppColors.onSurfaceVariant,
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: item.percent / 100,
                minHeight: 7,
                color: item.isAtRisk ? AppColors.absent : AppColors.primaryContainer,
                backgroundColor: AppColors.surfaceContainer,
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.secondary),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant))),
      ],
    );
  }
}
