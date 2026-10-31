import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import 'primary_button.dart';

/// Perfil provisional (datos + cerrar sesión) hasta construir la pantalla
/// de Perfil del mockup.
class TemporaryProfile extends StatelessWidget {
  final AppUser? user;
  final VoidCallback onSignOut;

  const TemporaryProfile({super.key, required this.user, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user?.fullName ?? '',
            style: AppText.headlineMd.copyWith(color: AppColors.primary),
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
            onPressed: onSignOut,
          ),
        ],
      ),
    );
  }
}
