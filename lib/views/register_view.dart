import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../util/validators.dart';
import '../viewmodels/register_viewmodel.dart';
import 'widgets/app_text_field.dart';
import 'widgets/common.dart';
import 'widgets/primary_button.dart';

// Estilo que comparten todos los campos de esta pantalla.
const _labelColor = AppColors.onSurface;
const _iconColor = AppColors.secondary;
const _radius = 16.0;

/// Crear cuenta de estudiante. La cuenta queda vinculada a este celular.
/// Es StatefulWidget solo por el formulario; el estado está en [RegisterViewModel].
class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _code = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus(); // Cierra el teclado.
    if (!_formKey.currentState!.validate()) return;

    final vm = Provider.of<RegisterViewModel>(context, listen: false);
    final ok = await vm.register(
      fullName: _name.text,
      code: _code.text,
      email: Validators.fullInstitutionalEmail(_email.text),
      password: _password.text,
    );
    if (!mounted || !ok) return;
    Navigator.pushNamedAndRemoveUntil(context, 'verify_email', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<RegisterViewModel>(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(alignment: Alignment.centerLeft, child: CircleBackButton()),
                  const SizedBox(height: 16),
                  Text(
                    'Crear cuenta',
                    style: AppText.headlineLg.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ingresa tus datos institucionales para crear tu cuenta.',
                    style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),
                  const _DeviceNotice(),
                  const SizedBox(height: 24),
                  AppTextField(
                    controller: _name,
                    label: 'Nombre completo',
                    hint: 'Ej. Valeria Gómez Morales',
                    icon: Icons.person_outline,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.name],
                    validator: Validators.fullName,
                    labelColor: _labelColor,
                    iconColor: _iconColor,
                    radius: _radius,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _code,
                    label: 'Código estudiantil',
                    hint: 'Ej. 2024-10842',
                    icon: Icons.badge_outlined,
                    validator: Validators.institutionalCode,
                    labelColor: _labelColor,
                    iconColor: _iconColor,
                    radius: _radius,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _email,
                    label: 'Correo institucional',
                    hint: 'nombre.apellido',
                    icon: Icons.mail_outline,
                    // El dominio va fijo al final: solo se escribe lo que va antes del @.
                    suffixText: '@udla.edu.co',
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.username],
                    validator: Validators.institutionalEmailUser,
                    labelColor: _labelColor,
                    iconColor: _iconColor,
                    radius: _radius,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _password,
                    label: 'Contraseña',
                    hint: 'Mínimo 8 caracteres',
                    icon: Icons.lock_outline,
                    obscureText: vm.obscurePassword,
                    onToggleObscure: vm.togglePasswordVisibility,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: Validators.newPassword,
                    labelColor: _labelColor,
                    iconColor: _iconColor,
                    radius: _radius,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _confirm,
                    label: 'Confirmar contraseña',
                    hint: 'Repite tu contraseña',
                    icon: Icons.lock_reset,
                    obscureText: vm.obscureConfirm,
                    onToggleObscure: vm.toggleConfirmVisibility,
                    textInputAction: TextInputAction.done,
                    validator: (v) => Validators.confirmPassword(v, _password.text),
                    labelColor: _labelColor,
                    iconColor: _iconColor,
                    radius: _radius,
                  ),
                  const SizedBox(height: 12),
                  _TermsCheckbox(
                    value: vm.acceptedTerms,
                    onChanged: vm.isLoading ? null : vm.setAcceptedTerms,
                  ),
                  if (vm.error != null) ...[
                    const SizedBox(height: 12),
                    ErrorBanner(vm.error!),
                  ],
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Registrarme',
                    trailingIcon: Icons.arrow_forward,
                    radius: 16,
                    isLoading: vm.isLoading,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeviceNotice extends StatelessWidget {
  const _DeviceNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryFixed.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.phonelink_lock, size: 22, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dispositivo seguro',
                  style: AppText.titleMd.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tu cuenta quedará vinculada a este dispositivo. '
                  'Solo podrás registrar asistencia desde este celular.',
                  style: AppText.bodySm.copyWith(
                    color: AppColors.onSecondaryFixedVariant,
                    height: 1.6,
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

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: value,
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: value ? AppColors.primaryContainer : AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: value
                    ? const Icon(Icons.check, size: 18, color: AppColors.onPrimary)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    'Acepto los términos y el tratamiento de datos',
                    style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
