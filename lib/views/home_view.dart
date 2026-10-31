import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../viewmodels/home_viewmodel.dart';
import 'widgets/primary_button.dart';

/// Home provisional hasta construir los Home de docente y estudiante.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<HomeViewModel>(context);
    final user = vm.user;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, ${user?.firstName ?? ''}',
                style: AppText.headlineLg.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Text(
                '${user?.role.label ?? ''} · ${user?.code ?? ''}\n${user?.email ?? ''}',
                style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const Spacer(),
              PrimaryButton.dark(
                label: 'Cerrar sesión',
                leadingIcon: Icons.logout,
                onPressed: () async {
                  await vm.signOut();
                  if (!context.mounted) return;
                  Navigator.pushNamedAndRemoveUntil(context, 'role', (r) => false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
