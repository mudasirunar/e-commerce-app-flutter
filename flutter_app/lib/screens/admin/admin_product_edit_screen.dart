import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/admin_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/custom_button.dart';

/// Screen allowing administrators to adjust live inventory stock count,
/// apply quick unit adjustments, and toggle storefront catalog visibility.
class AdminProductEditScreen extends StatefulWidget {
  final Product product;

  const AdminProductEditScreen({super.key, required this.product});

  @override
  State<AdminProductEditScreen> createState() => _AdminProductEditScreenState();
}

class _AdminProductEditScreenState extends State<AdminProductEditScreen> {
  late final TextEditingController _stockController;
  late int _stockQuantity;
  late bool _isActive;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _stockQuantity = widget.product.stockQuantity;
    _stockController = TextEditingController(text: '$_stockQuantity');
    _isActive = widget.product.isActive;
  }

  @override
  void dispose() {
    _stockController.dispose();
    super.dispose();
  }

  void _updateStock(int newQuantity) {
    final clamped = newQuantity < 0 ? 0 : newQuantity;
    setState(() {
      _stockQuantity = clamped;
      _stockController.text = '$clamped';
      _errorMessage = null;
    });
  }

  void _onStockInputChanged(String text) {
    final parsed = int.tryParse(text.trim());
    if (parsed != null && parsed >= 0) {
      setState(() {
        _stockQuantity = parsed;
        _errorMessage = null;
      });
    }
  }

  Future<void> _handleSave() async {
    final parsedStock = int.tryParse(_stockController.text.trim()) ?? _stockQuantity;
    if (parsedStock < 0) {
      setState(() => _errorMessage = 'Please enter a valid non-negative stock count');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final admin = context.read<AdminProvider>();
    final catalog = context.read<CatalogProvider>();

    bool stockOk = true;
    if (parsedStock != widget.product.stockQuantity) {
      stockOk = await admin.updateStock(widget.product.productId, parsedStock);
    }

    bool activeOk = true;
    if (_isActive != widget.product.isActive) {
      activeOk = await admin.toggleActive(widget.product.productId, _isActive);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (stockOk && activeOk) {
        await catalog.refresh();
        if (mounted) {
          final messenger = ScaffoldMessenger.of(context);
          messenger.clearSnackBars();
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Product inventory updated successfully'),
              backgroundColor: AppTheme.success,
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        setState(() {
          _errorMessage = admin.errorMessage ?? 'Failed to update product settings.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final catalog = context.watch<CatalogProvider>();

    String categoryName = widget.product.categoryId;
    for (final c in catalog.categories) {
      if (c.categoryId == widget.product.categoryId) {
        categoryName = c.name;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product Inventory'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20, vertical: AppTheme.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Error banner if any
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(AppTheme.space12),
                decoration: BoxDecoration(
                  color: AppTheme.errorContainer,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 20),
                    const SizedBox(width: AppTheme.space8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppTheme.error, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.space16),
            ],

            // 1. Product Hero Preview Card
            Container(
              padding: const EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E22) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF2E2E34) : const Color(0xFFE7E5E4),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 72,
                      width: 72,
                      color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                      child: widget.product.imageUrl.isNotEmpty
                          ? Image.network(
                              widget.product.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.chair_outlined, size: 32),
                            )
                          : const Icon(Icons.chair_outlined, size: 32),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF27272A) : const Color(0xFFF4EFEA),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                categoryName,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '#${widget.product.productId}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.product.formattedPrice,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space20),

            // 2. Interactive Stock Units Control Card
            Container(
              padding: const EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E22) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF2E2E34) : const Color(0xFFE7E5E4),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 18, color: accentColor),
                          const SizedBox(width: 8),
                          const Text(
                            'Inventory Stock Count',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Units available',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Stepper & Direct Editable Input Row
                  Row(
                    children: [
                      // Decrement Button
                      _buildStepperButton(
                        icon: Icons.remove_rounded,
                        isEnabled: _stockQuantity > 0,
                        onTap: () => _updateStock(_stockQuantity - 1),
                        isDark: isDark,
                        accentColor: accentColor,
                      ),
                      const SizedBox(width: 12),

                      // Number Display & Input
                      Expanded(
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF27272A) : const Color(0xFFF4EFEA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                              width: 1.2,
                            ),
                          ),
                          child: Center(
                            child: TextField(
                              controller: _stockController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              onChanged: _onStockInputChanged,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : Colors.black87,
                                letterSpacing: 1,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Increment Button
                      _buildStepperButton(
                        icon: Icons.add_rounded,
                        isEnabled: true,
                        onTap: () => _updateStock(_stockQuantity + 1),
                        isDark: isDark,
                        accentColor: accentColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Quick Preset Delta Buttons
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildDeltaChip(
                        label: '+5 units',
                        onTap: () => _updateStock(_stockQuantity + 5),
                        isDark: isDark,
                        accentColor: accentColor,
                      ),
                      _buildDeltaChip(
                        label: '+10 units',
                        onTap: () => _updateStock(_stockQuantity + 10),
                        isDark: isDark,
                        accentColor: accentColor,
                      ),
                      _buildDeltaChip(
                        label: '+25 units',
                        onTap: () => _updateStock(_stockQuantity + 25),
                        isDark: isDark,
                        accentColor: accentColor,
                      ),
                      _buildDeltaChip(
                        label: 'Set to 0',
                        isDestructive: true,
                        onTap: () => _updateStock(0),
                        isDark: isDark,
                        accentColor: accentColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Dynamic Stock Health Indicator
                  _buildStockHealthIndicator(isDark),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space20),

            // 3. Storefront Visibility Control Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E22) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF2E2E34) : const Color(0xFFE7E5E4),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _isActive
                          ? const Color(0xFF10B981).withValues(alpha: 0.12)
                          : const Color(0xFF9CA3AF).withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        _isActive ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                        size: 20,
                        color: _isActive ? const Color(0xFF10B981) : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isActive ? 'Visible in Customer Catalog' : 'Hidden from Catalog',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isActive
                              ? 'Shoppers can discover and purchase this item.'
                              : 'Concealed from customer browsing and checkout.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _isActive,
                    activeThumbColor: accentColor,
                    onChanged: (val) => setState(() => _isActive = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space24),

            // 4. Save Changes Button
            CustomButton(
              text: 'Save Inventory Changes',
              isLoading: _isSaving,
              onPressed: _handleSave,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperButton({
    required IconData icon,
    required bool isEnabled,
    required VoidCallback onTap,
    required bool isDark,
    required Color accentColor,
  }) {
    return Material(
      color: isEnabled
          ? (isDark ? const Color(0xFF27272A) : const Color(0xFFF4EFEA))
          : (isDark ? const Color(0xFF1C1C1F) : const Color(0xFFF5F5F4)),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEnabled
                  ? (isDark ? const Color(0xFF3F3F46) : const Color(0xFFE5E5E5))
                  : (isDark ? const Color(0xFF27272A) : const Color(0xFFEBEBEB)),
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 22,
              color: isEnabled
                  ? (isDark ? Colors.white : Colors.black87)
                  : (isDark ? Colors.white24 : Colors.black26),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeltaChip({
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    required Color accentColor,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? const Color(0xFFEF4444) : accentColor;

    return Material(
      color: color.withValues(alpha: isDark ? 0.10 : 0.06),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStockHealthIndicator(bool isDark) {
    Color healthColor;
    IconData healthIcon;
    String healthTitle;
    String healthSubtitle;

    if (_stockQuantity == 0) {
      healthColor = const Color(0xFFEF4444);
      healthIcon = Icons.warning_amber_rounded;
      healthTitle = 'Out of Stock';
      healthSubtitle = 'Customers cannot place orders for this item.';
    } else if (_stockQuantity <= 5) {
      healthColor = const Color(0xFFF59E0B);
      healthIcon = Icons.error_outline_rounded;
      healthTitle = 'Low Stock Alert ($_stockQuantity units left)';
      healthSubtitle = 'Consider restocking soon before inventory runs out.';
    } else {
      healthColor = const Color(0xFF10B981);
      healthIcon = Icons.check_circle_outline_rounded;
      healthTitle = 'Healthy Inventory ($_stockQuantity units)';
      healthSubtitle = 'Sufficient stock for regular customer orders.';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: healthColor.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: healthColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(healthIcon, size: 18, color: healthColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  healthTitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: healthColor,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  healthSubtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
