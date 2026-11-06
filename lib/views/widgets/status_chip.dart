import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Etiqueta redonda de estado: "Presente", "Ausente", "Manual", "Clase en curso"...
class StatusChip extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final Color? dotColor; // Punto a la izquierda (opcional)

  const StatusChip({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.dotColor,
  });

  /// Verde: asistió.
  const StatusChip.present({super.key})
      : label = 'Presente',
        background = AppColors.presentContainer,
        foreground = AppColors.present,
        dotColor = AppColors.presentDot;

  /// Rojo: no asistió.
  const StatusChip.absent({super.key})
      : label = 'Ausente',
        background = AppColors.absentContainer,
        foreground = AppColors.absent,
        dotColor = AppColors.absent;

  /// Gris: la asistencia la marcó el docente a mano.
  const StatusChip.manual({super.key})
      : label = 'Manual',
        background = AppColors.surfaceContainer,
        foreground = AppColors.onSurfaceVariant,
        dotColor = null;

  /// Amarillo: hay una clase abierta ahora.
  const StatusChip.live({super.key})
      : label = 'Clase en curso',
        background = AppColors.tertiaryFixed,
        foreground = AppColors.onTertiaryFixed,
        dotColor = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          // Flexible: si el texto no cabe en un celular angosto, baja de línea en vez de desbordarse.
          Flexible(
            child: Text(
              label,
              style: AppText.labelMd.copyWith(color: foreground, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
