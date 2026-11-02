import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/new_course_viewmodel.dart';
import '../widgets/app_card.dart';
import '../widgets/common.dart';
import '../widgets/detail_app_bar.dart';
import '../widgets/primary_button.dart';

/// Nuevo curso (mockup 10): datos del curso y un horario único para los días elegidos.
class NewCourseView extends StatefulWidget {
  const NewCourseView({super.key});

  @override
  State<NewCourseView> createState() => _NewCourseViewState();
}

class _NewCourseViewState extends State<NewCourseView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _group = TextEditingController();
  final _semester = TextEditingController();
  final _room = TextEditingController(text: 'Aula 101');

  @override
  void dispose() {
    _name.dispose();
    _group.dispose();
    _semester.dispose();
    _room.dispose();
    super.dispose();
  }

  String? _required(String? value, String message) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  Future<void> _pickTime(bool isStart) async {
    final vm = Provider.of<NewCourseViewModel>(context, listen: false);
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? vm.startTime : vm.endTime,
      helpText: isStart ? 'Hora de inicio' : 'Hora de fin',
    );
    if (picked == null) return;
    if (isStart) {
      vm.setStartTime(picked);
    } else {
      vm.setEndTime(picked);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final vm = Provider.of<NewCourseViewModel>(context, listen: false);
    final course = await vm.create(
      name: _name.text,
      group: _group.text,
      semester: _semester.text,
      room: _room.text,
    );
    if (!mounted || course == null) return;
    // Se reemplaza esta pantalla para que "atrás" no vuelva al formulario.
    Navigator.pushReplacementNamed(context, 'course_created', arguments: course);
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<NewCourseViewModel>(context);

    return Scaffold(
      appBar: const DetailAppBar(title: 'Nuevo curso'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Nuevo curso', style: AppText.headlineLg.copyWith(color: AppColors.primary)),
              const SizedBox(height: 4),
              Text(
                'Configura los detalles académicos y el horario semanal de la materia.',
                style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              _LabeledField(
                icon: Icons.menu_book_outlined,
                label: 'Nombre del curso',
                hint: 'Ej. Programación Móvil',
                controller: _name,
                validator: (v) => _required(v, 'Escribe el nombre del curso'),
              ),
              const SizedBox(height: 16),
              _LabeledField(
                icon: Icons.groups_outlined,
                label: 'Grupo',
                hint: 'Ej. Grupo 2',
                controller: _group,
                validator: (v) => _required(v, 'Escribe el grupo'),
              ),
              const SizedBox(height: 16),
              _LabeledField(
                icon: Icons.calendar_today_outlined,
                label: 'Semestre',
                hint: 'Ej. 2026-2',
                controller: _semester,
                validator: (v) => _required(v, 'Escribe el semestre'),
              ),
              const SizedBox(height: 24),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _CardTitle(icon: Icons.date_range_outlined, title: 'Días de clase'),
                    const SizedBox(height: 4),
                    Text(
                      'Selecciona los días asignados en la semana',
                      style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    _DayChips(selected: vm.selectedDays, onToggle: vm.toggleDay),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _CardTitle(icon: Icons.schedule, title: 'Horario'),
                    const SizedBox(height: 4),
                    Text(
                      'Aplica para todos los días seleccionados',
                      style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _TimeBox(
                            label: 'Hora de inicio',
                            value: NewCourseViewModel.formatTime(vm.startTime),
                            onTap: () => _pickTime(true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TimeBox(
                            label: 'Hora de fin',
                            value: NewCourseViewModel.formatTime(vm.endTime),
                            onTap: () => _pickTime(false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SmallLabel(icon: Icons.meeting_room_outlined, text: 'Aula'),
                    const SizedBox(height: 6),
                    _FilledInput(
                      controller: _room,
                      hint: 'Ej. Aula 101',
                      validator: (v) => _required(v, 'Escribe el aula'),
                    ),
                  ],
                ),
              ),
              if (vm.error != null) ...[
                const SizedBox(height: 16),
                ErrorBanner(vm.error!),
              ],
              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Crear curso',
                leadingIcon: Icons.add_circle_outline,
                isLoading: vm.isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Etiqueta azul con ícono y campo gris debajo (estilo del mockup).
class _LabeledField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final TextEditingController controller;
  final FormFieldValidator<String> validator;

  const _LabeledField({
    required this.icon,
    required this.label,
    required this.hint,
    required this.controller,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primaryContainer),
            const SizedBox(width: 6),
            Text(label, style: AppText.titleMd.copyWith(color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 8),
        _FilledInput(controller: controller, hint: hint, validator: validator),
      ],
    );
  }
}

/// Campo de texto gris claro con esquinas redondas.
class _FilledInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final FormFieldValidator<String> validator;

  const _FilledInput({required this.controller, required this.hint, required this.validator});

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    );
    return TextFormField(
      controller: controller,
      validator: validator,
      textCapitalization: TextCapitalization.sentences,
      style: AppText.bodyLg.copyWith(color: AppColors.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppText.bodyLg.copyWith(color: AppColors.onSurfaceVariant),
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.primaryContainer, width: 1.5),
        ),
        errorBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.error)),
        focusedErrorBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _CardTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: AppColors.primaryContainer),
        const SizedBox(width: 8),
        Text(title, style: AppText.titleMd.copyWith(color: AppColors.primary)),
      ],
    );
  }
}

class _SmallLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SmallLabel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(text, style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
      ],
    );
  }
}

/// Fila de botones Lun–Sáb: azul si el día está elegido, gris si no.
class _DayChips extends StatelessWidget {
  final Set<int> selected;
  final ValueChanged<int> onToggle;

  const _DayChips({required this.selected, required this.onToggle});

  static const _labels = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    for (var i = 0; i < _labels.length; i++) {
      final day = i + 1; // 1 = lunes
      final isOn = selected.contains(day);
      if (i > 0) chips.add(const SizedBox(width: 6));
      chips.add(Expanded(
        child: InkWell(
          onTap: () => onToggle(day),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isOn ? AppColors.primaryContainer : AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _labels[i],
              style: AppText.labelLg.copyWith(
                color: isOn ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                fontWeight: isOn ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ));
    }
    return Row(children: chips);
  }
}

/// Caja de hora (08:00) con reloj; al tocarla se abre el selector de hora.
class _TimeBox extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _TimeBox({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SmallLabel(icon: Icons.schedule, text: label),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: AppText.titleLg.copyWith(color: AppColors.onSurface, letterSpacing: 1),
                  ),
                ),
                const Icon(Icons.schedule, size: 20, color: AppColors.onSurface),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
