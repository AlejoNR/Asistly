import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/profile_viewmodel.dart';
import 'common.dart';
import 'confirm_dialog.dart';

/// Partes que comparten los perfiles del docente y del estudiante (mockup 32).

/// Tarjeta con avatar, nombre, código, correo y un resumen de dos datos.
class ProfileCard extends StatelessWidget {
  final ProfileViewModel vm;
  final List<ProfileStat> stats;

  const ProfileCard({super.key, required this.vm, required this.stats});

  @override
  Widget build(BuildContext context) {
    final user = vm.user;
    final statWidgets = <Widget>[];
    for (final stat in stats) {
      statWidgets.add(Expanded(child: stat));
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 12, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle),
            child: Text(vm.initials,
                style: AppText.headlineLg.copyWith(color: AppColors.onPrimary, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 16),
          Text(user?.fullName ?? '',
              textAlign: TextAlign.center,
              style: AppText.headlineSm.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Código: ${user?.code ?? ''}', style: AppText.bodyMd.copyWith(color: AppColors.onSurface)),
          const SizedBox(height: 4),
          Text(user?.email ?? '',
              textAlign: TextAlign.center, style: AppText.bodyMd.copyWith(color: AppColors.secondary)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: statWidgets),
          ),
        ],
      ),
    );
  }
}

class ProfileStat extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const ProfileStat({super.key, required this.value, required this.label, this.valueColor = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppText.headlineMd.copyWith(color: valueColor, fontWeight: FontWeight.w700)),
        Text(label, textAlign: TextAlign.center, style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
      ],
    );
  }
}

/// Opción del perfil: ícono en un cuadro, título, subtítulo y flecha.
/// Con [danger] se pinta en rojo suave (Cerrar sesión).
class ProfileOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;

  const ProfileOptionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.absent : AppColors.onSurface;
    return Material(
      color: danger ? AppColors.absentContainer : AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: danger ? AppColors.errorContainer : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: danger ? AppColors.absent : AppColors.primaryContainer),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.titleMd.copyWith(color: color)),
                    Text(subtitle,
                        style: AppText.bodySm.copyWith(color: danger ? AppColors.absent : AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
              ?trailing, // El "?" lo agrega solo si no es null
            ],
          ),
        ),
      ),
    );
  }
}

/// Las opciones comunes: "Cambiar contraseña" y "Cerrar sesión", con sus confirmaciones.
class ProfileAccountOptions extends StatelessWidget {
  final ProfileViewModel vm;
  const ProfileAccountOptions({super.key, required this.vm});

  Future<void> _changePassword(BuildContext context) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Cambiar contraseña',
      message: 'Te enviaremos a ${vm.user?.email ?? 'tu correo'} un enlace para crear una contraseña nueva.',
      confirmLabel: 'Enviar enlace',
    );
    if (!ok || !context.mounted) return;
    final error = await vm.sendPasswordChange();
    if (!context.mounted) return;
    showAppSnackBar(context, error ?? 'Listo. Revisa tu correo (también la carpeta de spam).');
  }

  Future<void> _signOut(BuildContext context) async {
    final ok = await showConfirmDialog(
      context,
      title: '¿Cerrar sesión?',
      message: 'Tendrás que volver a ingresar tu correo y contraseña.',
      confirmLabel: 'Cerrar sesión',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    await vm.signOut();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, 'role', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProfileOptionTile(
          icon: Icons.key_outlined,
          title: 'Cambiar contraseña',
          subtitle: 'Actualiza tu clave de acceso',
          trailing: vm.isSendingReset
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.chevron_right, color: AppColors.outline),
          onTap: vm.isSendingReset ? null : () => _changePassword(context),
        ),
        const SizedBox(height: 12),
        ProfileOptionTile(
          icon: Icons.logout,
          title: 'Cerrar sesión',
          subtitle: 'Salir de la cuenta en este equipo',
          danger: true,
          trailing: const Icon(Icons.arrow_forward, color: AppColors.absent),
          onTap: () => _signOut(context),
        ),
      ],
    );
  }
}
