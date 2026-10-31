import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_role.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../viewmodels/demo_viewmodel.dart';
import 'widgets/primary_button.dart';

/// Pantalla del MODO DEMO (solo desarrollo): elegir con qué rol entrar
/// sin iniciar sesión. Se abre únicamente desde lib/main_demo.dart.
class DemoView extends StatelessWidget {
  const DemoView({super.key});

  void _enter(BuildContext context, UserRole role) {
    final vm = Provider.of<DemoViewModel>(context, listen: false);
    final route = vm.enterAs(role);
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.science_outlined, size: 48, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'Modo demo',
                textAlign: TextAlign.center,
                style: AppText.headlineMd.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Text(
                'Entra sin iniciar sesión, con datos de ejemplo.\n'
                'Solo para revisar las pantallas mientras se desarrollan.',
                textAlign: TextAlign.center,
                style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Entrar como docente',
                leadingIcon: Icons.assignment_ind,
                onPressed: () => _enter(context, UserRole.teacher),
              ),
              const SizedBox(height: 12),
              PrimaryButton.dark(
                label: 'Entrar como estudiante',
                leadingIcon: Icons.person_outline,
                onPressed: () => _enter(context, UserRole.student),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, 'role'),
                child: const Text('Ir al inicio de sesión normal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
