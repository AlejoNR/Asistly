import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// "● 12 presentes  ● 1 ausente". Baja de línea si no cabe en celulares angostos.
class AttendanceLegend extends StatelessWidget {
  final int present;
  final int absent;

  const AttendanceLegend({super.key, required this.present, required this.absent});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        _Item(color: AppColors.primaryContainer, text: '$present ${present == 1 ? 'presente' : 'presentes'}'),
        _Item(color: AppColors.absent, text: '$absent ${absent == 1 ? 'ausente' : 'ausentes'}'),
      ],
    );
  }
}

class _Item extends StatelessWidget {
  final Color color;
  final String text;
  const _Item({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
      ],
    );
  }
}
