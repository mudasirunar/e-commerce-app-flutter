import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/delivery_info.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/checkout_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import 'order_confirmed_screen.dart';

/// Screen managing checkout delivery collection, Cash on Delivery confirmation,
/// and atomic server-side inventory verification and checkout.
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
  final _notesController = TextEditingController();

  String _selectedCity = 'Karachi';
  bool _saveAsDefault = false;

  final List<String> _pakistanCities = const [
    'Karachi',
    'Lahore',
    'Islamabad',
    'Rawalpindi',
    'Faisalabad',
    'Peshawar',
    'Multan',
    'Quetta',
    'Sialkot',
    'Hyderabad',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefillFromProfile();
    });
  }

  void _prefillFromProfile() {
    final profile = context.read<AuthProvider>().userProfile;
    if (profile?.defaultDeliveryInfo != null) {
      final info = profile!.defaultDeliveryInfo!;
      _nameController.text = info.fullName;
      _phoneController.text = info.phone;
      _addressController.text = info.address;
      if (_pakistanCities.contains(info.city)) {
        setState(() => _selectedCity = info.city);
      }
    } else if (profile != null && profile.displayName.isNotEmpty) {
      _nameController.text = profile.displayName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handlePlaceOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final deliveryInfo = DeliveryInfo(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      city: _selectedCity,
      notes: _notesController.text.trim(),
    );

    final checkout = context.read<CheckoutProvider>();
    final cart = context.read<CartProvider>();
    final auth = context.read<AuthProvider>();

    checkout.updateDeliveryInfo(deliveryInfo);

    if (_saveAsDefault) {
      await auth.updateDeliveryProfile(
        defaultDeliveryInfo: deliveryInfo,
      );
    }

    final success = await checkout.submitCheckout(cart);

    if (success && mounted && checkout.confirmedOrder != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderConfirmedScreen(order: checkout.confirmedOrder!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cart = context.watch<CartProvider>();
    final checkout = context.watch<CheckoutProvider>();

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

              // Section 1: Delivery Details
              Text(
                'Shipping Destination',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
              ),
              const SizedBox(height: AppTheme.space16),

              CustomTextField(
                controller: _nameController,
                label: 'Recipient Full Name',
                hint: 'Mudasir Unar',
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

              // City Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedCity,
                decoration: const InputDecoration(
                  labelText: 'City',
                  prefixIcon: Icon(Icons.location_city_outlined),
                ),
                items: _pakistanCities.map((city) {
                  return DropdownMenuItem(value: city, child: Text(city));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCity = val);
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

              // Save default address checkbox
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _saveAsDefault,
                activeColor: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                title: Text(
                  'Save as my default delivery address',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (val) => setState(() => _saveAsDefault = val ?? false),
              ),
              const SizedBox(height: AppTheme.space24),

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
                          'Items Subtotal (${cart.totalUnits} units)',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          ),
                        ),
                        Text(
                          cart.formattedSubtotal,
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
                          cart.formattedDeliveryFee,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: cart.deliveryFeeMinor == 0 ? AppTheme.success : null,
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
                          cart.formattedTotal,
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
                isLoading: checkout.isSubmitting,
                onPressed: _handlePlaceOrder,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
