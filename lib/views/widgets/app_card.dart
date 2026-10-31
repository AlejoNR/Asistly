import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Tarjeta blanca con esquinas de 16 px y sombra suave (estilo de los mockups).
///
/// Si se da [accentColor], dibuja una franja de color a la izquierda:
/// azul para los cursos normales, amarilla para la clase en curso.
class AppCard extends StatelessWidget {
  final Widget child;
  final Color? accentColor;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.accentColor,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(padding: padding, child: child);

    if (accentColor != null) {
      content = IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 6, color: accentColor),
            Expanded(child: content),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      // Material + InkWell dan el efecto de toque sin perder las esquinas redondas.
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: content),
      ),
    );
  }
}
