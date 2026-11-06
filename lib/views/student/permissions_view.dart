import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/permissions_viewmodel.dart';
import '../widgets/primary_button.dart';

/// "Antes de empezar" (mockup 08). Los textos del mockup hablan de recordatorios,
/// que no existen en la app: aquí dicen para qué se usa cada permiso.
class PermissionsView extends StatelessWidget {
  final VoidCallback onContinue;
  const PermissionsView({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<PermissionsViewModel>(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          children: [
            Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(color: AppColors.surfaceContainer, shape: BoxShape.circle),
                child: const Icon(Icons.shield_outlined, size: 40, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 16),
            Text('Antes de empezar',
                textAlign: TextAlign.center,
                style: AppText.headlineMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Asistly necesita estos permisos para verificar tu asistencia en el salón.',
                textAlign: TextAlign.center,
                style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 24),
            _PermissionCard(
              icon: Icons.bluetooth_searching,
              title: 'Bluetooth',
              text: 'Para detectar la señal de tu docente en el salón',
              granted: vm.bluetoothGranted,
              onAllow: vm.requestBluetooth,
            ),
            const SizedBox(height: 16),
            _PermissionCard(
              icon: Icons.photo_camera_outlined,
              title: 'Cámara',
              text: 'Para leer el código QR de asistencia',
              granted: vm.cameraGranted,
              onAllow: vm.requestCamera,
            ),
            if (vm.isBlocked) ...[
              const SizedBox(height: 16),
              Text('Negaste un permiso. Para activarlo, ábrelo en los ajustes del celular.',
                  textAlign: TextAlign.center, style: AppText.bodySm.copyWith(color: AppColors.absent)),
              TextButton(onPressed: vm.openSettings, child: const Text('Abrir ajustes')),
            ],
            const SizedBox(height: 32),
            PrimaryButton(label: 'Continuar', trailingIcon: Icons.arrow_forward, onPressed: onContinue, radius: 16),
          ],
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final bool granted;
  final VoidCallback onAllow;

  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.text,
    required this.granted,
    required this.onAllow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(color: AppColors.surfaceContainerLowest, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.titleLg.copyWith(color: AppColors.primary)),
                const SizedBox(height: 2),
                Text(text, style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (granted)
            const Icon(Icons.check_circle, color: AppColors.present, size: 28)
          else
            FilledButton(
              onPressed: onAllow,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: AppText.labelLg,
              ),
              child: const Text('Permitir'),
            ),
        ],
      ),
    );
  }
}
