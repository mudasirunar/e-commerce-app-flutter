import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/admin_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

/// Screen allowing administrators to adjust live inventory stock and catalog visibility.
class AdminProductEditScreen extends StatefulWidget {
  final Product product;

  const AdminProductEditScreen({super.key, required this.product});

  @override
  State<AdminProductEditScreen> createState() => _AdminProductEditScreenState();
}

class _AdminProductEditScreenState extends State<AdminProductEditScreen> {
  late final TextEditingController _stockController;
  late bool _isActive;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _stockController = TextEditingController(text: '${widget.product.stockQuantity}');
    _isActive = widget.product.isActive;
  }

  @override
  void dispose() {
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final parsedStock = int.tryParse(_stockController.text.trim());
    if (parsedStock == null || parsedStock < 0) {
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product updated successfully'),
              backgroundColor: AppTheme.success,
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product Inventory'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20, vertical: AppTheme.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(AppTheme.space12),
                decoration: BoxDecoration(
                  color: AppTheme.errorContainer,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppTheme.error, fontSize: 13),
                ),
              ),
              const SizedBox(height: AppTheme.space20),
            ],

            // Product summary preview
            Container(
              padding: const EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceWarm,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    child: Container(
                      height: 64,
                      width: 64,
                      color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                      child: widget.product.imageUrl.isNotEmpty
                          ? Image.network(
                              widget.product.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.chair_outlined),
                            )
                          : const Icon(Icons.chair_outlined),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.product.formattedPrice,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space24),

            // Stock adjustment
            Text(
              'Inventory Stock Count',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.space12),

            CustomTextField(
              controller: _stockController,
              label: 'Available Units',
              hint: '25',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.inventory_2_outlined,
            ),
            const SizedBox(height: AppTheme.space24),

            // Active visibility switch
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Visible in Store Catalog',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
              ),
              subtitle: Text(
                _isActive
                    ? 'Customers can browse and order this piece.'
                    : 'Piece is hidden from customer browsing.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
              value: _isActive,
              activeThumbColor: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
              onChanged: (val) => setState(() => _isActive = val),
            ),
            const SizedBox(height: AppTheme.space32),

            // Save button
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
}
