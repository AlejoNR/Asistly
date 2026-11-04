import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/official_list.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/import_list_viewmodel.dart';
import '../widgets/app_card.dart';
import '../widgets/common.dart';
import '../widgets/detail_app_bar.dart';
import '../widgets/initials_avatar.dart';
import '../widgets/primary_button.dart';

/// Importar lista oficial de matriculados (mockup 13).
class ImportListView extends StatelessWidget {
  const ImportListView({super.key});

  Future<void> _import(BuildContext context, ImportListViewModel vm) async {
    final total = vm.preview?.validRows.length ?? 0;
    final added = await vm.import();
    if (!context.mounted || added == null) return; // Si falló, el error se ve en la pantalla
    final news = added == 1 ? '1 nuevo' : '$added nuevos';
    showAppSnackBar(context, 'Lista oficial importada: $total estudiantes ($news).');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<ImportListViewModel>(context);
    final course = vm.course;
    final preview = vm.preview;

    return Scaffold(
      appBar: const DetailAppBar(title: 'Importar lista'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          if (course != null)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Tag(icon: Icons.school_outlined, text: '${course.name} · ${course.group}', strong: true),
                _Tag(text: 'Semestre ${course.semester}'),
              ],
            ),
          const SizedBox(height: 8),
          Text(
            'Sube la lista oficial de matriculados. Solo estos estudiantes podrán unirse '
            'directamente al curso.',
            style: AppText.bodyLg.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          _DropZone(isReading: vm.isReading, onTap: vm.pickFile),
          if (vm.error != null) ...[const SizedBox(height: 12), ErrorBanner(vm.error!)],
          const SizedBox(height: 16),
          const _ColumnsInfo(),
          if (preview != null) ...[
            const SizedBox(height: 16),
            _FileSummary(preview: preview, onChange: vm.pickFile),
            const SizedBox(height: 16),
            _PreviewList(rows: vm.previewRows, total: preview.validRows.length),
            if (preview.errorRows.isNotEmpty) ...[
              const SizedBox(height: 16),
              _ErrorRows(errors: preview.errorRows, expanded: vm.showErrors, onToggle: vm.toggleErrors),
            ],
          ],
        ],
      ),
      bottomNavigationBar: preview == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PrimaryButton(
                      label: 'Importar ${preview.validRows.length} estudiantes',
                      leadingIcon: Icons.group_add_outlined,
                      isLoading: vm.isImporting,
                      onPressed: () => _import(context, vm),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancelar y volver',
                        style: AppText.labelLg.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData? icon;
  final String text;
  final bool strong;
  const _Tag({this.icon, required this.text, this.strong = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: strong ? AppColors.primaryFixed : AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 16, color: AppColors.primaryContainer), const SizedBox(width: 6)],
          // Flexible: si el nombre del curso es largo, baja de línea en vez de desbordarse.
          Flexible(
            child: Text(
              text,
              style: AppText.labelLg.copyWith(color: strong ? AppColors.primaryContainer : AppColors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

/// Zona para tocar y elegir el archivo.
class _DropZone extends StatelessWidget {
  final bool isReading;
  final VoidCallback onTap;
  const _DropZone({required this.isReading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isReading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(color: AppColors.primaryFixed, shape: BoxShape.circle),
                child: isReading
                    ? const Padding(padding: EdgeInsets.all(18), child: CircularProgressIndicator(strokeWidth: 2.5))
                    : const Icon(Icons.upload_file_outlined, size: 30, color: AppColors.primaryContainer),
              ),
              const SizedBox(height: 12),
              Text('Toca para seleccionar un archivo', style: AppText.titleLg.copyWith(color: AppColors.onSurface)),
              const SizedBox(height: 2),
              Text(
                'Formatos: .xlsx o .csv (Máx. 5 MB)',
                style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.touch_app_outlined, size: 18, color: AppColors.primaryContainer),
                    const SizedBox(width: 6),
                    Text('Explorar almacenamiento', style: AppText.labelMd.copyWith(color: AppColors.primaryContainer)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Qué columnas toma Asistly del archivo.
class _ColumnsInfo extends StatelessWidget {
  const _ColumnsInfo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // La etiqueta va arriba del texto para que el texto use todo el ancho.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: AppColors.primaryFixed, borderRadius: BorderRadius.circular(6)),
            child: Text('Obligatorio', style: AppText.labelMd.copyWith(color: AppColors.primaryContainer)),
          ),
          const SizedBox(height: 8),
          Text(
            'Usa el reporte de matriculados del sistema académico. Asistly solo toma estas columnas:',
            style: AppText.titleMd.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ColumnChip(icon: Icons.tag, text: 'CODIGOESTUDIANTE'),
              _ColumnChip(icon: Icons.person_outline, text: 'NOMBRECOMPLETO'),
              _ColumnChip(icon: Icons.alternate_email, text: 'MAIL_INST'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.lock_outline, size: 16, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Las demás columnas del archivo se ignoran y no se guardan.',
                  style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ColumnChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ColumnChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppText.labelMd.copyWith(
              color: AppColors.primary,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Archivo elegido con los contadores de válidos y con error.
class _FileSummary extends StatelessWidget {
  final ImportPreview preview;
  final VoidCallback onChange;
  const _FileSummary({required this.preview, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.description_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preview.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.titleMd.copyWith(color: AppColors.onSurface),
                    ),
                    Text(
                      '${preview.fileSize} · Hoja: ${preview.sheetName}',
                      style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onChange,
                child: Text('Cambiar', style: AppText.labelLg.copyWith(color: AppColors.primaryContainer)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _CountBox(
                    icon: Icons.check_circle_outline,
                    title: '${preview.validRows.length} válidos',
                    subtitle: 'Listos para alta',
                    color: AppColors.primary,
                    background: AppColors.surfaceContainer,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CountBox(
                    icon: Icons.error_outline,
                    title: '${preview.errorRows.length} con error',
                    subtitle: 'Requieren revisión',
                    color: AppColors.absent,
                    background: AppColors.absentContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color background;

  const _CountBox({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
      // El ícono va junto al número y el subtítulo debajo a todo lo ancho:
      // así no se corta ("Listos par...") en pantallas angostas.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(title, style: AppText.labelLg.copyWith(color: color)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: AppText.labelSm.copyWith(color: color)),
        ],
      ),
    );
  }
}

/// Vista previa con los primeros 3 estudiantes válidos.
class _PreviewList extends StatelessWidget {
  final List<OfficialListEntry> rows;
  final int total;
  const _PreviewList({required this.rows, required this.total});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Vista previa de estudiantes', style: AppText.titleMd.copyWith(color: AppColors.onSurface)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(999)),
                child: Text(
                  'Primeros ${rows.length}',
                  style: AppText.labelMd.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final row in rows)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  InitialsAvatar(initials: row.initials, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.bodyLg.copyWith(color: AppColors.onSurface),
                        ),
                        Text(row.code, style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                        // Un correo no se debe partir a la mitad: si no cabe, termina en "...".
                        Text(
                          row.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.check, color: AppColors.primaryContainer),
                ],
              ),
            ),
          Text(
            'Mostrando ${rows.length} de $total registros válidos',
            style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

/// Sección roja "Filas con errores", que se puede plegar.
class _ErrorRows extends StatelessWidget {
  final List<ImportRowError> errors;
  final bool expanded;
  final VoidCallback onToggle;

  const _ErrorRows({required this.errors, required this.expanded, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.absentContainer, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.absent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Filas con errores (${errors.length})',
                    style: AppText.titleMd.copyWith(color: AppColors.absent),
                  ),
                ),
                Icon(expanded ? Icons.expand_less : Icons.expand_more, color: AppColors.absent),
              ],
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 12),
            for (final error in errors)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      error.isEmailError ? Icons.mail_lock_outlined : Icons.remove_circle_outline,
                      size: 20,
                      color: AppColors.absent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Fila ${error.row}', style: AppText.labelLg.copyWith(color: AppColors.absent)),
                          Text(error.message, style: AppText.bodySm.copyWith(color: AppColors.absent)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: AppColors.absent),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Estas filas serán ignoradas automáticamente durante la importación.',
                    style: AppText.labelSm.copyWith(color: AppColors.absent),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
