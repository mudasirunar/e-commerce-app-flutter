import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/delivery_info.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_confirmation_dialog.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../admin/admin_dashboard_screen.dart';
import '../auth/login_screen.dart';

/// Screen allowing customers to review their account details, manage their default
/// shipping destination, toggle System/Light/Dark themes, and access the Admin Portal if authorized.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final profile = auth.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account & Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20, vertical: AppTheme.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Header
            if (auth.isAuthenticated) ...[
              Container(
                padding: const EdgeInsets.all(AppTheme.space20),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceWarm,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                      child: Text(
                        (profile?.displayName.isNotEmpty == true
                                ? profile!.displayName[0]
                                : auth.email.isNotEmpty
                                    ? auth.email[0]
                                    : 'U')
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.space16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  profile?.displayName.isNotEmpty == true
                                      ? profile!.displayName
                                      : 'Customer',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (auth.isAdmin)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'ADMIN',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            auth.email,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.space24),

              // Default Shipping Destination
              _buildDefaultAddressSection(context, profile?.defaultDeliveryInfo, isDark),
              const SizedBox(height: AppTheme.space24),
            ] else ...[
              // Guest header
              Container(
                padding: const EdgeInsets.all(AppTheme.space24),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceWarm,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 48,
                      color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                    ),
                    const SizedBox(height: AppTheme.space16),
                    const Text(
                      'Welcome to E-Commerce App',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppTheme.space8),
                    Text(
                      'Sign in to sync your bag, track past orders, and manage saved delivery addresses.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space20),
                    CustomButton(
                      text: 'Sign In / Register',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.space24),
            ],

            // Appearance & Theme Mode Section
            Text(
              'Appearance & Theme',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceWarm,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: const Text('System'),
                        icon: AnimatedScale(
                          scale: themeProvider.themeMode == ThemeMode.system ? 1.25 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutBack,
                          child: Icon(
                            Icons.brightness_auto_rounded,
                            size: 19,
                            color: themeProvider.themeMode == ThemeMode.system
                                ? (isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB))
                                : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                          ),
                        ),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: const Text('Light'),
                        icon: AnimatedRotation(
                          turns: themeProvider.themeMode == ThemeMode.light ? 0.125 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutBack,
                          child: AnimatedScale(
                            scale: themeProvider.themeMode == ThemeMode.light ? 1.25 : 1.0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutBack,
                            child: Icon(
                              Icons.wb_sunny_rounded,
                              size: 19,
                              color: themeProvider.themeMode == ThemeMode.light
                                  ? const Color(0xFFF59E0B)
                                  : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                            ),
                          ),
                        ),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: const Text('Dark'),
                        icon: AnimatedRotation(
                          turns: themeProvider.themeMode == ThemeMode.dark ? -0.06 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutBack,
                          child: AnimatedScale(
                            scale: themeProvider.themeMode == ThemeMode.dark ? 1.25 : 1.0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutBack,
                            child: Icon(
                              Icons.nightlight_round,
                              size: 19,
                              color: themeProvider.themeMode == ThemeMode.dark
                                  ? const Color(0xFFA78BFA)
                                  : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                            ),
                          ),
                        ),
                      ),
                    ],
                    selected: {themeProvider.themeMode},
                    onSelectionChanged: (newSelection) {
                      themeProvider.setThemeMode(newSelection.first);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space24),

            // Admin Operations Entry (Gated to Admin users only)
            if (auth.isAdmin) ...[
              Text(
                'Store Administration',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
              ),
              const SizedBox(height: AppTheme.space12),

              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceWarm,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(AppTheme.space16),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkAccent.withValues(alpha: 0.2)
                          : AppTheme.lightAccent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.admin_panel_settings_outlined,
                      color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                    ),
                  ),
                  title: const Text('Admin Operations Portal', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Manage stock levels, visibility, and fulfillment.'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppTheme.space24),
            ],

            // Sign out button
            if (auth.isAuthenticated) ...[
              CustomButton(
                text: 'Sign Out',
                variant: ButtonVariant.secondary,
                onPressed: () => _handleSignOut(context, auth),
              ),
              const SizedBox(height: AppTheme.space24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAddressSection(BuildContext context, DeliveryInfo? info, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Default Delivery Address',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
            TextButton(
              onPressed: () => _showEditAddressDialog(context, info),
              child: Text(
                info == null ? 'Add Address' : 'Edit',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space8),
        Container(
          padding: const EdgeInsets.all(AppTheme.space16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceWarm,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
          ),
          child: info == null
              ? Row(
                  children: [
                    Icon(
                      Icons.location_off_outlined,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                    const SizedBox(width: AppTheme.space12),
                    Expanded(
                      child: Text(
                        'No default address saved yet. Save one for faster checkout.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      info.phone,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${info.address}, ${info.city}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  void _showEditAddressDialog(BuildContext context, DeliveryInfo? current) {
    final nameCtrl = TextEditingController(text: current?.fullName ?? '');
    final phoneCtrl = TextEditingController(text: current?.phone ?? '');
    final addressCtrl = TextEditingController(text: current?.address ?? '');
    String city = current?.city ?? 'Karachi';

    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.location_on_outlined,
                        size: 28,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    current == null ? 'Add Delivery Address' : 'Edit Delivery Address',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 19,
                    ),
                  ),
                  const SizedBox(height: 18),
                  CustomTextField(
                    controller: nameCtrl,
                    label: 'Recipient Name',
                    hint: 'Full Name',
                  ),
                  const SizedBox(height: AppTheme.space12),
                  CustomTextField(
                    controller: phoneCtrl,
                    label: 'Mobile Phone',
                    hint: '03001234567',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: AppTheme.space12),
                  CustomTextField(
                    controller: addressCtrl,
                    label: 'Detailed Address',
                    hint: 'House, Street, Area',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 46),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              side: BorderSide(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.18)
                                    : const Color(0xFFD6D3D1),
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : const Color(0xFF44403C),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            onPressed: () async {
                              final newInfo = DeliveryInfo(
                                fullName: nameCtrl.text.trim(),
                                phone: phoneCtrl.text.trim(),
                                address: addressCtrl.text.trim(),
                                city: city,
                              );
                              if (newInfo.isValid) {
                                final auth = context.read<AuthProvider>();
                                await auth.updateDeliveryProfile(
                                  defaultDeliveryInfo: newInfo,
                                );
                                if (ctx.mounted) Navigator.of(ctx).pop();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 46),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              backgroundColor: theme.colorScheme.primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Save',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSignOut(BuildContext context, AuthProvider auth) async {
    final confirmed = await AppConfirmationDialog.show(
      context: context,
      title: 'Sign Out?',
      message: 'Are you sure you want to sign out from your account?',
      icon: Icons.logout_rounded,
      confirmLabel: 'Sign Out',
      cancelLabel: 'Cancel',
      isDestructive: true,
    );

    if (confirmed == true) {
      auth.signOut();
    }
  }
}

