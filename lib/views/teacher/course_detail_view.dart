import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/class_session.dart';
import '../../models/course.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../util/date_format.dart';
import '../../viewmodels/course_detail_viewmodel.dart';
import '../widgets/app_card.dart';
import '../widgets/detail_app_bar.dart';

/// Detalle del curso del docente (mockup 12).
class CourseDetailView extends StatelessWidget {
  const CourseDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<CourseDetailViewModel>(context);
    final course = vm.course;

    if (vm.isLoading || course == null) {
      return const Scaffold(
        appBar: DetailAppBar(title: 'Detalle del curso'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: const DetailAppBar(title: 'Detalle del curso'),
      body: RefreshIndicator(
        onRefresh: vm.load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _HeroCard(course: course, isLive: course.hasActiveSession),
            const SizedBox(height: 12),
            _SummaryCard(course: course, comment: vm.attendanceComment),
            const SizedBox(height: 12),
            _QuickActions(course: course, onReturn: vm.load),
            const SizedBox(height: 16),
            _OfficialListCard(course: course, onReturn: vm.load),
            const SizedBox(height: 16),
            _SessionSettingsCard(vm: vm, course: course),
            const SizedBox(height: 20),
            _StartClassButton(vm: vm, course: course),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text('Clases anteriores',
                      style: AppText.headlineSm.copyWith(color: AppColors.onSurface)),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, 'class_history', arguments: course.id),
                  child: Text('Ver historial',
                      style: AppText.labelLg.copyWith(color: AppColors.primaryContainer)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final session in vm.recentSessions) ...[
              _SessionRow(session: session),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

/// Encabezado azul con foto de fondo, nombre del curso y semestre.
class _HeroCard extends StatelessWidget {
  final Course course;
  final bool isLive;
  const _HeroCard({required this.course, required this.isLive});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/login_hero.jpg', fit: BoxFit.cover),
          ),
          // Capa azul encima de la foto para que el texto se lea bien.
          Positioned.fill(
            child: Container(color: AppColors.primaryContainer.withValues(alpha: 0.85)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.tertiaryFixed,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isLive ? 'Clase en curso' : 'Próxima clase',
                            style: AppText.labelMd.copyWith(color: AppColors.onTertiaryFixed),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Semestre ${course.semester}',
                        style: AppText.labelMd.copyWith(color: AppColors.primaryFixed),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  course.fullName,
                  style: AppText.headlineSm.copyWith(color: AppColors.onPrimary, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Código ${course.enrollCode} · ${course.room}',
                  style: AppText.bodyMd.copyWith(color: AppColors.primaryFixed),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta con el horario, la asistencia promedio y los inscritos.
class _SummaryCard extends StatelessWidget {
  final Course course;
  final String comment;
  const _SummaryCard({required this.course, required this.comment});

  @override
  Widget build(BuildContext context) {
    const dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final scheduleRows = <Widget>[];
    for (final day in course.days) {
      scheduleRows.add(Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryFixed,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.primaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${dayNames[day - 1]} ${course.timeLabel}',
                style: AppText.titleLg.copyWith(color: AppColors.onSurface),
              ),
            ),
            Text(course.room, style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
          ],
        ),
      ));
    }

    return AppCard(
      child: Column(
        children: [
          ...scheduleRows,
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          value: course.averageAttendance / 100,
                          strokeWidth: 5,
                          backgroundColor: AppColors.surfaceContainerHigh,
                          color: AppColors.primaryContainer,
                        ),
                      ),
                      Text(
                        '${course.averageAttendance.round()}%',
                        style: AppText.labelLg.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Asistencia promedio', style: AppText.titleMd.copyWith(color: AppColors.onSurface)),
                      Text(comment, style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.group_outlined, size: 18, color: AppColors.primaryContainer),
                        const SizedBox(width: 4),
                        Text('${course.enrolledCount}',
                            style: AppText.headlineSm.copyWith(color: AppColors.primary)),
                      ],
                    ),
                    Text('Inscritos', style: AppText.labelMd.copyWith(color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Accesos rápidos: Estudiantes (con pendientes), Reporte y Código.
class _QuickActions extends StatelessWidget {
  final Course course;
  final VoidCallback onReturn; // Recarga el detalle al volver
  const _QuickActions({required this.course, required this.onReturn});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            icon: Icons.group_outlined,
            title: 'Estudiantes',
            subtitle: course.pendingCount > 0 ? '${course.pendingCount} pendientes' : 'Ver lista',
            badge: course.pendingCount,
            onTap: () => Navigator.pushNamed(context, 'course_students', arguments: course.id).then((value) => onReturn()),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickAction(
            icon: Icons.bar_chart,
            title: 'Reporte',
            subtitle: 'Ver estadísticas',
            onTap: () => Navigator.pushNamed(context, 'course_report', arguments: course.id),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickAction(
            icon: Icons.key,
            title: 'Código',
            subtitle: course.enrollCode,
            onTap: () => Navigator.pushNamed(context, 'course_created', arguments: course),
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int badge;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 104,
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 26, color: AppColors.primaryContainer),
                  const SizedBox(height: 6),
                  Text(title, style: AppText.labelLg.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w700)),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.labelSm.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Burbuja amarilla con el número de solicitudes pendientes.
        if (badge > 0)
          Positioned(
            top: -8,
            right: 8,
            child: Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.tertiaryFixed, shape: BoxShape.circle),
              child: Text('$badge', style: AppText.labelMd.copyWith(color: AppColors.onTertiaryFixed, fontWeight: FontWeight.w700)),
            ),
          ),
      ],
    );
  }
}

/// Tarjeta "Lista oficial": invita a importarla o muestra que ya está cargada.
class _OfficialListCard extends StatelessWidget {
  final Course course;
  final VoidCallback onReturn;
  const _OfficialListCard({required this.course, required this.onReturn});

  @override
  Widget build(BuildContext context) {
    final loaded = course.officialListCount > 0;
    final importedAt = course.officialListImportedAt;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: loaded ? AppColors.surfaceContainerLowest : const Color(0xFFFFF8E6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: loaded ? AppColors.outlineVariant : AppColors.tertiaryFixed, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: loaded ? AppColors.presentContainer : AppColors.tertiaryFixed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  loaded ? Icons.fact_check_outlined : Icons.upload_file_outlined,
                  color: loaded ? AppColors.present : AppColors.onTertiaryFixed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loaded ? 'Lista oficial cargada' : 'Aún no has importado la lista oficial',
                      style: AppText.titleLg.copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loaded
                          ? '${course.officialListCount} estudiantes'
                              '${importedAt != null ? ' · ${DateFormatEs.short(importedAt)}' : ''}'
                          : 'Súbela para que los estudiantes de la lista se inscriban '
                              'automáticamente al unirse con el código.',
                      style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, 'import_list', arguments: course.id).then((value) => onReturn()),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(48),
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: AppText.labelLg,
            ),
            icon: Icon(loaded ? Icons.sync : Icons.cloud_upload_outlined, size: 20),
            label: Text(loaded ? 'Actualizar lista' : 'Importar lista'),
          ),
        ],
      ),
    );
  }
}

/// "Configuración de la clase": tiempo para registrarse y validar por Bluetooth.
class _SessionSettingsCard extends StatelessWidget {
  final CourseDetailViewModel vm;
  final Course course;
  const _SessionSettingsCard({required this.vm, required this.course});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.tune, color: AppColors.primaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Configuración de la clase',
                    style: AppText.titleLg.copyWith(color: AppColors.onSurface)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('Automático', style: AppText.labelMd.copyWith(color: AppColors.primaryContainer)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingRow(
            icon: Icons.timer_outlined,
            title: 'Ventana de registro',
            subtitle: 'Tiempo para registrarse: ${course.registrationMinutes} min',
            trailing: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => vm.changeRegistrationMinutes(-5),
                    icon: const Icon(Icons.remove, color: AppColors.primary),
                    tooltip: 'Menos tiempo',
                  ),
                  IconButton(
                    onPressed: () => vm.changeRegistrationMinutes(5),
                    icon: const Icon(Icons.add, color: AppColors.primary),
                    tooltip: 'Más tiempo',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _SettingRow(
            icon: Icons.bluetooth_searching,
            title: 'Validar por Bluetooth',
            subtitle: 'Verificar proximidad física al aula',
            trailing: Switch(
              value: course.validateBluetooth,
              onChanged: vm.setValidateBluetooth,
              activeTrackColor: AppColors.primaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SettingRow({required this.icon, required this.title, required this.subtitle, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 22, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.titleMd.copyWith(color: AppColors.onSurface)),
                Text(subtitle, style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

/// Botón amarillo "Iniciar clase". Deshabilitado fuera del horario, con la próxima clase.
class _StartClassButton extends StatelessWidget {
  final CourseDetailViewModel vm;
  final Course course;
  const _StartClassButton({required this.vm, required this.course});

  @override
  Widget build(BuildContext context) {
    // Si ya hay una clase abierta, el botón lleva a la sesión activa.
    final isLive = course.hasActiveSession;
    final enabled = isLive || vm.canStartClass;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 60,
          child: FilledButton(
            onPressed: enabled
                ? () => Navigator.pushNamed(context, 'active_session', arguments: course.id)
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.tertiaryFixedDim,
              foregroundColor: AppColors.onTertiaryFixed,
              disabledBackgroundColor: AppColors.surfaceContainerHighest,
              disabledForegroundColor: AppColors.outline,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              textStyle: AppText.titleMd,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: enabled ? AppColors.onTertiaryFixed : AppColors.outlineVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(isLive ? Icons.visibility : Icons.play_arrow, color: AppColors.tertiaryFixed),
                ),
                const SizedBox(width: 12),
                Text(isLive ? 'Ver clase en curso' : 'Iniciar clase'),
              ],
            ),
          ),
        ),
        if (!enabled) ...[
          const SizedBox(height: 8),
          Text(vm.nextClassLabel, style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
        ],
      ],
    );
  }
}

/// Renglón de una clase anterior: número, fecha, presentes y porcentaje.
class _SessionRow extends StatelessWidget {
  final ClassSession session;
  const _SessionRow({required this.session});

  @override
  Widget build(BuildContext context) {
    final percent = session.attendancePercent.round();
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: () => Navigator.pushNamed(context, 'closed_session', arguments: session),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.event_available_outlined, color: AppColors.primaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Clase #${session.number} · ${DateFormatEs.short(session.date)}',
                  style: AppText.titleMd.copyWith(color: AppColors.onSurface),
                ),
                Text(
                  '${session.presentCount} de ${session.totalCount} alumnos presentes',
                  style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: percent >= 75 ? AppColors.presentContainer : AppColors.absentContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$percent%',
              style: AppText.labelLg.copyWith(color: percent >= 75 ? AppColors.present : AppColors.absent),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: AppColors.outline),
        ],
      ),
    );
  }
}
