import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_address.dart';
import '../../providers/address_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/phone_formatter.dart';
import '../../widgets/common/app_confirmation_dialog.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/state_views.dart';

/// Dedicated screen for managing saved delivery destinations, creating new addresses,
/// choosing the default shipping address, and editing/deleting existing entries.
class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final addressProvider = context.watch<AddressProvider>();
    final addresses = addressProvider.addresses;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Delivery Addresses'),
            if (addresses.isNotEmpty)
              Text(
                '${addresses.length} of ${AddressProvider.maxAddresses} saved',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
          ],
        ),
        actions: [
          if (addresses.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Icon(
                  Icons.add_rounded,
                  color: addressProvider.canAddAddress
                      ? null
                      : (isDark ? AppTheme.darkTextSecondary.withValues(alpha: 0.4) : AppTheme.lightTextSecondary.withValues(alpha: 0.4)),
                ),
                tooltip: addressProvider.canAddAddress ? 'Add Address' : 'Max 5 Addresses Saved',
                onPressed: () => _openAddressSheet(context),
              ),
            ),
        ],
      ),
      body: addressProvider.isLoading && addresses.isEmpty
          ? const LoadingView(message: 'Loading addresses...')
          : addresses.isEmpty
          ? EmptyView(
              icon: Icons.location_off_outlined,
              title: 'No Addresses Saved',
              subtitle:
                  'Add a delivery address to speed up your checkout process and enable auto-fill.',
              actionText: 'Add New Address',
              onAction: () => _openAddressSheet(context),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space20,
                vertical: AppTheme.space20,
              ),
              itemCount: addresses.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppTheme.space16),
              itemBuilder: (ctx, index) {
                final addr = addresses[index];
                return _buildAddressCard(context, addr, isDark);
              },
            ),
      bottomNavigationBar: addresses.isNotEmpty
          ? Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  ),
                ),
              ),
              child: SafeArea(
                child: addressProvider.canAddAddress
                    ? CustomButton(
                        text: 'Add New Address',
                        icon: Icons.add_rounded,
                        onPressed: () => _openAddressSheet(context),
                      )
                    : InkWell(
                        onTap: () => _openAddressSheet(context),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF27272A) : const Color(0xFFF4EFEA),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                size: 16,
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Address Book Full (5 of 5 Saved)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            )
          : null,
    );
  }

  Widget _buildAddressCard(BuildContext context, UserAddress address, bool isDark) {
    final provider = context.read<AddressProvider>();

    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: address.isDefault
              ? (isDark ? AppTheme.darkAccent : AppTheme.lightAccent)
              : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
          width: address.isDefault ? 1.6 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : const Color(0xFFC2410C).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Label pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF3F3F46).withValues(alpha: 0.4)
                      : const Color(0xFFF4EFEA),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getLabelIcon(address.label),
                      size: 13,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      address.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Default badge
              if (address.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkAccentContainer : AppTheme.lightAccentContainer,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 12,
                        color: isDark ? AppTheme.darkOnAccentContainer : AppTheme.lightOnAccentContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'DEFAULT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppTheme.darkOnAccentContainer : AppTheme.lightOnAccentContainer,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

              const Spacer(),

              // Edit Action
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 19),
                tooltip: 'Edit Address',
                visualDensity: VisualDensity.compact,
                onPressed: () => _openAddressSheet(context, existing: address),
              ),

              // Delete Action
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 19),
                tooltip: 'Delete Address',
                visualDensity: VisualDensity.compact,
                color: Colors.redAccent,
                onPressed: () => _confirmDeleteAddress(context, address),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),

          // Recipient & phone
          Text(
            address.fullName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            address.formattedPhone,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 6),

          // Address & City
          Text(
            '${address.address}, ${address.city}',
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
          ),

          // Action to set as default if not already
          if (!address.isDefault) ...[
            const SizedBox(height: AppTheme.space12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                label: const Text('Set as Default'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                onPressed: () async {
                  final ok = await provider.setDefault(address.id);
                  if (ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Default delivery address updated.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getLabelIcon(String label) {
    switch (label.toLowerCase()) {
      case 'work':
      case 'office':
        return Icons.work_outline_rounded;
      case 'home':
        return Icons.home_outlined;
      default:
        return Icons.location_on_outlined;
    }
  }

  Future<void> _confirmDeleteAddress(BuildContext context, UserAddress address) async {
    final confirmed = await AppConfirmationDialog.show(
      context: context,
      title: 'Delete Address?',
      message: 'Are you sure you want to remove "${address.label} - ${address.address}" from your saved addresses?',
      icon: Icons.delete_outline_rounded,
      confirmLabel: 'Delete',
      cancelLabel: 'Keep',
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      await context.read<AddressProvider>().deleteAddress(address.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address deleted.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _openAddressSheet(BuildContext context, {UserAddress? existing}) {
    final addressProvider = context.read<AddressProvider>();
    if (existing == null && !addressProvider.canAddAddress) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Maximum of 5 saved addresses reached. Please edit or delete an existing address.',
          ),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _AddressFormSheet(existing: existing),
    );
  }
}

class _AddressFormSheet extends StatefulWidget {
  final UserAddress? existing;

  const _AddressFormSheet({this.existing});

  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _label;
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late bool _isDefault;
  bool _isSaving = false;

  final List<String> _labels = ['Home', 'Work', 'Other'];

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    _label = item?.label ?? 'Home';
    _nameController = TextEditingController(text: item?.fullName ?? '');
    _phoneController = TextEditingController(
      text: item != null ? PhoneFormatter.formatDisplay(item.phone) : '',
    );
    _addressController = TextEditingController(text: item?.address ?? '');
    _cityController = TextEditingController(text: item?.city ?? 'Karachi');
    _isDefault = item?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final addressProvider = context.watch<AddressProvider>();
    final isOnlyAddress = addressProvider.addresses.isEmpty ||
        (widget.existing != null && addressProvider.addresses.length == 1);

    // If it's the only address, force isDefault to true
    if (isOnlyAddress) {
      _isDefault = true;
    }

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Row(
                children: [
                  Icon(
                    widget.existing == null ? Icons.add_location_alt_outlined : Icons.edit_location_alt_outlined,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.existing == null ? 'Add Delivery Address' : 'Edit Delivery Address',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Address Label selector chips
              Text(
                'Address Type',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Theme(
                data: theme.copyWith(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  splashFactory: NoSplash.splashFactory,
                  hoverColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  chipTheme: theme.chipTheme.copyWith(
                    pressElevation: 0,
                  ),
                ),
                child: Wrap(
                  spacing: 8,
                  children: _labels.map((l) {
                    final isSelected = _label == l;
                    return ChoiceChip(
                      label: Text(l),
                      selected: isSelected,
                      showCheckmark: false,
                      pressElevation: 0,
                      onSelected: (val) {
                        if (val) setState(() => _label = l);
                      },
                      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.18),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : (isDark ? Colors.white70 : const Color(0xFF334155)),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Recipient Name
              CustomTextField(
                controller: _nameController,
                label: 'Recipient Full Name',
                hint: 'e.g. Ali Khan',
                validator: (val) {
                  if (val == null || val.trim().length < 2) {
                    return 'Please enter recipient name (at least 2 letters)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.space12),

              // Phone number
              CustomTextField(
                controller: _phoneController,
                label: 'Mobile Phone',
                hint: '0300 1234567',
                keyboardType: TextInputType.phone,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter mobile number';
                  }
                  if (!PhoneFormatter.isValidPakistaniMobile(val)) {
                    return 'Enter valid Pakistani number (e.g. 03001234567)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.space12),

              // Detailed Address
              CustomTextField(
                controller: _addressController,
                label: 'Street / House / Area',
                hint: 'House # 12, Street 4, Sector B...',
                maxLines: 2,
                validator: (val) {
                  if (val == null || val.trim().length < 5) {
                    return 'Please enter detailed delivery address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.space12),

              CustomTextField(
                controller: _cityController,
                label: 'City',
                hint: 'e.g. Karachi, Lahore, Islamabad',
                prefixIcon: Icons.location_city_outlined,
                validator: (val) {
                  if (val == null || val.trim().length < 2) {
                    return 'Please enter city (min 2 characters)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.space12),

              // Default Address switch
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Set as Default Address',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isOnlyAddress
                                ? 'Auto-selected because this is your only address.'
                                : 'Used automatically during checkout.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _isDefault,
                      onChanged: isOnlyAddress
                          ? null
                          : (val) => setState(() => _isDefault = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveAddress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                widget.existing == null ? 'Save Address' : 'Update',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
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
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final provider = context.read<AddressProvider>();

    bool success;
    if (widget.existing != null) {
      success = await provider.updateAddress(
        id: widget.existing!.id,
        label: _label,
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        isDefault: _isDefault,
      );
    } else {
      success = await provider.addAddress(
        label: _label,
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        isDefault: _isDefault,
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existing == null ? 'Address added.' : 'Address updated.'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      final err = provider.errorMessage ?? 'Could not save address. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}
