import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/delivery_info.dart';
import '../../models/user_address.dart';
import '../../providers/address_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/checkout_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../profile/addresses_screen.dart';
import 'order_confirmed_screen.dart';

/// Screen managing checkout delivery collection, address book selection,
/// Cash on Delivery confirmation, and atomic server-side inventory verification.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController(text: 'Karachi');
  final _notesController = TextEditingController();

  UserAddress? _selectedSavedAddress;
  bool _isCustomOneTime = false;
  bool _saveAsDefault = false;

  // Cached summary state to prevent any 00 or empty layout flash before route transition
  int _lastTotalUnits = 0;
  String _lastFormattedSubtotal = '';
  String _lastFormattedDeliveryFee = '';
  String _lastFormattedTotal = '';
  bool _isNavigatingToConfirmed = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _addressController.addListener(_onFieldChanged);
    _cityController.addListener(_onFieldChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAddressState();
    });
  }

  void _onFieldChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _initializeAddressState() {
    final addressProvider = context.read<AddressProvider>();
    final authProvider = context.read<AuthProvider>();
    final profile = authProvider.userProfile;

    final defaultAddr = addressProvider.defaultAddress;
    if (defaultAddr != null) {
      _applyAddress(defaultAddr);
    } else if (profile?.defaultDeliveryInfo != null) {
      final info = profile!.defaultDeliveryInfo!;
      _nameController.text = info.fullName;
      _phoneController.text = info.phone;
      _addressController.text = info.address;
      _cityController.text = info.city.isNotEmpty ? info.city : 'Karachi';
      _selectedSavedAddress = null;
      _isCustomOneTime = false;
    } else if (profile != null && profile.displayName.isNotEmpty) {
      _nameController.text = profile.displayName;
      _selectedSavedAddress = null;
      _isCustomOneTime = false;
    }
    setState(() {});
  }

  void _applyAddress(UserAddress address) {
    _selectedSavedAddress = address;
    _isCustomOneTime = false;
    _saveAsDefault = false;
    _nameController.text = address.fullName;
    _phoneController.text = address.phone;
    _addressController.text = address.address;
    _cityController.text = address.city.isNotEmpty ? address.city : 'Karachi';
    setState(() {});
  }

  void _switchToCustomOneTime() {
    setState(() {
      _selectedSavedAddress = null;
      _isCustomOneTime = true;
      _saveAsDefault = false;
    });
  }

  bool get _isEditedFromSavedAddress {
    if (_selectedSavedAddress == null) return false;
    return _nameController.text.trim() != _selectedSavedAddress!.fullName.trim() ||
        _phoneController.text.trim() != _selectedSavedAddress!.phone.trim() ||
        _addressController.text.trim() != _selectedSavedAddress!.address.trim() ||
        _cityController.text.trim() != _selectedSavedAddress!.city.trim();
  }

  bool _shouldShowSaveCheckbox(int savedAddressCount) {
    if (savedAddressCount == 0) return true;

    // If an unmodified saved address is currently selected, hide checkbox
    if (_selectedSavedAddress != null && !_isEditedFromSavedAddress && !_isCustomOneTime) {
      return false;
    }

    // Only show save checkbox if user has space in their address book (< 5)
    return savedAddressCount < AddressProvider.maxAddresses;
  }

  String _getSaveCheckboxTitle(int count) {
    if (count == 0) {
      return 'Save as my default delivery address';
    }
    if (_selectedSavedAddress != null && _isEditedFromSavedAddress) {
      return 'Update saved address with these edited details';
    }
    return 'Save as default in my address book';
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFieldChanged);
    _phoneController.removeListener(_onFieldChanged);
    _addressController.removeListener(_onFieldChanged);
    _cityController.removeListener(_onFieldChanged);
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handlePlaceOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final deliveryInfo = DeliveryInfo(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      city: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : 'Karachi',
      notes: _notesController.text.trim(),
    );

    final checkout = context.read<CheckoutProvider>();
    final cart = context.read<CartProvider>();
    final auth = context.read<AuthProvider>();
    final addressProvider = context.read<AddressProvider>();

    checkout.updateDeliveryInfo(deliveryInfo);

    setState(() => _isNavigatingToConfirmed = false);

    // Save address preferences concurrently in the background so checkout is not delayed
    Future<void>? addressSaveFuture;
    if (_saveAsDefault) {
      addressSaveFuture = _saveAddressPreference(addressProvider, auth, deliveryInfo);
    }

    final success = await checkout.submitCheckout(cart);

    if (success && mounted && checkout.confirmedOrder != null) {
      setState(() => _isNavigatingToConfirmed = true);
      final confirmedOrder = checkout.confirmedOrder!;

      if (addressSaveFuture != null) {
        await addressSaveFuture;
      }

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderConfirmedScreen(order: confirmedOrder),
        ),
      );
    }
  }

  Future<void> _saveAddressPreference(
    AddressProvider addressProvider,
    AuthProvider auth,
    DeliveryInfo deliveryInfo,
  ) async {
    try {
      if (addressProvider.addresses.isEmpty) {
        await addressProvider.addAddress(
          label: 'Home',
          fullName: deliveryInfo.fullName,
          phone: deliveryInfo.phone,
          address: deliveryInfo.address,
          city: deliveryInfo.city,
          isDefault: true,
        );
      } else if (_selectedSavedAddress != null && _isEditedFromSavedAddress) {
        await addressProvider.updateAddress(
          id: _selectedSavedAddress!.id,
          label: _selectedSavedAddress!.label,
          fullName: deliveryInfo.fullName,
          phone: deliveryInfo.phone,
          address: deliveryInfo.address,
          city: deliveryInfo.city,
          isDefault: true,
        );
      } else if (addressProvider.canAddAddress) {
        await addressProvider.addAddress(
          label: 'Home',
          fullName: deliveryInfo.fullName,
          phone: deliveryInfo.phone,
          address: deliveryInfo.address,
          city: deliveryInfo.city,
          isDefault: true,
        );
      }

      await auth.updateDeliveryProfile(
        defaultDeliveryInfo: deliveryInfo,
      );
    } catch (_) {
      // Non-critical background failure: don't break order flow
    }
  }

  void _openAddressSelectorSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final addressProvider = context.read<AddressProvider>();
    final addresses = addressProvider.addresses;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Select Delivery Destination',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Choose saved address or enter temporary details',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 24),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
                    children: [
                      ...addresses.map((addr) {
                        final isSelected = !_isCustomOneTime &&
                            _selectedSavedAddress?.id == addr.id;

                        return Container(
                          margin: const EdgeInsets.only(bottom: AppTheme.space12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? AppTheme.darkAccent : AppTheme.lightAccent)
                                    .withValues(alpha: 0.08)
                                : (isDark
                                    ? const Color(0xFF27272A).withValues(alpha: 0.5)
                                    : const Color(0xFFFBF8F5)),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? (isDark ? AppTheme.darkAccent : AppTheme.lightAccent)
                                  : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              _applyAddress(addr);
                              Navigator.pop(sheetCtx);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(AppTheme.space12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Icon(
                                      isSelected
                                          ? Icons.radio_button_checked_rounded
                                          : Icons.radio_button_off_rounded,
                                      color: isSelected
                                          ? (isDark ? AppTheme.darkAccent : AppTheme.lightAccent)
                                          : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              addr.label,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            if (addr.isDefault) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: (isDark ? AppTheme.darkAccent : AppTheme.lightAccent)
                                                      .withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'DEFAULT',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${addr.fullName} • ${addr.formattedPhone}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${addr.address}, ${addr.city}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                      // Temporary one-time address option
                      Container(
                        margin: const EdgeInsets.only(bottom: AppTheme.space12),
                        decoration: BoxDecoration(
                          color: _isCustomOneTime
                              ? (isDark ? AppTheme.darkAccent : AppTheme.lightAccent).withValues(alpha: 0.08)
                              : (isDark ? const Color(0xFF27272A).withValues(alpha: 0.5) : const Color(0xFFFBF8F5)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _isCustomOneTime
                                ? (isDark ? AppTheme.darkAccent : AppTheme.lightAccent)
                                : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                            width: _isCustomOneTime ? 1.5 : 1.0,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            _switchToCustomOneTime();
                            Navigator.pop(sheetCtx);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.space12),
                            child: Row(
                              children: [
                                Icon(
                                  _isCustomOneTime
                                      ? Icons.radio_button_checked_rounded
                                      : Icons.radio_button_off_rounded,
                                  color: _isCustomOneTime
                                      ? (isDark ? AppTheme.darkAccent : AppTheme.lightAccent)
                                      : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Use Temporary One-Time Address',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Ship to custom address without saving to address book',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.edit_note_rounded,
                                  size: 20,
                                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Add new address button if under max limit
                      if (addressProvider.canAddAddress)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 12),
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              Navigator.pop(sheetCtx);
                              await Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const AddressesScreen()),
                              );
                              if (!mounted) return;
                              final refreshed = context.read<AddressProvider>().defaultAddress;
                              if (refreshed != null && _selectedSavedAddress == null) {
                                _applyAddress(refreshed);
                              }
                            },
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: Text(
                              'Add New Address (${addresses.length}/${AddressProvider.maxAddresses})',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cart = context.watch<CartProvider>();
    final checkout = context.watch<CheckoutProvider>();
    final addressProvider = context.watch<AddressProvider>();
    final isPlacingOrder = checkout.isSubmitting || _isNavigatingToConfirmed;

    if (!cart.isEmpty) {
      _lastTotalUnits = cart.totalUnits;
      _lastFormattedSubtotal = cart.formattedSubtotal;
      _lastFormattedDeliveryFee = cart.formattedDeliveryFee;
      _lastFormattedTotal = cart.formattedTotal;
    }

    final displayTotalUnits = cart.isEmpty && isPlacingOrder ? _lastTotalUnits : cart.totalUnits;
    final displaySubtotal = cart.isEmpty && isPlacingOrder ? _lastFormattedSubtotal : cart.formattedSubtotal;
    final displayDeliveryFee = cart.isEmpty && isPlacingOrder ? _lastFormattedDeliveryFee : cart.formattedDeliveryFee;
    final displayTotal = cart.isEmpty && isPlacingOrder ? _lastFormattedTotal : cart.formattedTotal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout & Delivery'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20, vertical: AppTheme.space24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Error banner if any
              if (checkout.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppTheme.space12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorContainer,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 20, color: AppTheme.error),
                      const SizedBox(width: AppTheme.space8),
                      Expanded(
                        child: Text(
                          checkout.errorMessage!,
                          style: const TextStyle(
                            color: AppTheme.error,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space20),
              ],

              // Section 1 Header: Shipping Destination
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Shipping Destination',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                  ),
                  if (addressProvider.addresses.isNotEmpty)
                    TextButton.icon(
                      onPressed: _openAddressSelectorSheet,
                      icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                      label: Text(
                        addressProvider.addresses.length > 1 ? 'Change' : 'Address Book',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.space12),

              // Active Destination Preview Card
              if (_selectedSavedAddress != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppTheme.space12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E24) : const Color(0xFFFBF8F5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isDark ? AppTheme.darkAccent : AppTheme.lightAccent).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _selectedSavedAddress!.label == 'Work'
                              ? Icons.work_outline_rounded
                              : Icons.home_outlined,
                          size: 18,
                          color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _selectedSavedAddress!.label,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                if (_selectedSavedAddress!.isDefault) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (isDark ? AppTheme.darkAccent : AppTheme.lightAccent)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'DEFAULT',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.4,
                                        color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${_selectedSavedAddress!.address}, ${_selectedSavedAddress!.city}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _openAddressSelectorSheet,
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: const Text('Switch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space16),
              ] else if (_isCustomOneTime) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_note_rounded, size: 18, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Temporary one-time shipping address for this order.',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                      if (addressProvider.addresses.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            if (addressProvider.defaultAddress != null) {
                              _applyAddress(addressProvider.defaultAddress!);
                            }
                          },
                          child: const Text(
                            'Reset',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space16),
              ],

              CustomTextField(
                controller: _nameController,
                label: 'Recipient Full Name',
                hint: 'e.g. Ahmed Ali',
                prefixIcon: Icons.person_outline_rounded,
                validator: (val) {
                  if (val == null || val.trim().length < 2) {
                    return 'Please enter a valid recipient name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.space16),

              CustomTextField(
                controller: _phoneController,
                label: 'Mobile Phone Number',
                hint: '03001234567',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter mobile number';
                  }
                  final cleaned = val.replaceAll(RegExp(r'[\s\-]'), '');
                  if (!RegExp(r'^(\+92|92|0)?3[0-9]{9}$').hasMatch(cleaned)) {
                    return 'Enter a valid Pakistani mobile number (e.g. 03001234567)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.space16),

              // City Field
              CustomTextField(
                controller: _cityController,
                label: 'City',
                hint: 'e.g. Karachi, Lahore, Islamabad',
                prefixIcon: Icons.location_city_outlined,
                validator: (val) {
                  if (val == null || val.trim().length < 2) {
                    return 'Please enter city';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.space16),

              CustomTextField(
                controller: _addressController,
                label: 'Street Address & Apartment / House #',
                hint: 'House 14-B, Street 3, Block 7, Clifton',
                prefixIcon: Icons.home_outlined,
                maxLines: 2,
                validator: (val) {
                  if (val == null || val.trim().length < 8) {
                    return 'Please provide a detailed delivery address (min 8 characters)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.space16),

              CustomTextField(
                controller: _notesController,
                label: 'Delivery Instructions (Optional)',
                hint: 'Leave with guard, ring doorbell twice...',
                prefixIcon: Icons.notes_rounded,
              ),
              const SizedBox(height: AppTheme.space12),

              // Smart Default / Save Address Checkbox
              if (_shouldShowSaveCheckbox(addressProvider.addressesCount)) ...[
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _saveAsDefault,
                  activeColor: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                  title: Text(
                    _getSaveCheckboxTitle(addressProvider.addressesCount),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (val) => setState(() => _saveAsDefault = val ?? false),
                ),
                const SizedBox(height: AppTheme.space16),
              ] else
                const SizedBox(height: AppTheme.space8),

              // Section 2: Payment Method
              Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 18,
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
                  border: Border.all(
                    color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                      size: 26,
                    ),
                    const SizedBox(width: AppTheme.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cash on Delivery (COD)',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pay in cash upon receipt of your package.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.check_circle_rounded,
                      color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                      size: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.space24),

              // Section 3: Order Summary Breakdown
              Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 18,
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
                  border: Border.all(
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Items Subtotal ($displayTotalUnits units)',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          ),
                        ),
                        Text(
                          displaySubtotal,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Delivery Fee',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          ),
                        ),
                        Text(
                          displayDeliveryFee,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: displayDeliveryFee.toLowerCase().contains('free') ? AppTheme.success : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space12),
                    Divider(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                    const SizedBox(height: AppTheme.space12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Payable',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          displayTotal,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.space32),

              // Submit Checkout Button
              CustomButton(
                text: 'Confirm & Place Order',
                isLoading: isPlacingOrder,
                onPressed: _handlePlaceOrder,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
