import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../util/validators.dart';
import '../viewmodels/forgot_password_viewmodel.dart';
import 'widgets/app_text_field.dart';
import 'widgets/common.dart';
import 'widgets/primary_button.dart';

/// "Recuperar contraseña": pide el correo y envía el enlace para cambiarla.
/// Es StatefulWidget solo por el formulario; el estado está en [ForgotPasswordViewModel].
class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final email = _email.text.trim();
    final vm = Provider.of<ForgotPasswordViewModel>(context, listen: false);
    final ok = await vm.sendReset(email);
    if (!mounted || !ok) return;
    Navigator.pushReplacementNamed(context, 'check_email', arguments: email);
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<ForgotPasswordViewModel>(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1)),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_reset, size: 30, color: AppColors.primary),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Recuperar contraseña',
                      textAlign: TextAlign.center,
                      style: AppText.headlineMd.copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Ingresa tu correo institucional y te enviaremos un enlace '
                      'para crear una nueva contraseña.',
                      textAlign: TextAlign.center,
                      style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 32),
                    AppTextField(
                      controller: _email,
                      label: 'Correo institucional',
                      hint: 'usuario@udla.edu.co',
                      icon: Icons.mail_outline,
                      iconColor: AppColors.outline,
                      labelColor: AppColors.onSurface,
                      fillColor: AppColors.surfaceContainerLow,
                      radius: 16,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.email],
                      validator: Validators.institutionalEmail,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (vm.error != null) ...[
                      const SizedBox(height: 16),
                      ErrorBanner(vm.error!),
                    ],
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Enviar enlace',
                      trailingIcon: Icons.arrow_forward,
                      radius: 16,
                      height: 56,
                      isLoading: vm.isLoading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 32),
                    TextLink(
                      label: 'Volver a iniciar sesión',
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
