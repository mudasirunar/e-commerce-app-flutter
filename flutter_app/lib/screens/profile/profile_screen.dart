import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/delivery_info.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
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
                      'Welcome to Boutique Luxury',
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
            const SizedBox(height: AppTheme.space12),

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
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('System'),
                        icon: Icon(Icons.brightness_auto_outlined, size: 18),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Light'),
                        icon: Icon(Icons.wb_sunny_outlined, size: 18),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Dark'),
                        icon: Icon(Icons.nightlight_outlined, size: 18),
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
      builder: (ctx) => AlertDialog(
        title: Text(current == null ? 'Add Default Address' : 'Edit Default Address'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _handleSignOut(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text('Are you sure you want to sign out from your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () {
              auth.signOut();
              Navigator.of(ctx).pop();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
