import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/course_student.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/join_course_viewmodel.dart';
import '../widgets/app_card.dart';
import '../widgets/common.dart';
import '../widgets/detail_app_bar.dart';
import '../widgets/primary_button.dart';

/// "Unirme a un curso" (mockup 23). El código se ve en casillas, pero quien recibe lo
/// que se escribe es un TextField invisible encima: así funciona el teclado y pegar.
class JoinCourseView extends StatelessWidget {
  const JoinCourseView({super.key});

  Future<void> _join(BuildContext context, JoinCourseViewModel vm) async {
    final status = await vm.join();
    if (status == null || !context.mounted) return;
    showAppSnackBar(
      context,
      status == EnrollmentStatus.enrolled
          ? '¡Listo! Ya estás inscrito en el curso.'
          : 'Solicitud enviada. Tu docente debe aceptarla.',
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<JoinCourseViewModel>(context);
    final course = vm.found;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const DetailAppBar(title: 'Unirse a un curso'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.school, size: 34, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 16),
          Text('Unirme a un curso',
              textAlign: TextAlign.center,
              style: AppText.headlineSm.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Ingresa el código que te compartió tu docente',
              textAlign: TextAlign.center, style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 20),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Código del curso', style: AppText.labelMd.copyWith(color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 12),
                Stack(
                  children: [
                    _CodeBoxes(code: vm.formattedCode),
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0,
                        child: TextField(
                          autofocus: true,
                          showCursor: false,
                          autocorrect: false,
                          enableSuggestions: false,
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9-]')),
                            LengthLimitingTextInputFormatter(10),
                          ],
                          onChanged: vm.onTextChanged,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.touch_app_outlined, size: 18, color: AppColors.secondary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text('Toca para escribir con tu teclado',
                          style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (vm.isSearching)
            const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator()))
          else if (course != null)
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(color: AppColors.primaryFixed, borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.menu_book_outlined, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle_outline, size: 16, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text('Curso encontrado',
                                  style: AppText.labelMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(course.fullName, style: AppText.titleMd.copyWith(color: AppColors.onSurface)),
                        Text('${course.teacherName} · ${course.room}',
                            style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                        Text(course.enrollCode,
                            style: AppText.labelMd.copyWith(color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (vm.message != null) ...[
            const SizedBox(height: 4),
            ErrorBanner(vm.message!),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: AppColors.primaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Tu docente comparte este código cuando crea el curso.',
                      style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Unirme',
            trailingIcon: Icons.arrow_forward,
            radius: 16,
            isLoading: vm.isJoining,
            onPressed: course == null ? null : () => _join(context, vm),
          ),
        ],
      ),
    );
  }
}

/// Casillas del código: una por carácter y un guion pequeño. Siempre muestra
/// al menos 7 casillas; Expanded las encoge para que quepan en celulares angostos.
class _CodeBoxes extends StatelessWidget {
  final String code; // "PM2-4X7K" o lo que lleve escrito
  const _CodeBoxes({required this.code});

  @override
  Widget build(BuildContext context) {
    final boxes = <Widget>[];
    var filled = 0;
    for (var i = 0; i < code.length; i++) {
      if (code[i] == '-') {
        boxes.add(Container(
          width: 8,
          height: 3,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          color: AppColors.outlineVariant,
        ));
      } else {
        boxes.add(Expanded(child: _Box(char: code[i])));
        filled++;
      }
    }
    for (var i = filled; i < 7; i++) {
      boxes.add(const Expanded(child: _Box(char: '')));
    }
    return Row(children: boxes);
  }
}

class _Box extends StatelessWidget {
  final String char;
  const _Box({required this.char});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(12)),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(char, style: AppText.titleLg.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
