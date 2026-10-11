import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/catalog/stock_badge.dart';
import '../../widgets/common/app_confirmation_dialog.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/quantity_stepper.dart';
import '../../utils/app_config.dart';
import '../auth/login_screen.dart';
import '../cart/cart_screen.dart';

/// Screen displaying rich product details, high-res presentation,
/// availability status, and direct cart actions.
class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _selectedQuantity = 1;
  bool _isAdded = false;
  Timer? _resetTimer;
  Timer? _snackBarTimer;
  ScaffoldMessengerState? _messenger;

  @override
  void dispose() {
    _resetTimer?.cancel();
    _snackBarTimer?.cancel();
    _messenger?.clearSnackBars();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Listen to live updates of this product from catalog provider if available
    final catalog = context.watch<CatalogProvider>();
    final liveProduct = catalog.findProductById(widget.product.productId) ?? widget.product;
    final category = catalog.findCategoryById(liveProduct.categoryId);

    final canAddToCart = liveProduct.isInStock && liveProduct.isActive;
    final maxQuantity = liveProduct.stockQuantity > 0 ? liveProduct.stockQuantity : 1;

    // Watch cart provider for real-time item count badge
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(liveProduct.name),
        actions: [
          IconButton(
            tooltip: 'Shopping Bag',
            icon: Badge(
              isLabelVisible: cart.totalUnits > 0,
              label: Text('${cart.totalUnits}'),
              backgroundColor: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
              textColor: isDark ? Colors.black : Colors.white,
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          ),
          const SizedBox(width: AppTheme.space8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Image Presentation
            AspectRatio(
              aspectRatio: 1.15,
              child: Container(
                color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceWarm,
                child: liveProduct.imageUrl.isNotEmpty
                    ? Image.network(
                        liveProduct.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(isDark),
                      )
                    : _buildImagePlaceholder(isDark),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(AppTheme.space24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category tag and Stock status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceWarm,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            border: Border.all(
                              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                            ),
                          ),
                          child: Text(
                            category.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                              color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                            ),
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      StockBadge(product: liveProduct),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space16),

                  // Product Title
                  Text(
                    liveProduct.name,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space12),

                  // Price
                  Text(
                    liveProduct.formattedPrice,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space24),

                  // Divider
                  Divider(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                  const SizedBox(height: AppTheme.space16),

                  // Description Header
                  Text(
                    'About this piece',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space8),
                  Text(
                    liveProduct.description.isNotEmpty
                        ? liveProduct.description
                        : 'Designed with understated luxury and crafted from sustainable, premium materials.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space32),

                  // Quantity Selector (if in stock)
                  if (canAddToCart) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Quantity',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                          ),
                        ),
                        QuantityStepper(
                          value: _selectedQuantity,
                          min: 1,
                          max: maxQuantity,
                          onChanged: (newQty) {
                            setState(() => _selectedQuantity = newQty);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space24),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppTheme.space16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightBackground,
          border: Border(
            top: BorderSet(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: CustomButton(
            text: _isAdded
                ? 'Added to Bag'
                : (canAddToCart
                    ? 'Add to Bag  •  ${liveProduct.formattedPrice}'
                    : 'Currently Unavailable'),
            icon: _isAdded ? Icons.check_circle_rounded : null,
            onPressed: canAddToCart && !_isAdded ? () => _handleAddToCart(liveProduct) : null,
          ),
        ),
      ),
    );
  }

  Future<void> _handleAddToCart(Product product) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      final shouldSignIn = await AppConfirmationDialog.show(
        context: context,
        title: 'Sign In Required',
        message: 'Please sign in to add items to your shopping bag.',
        icon: Icons.shopping_bag_outlined,
        confirmLabel: 'Sign In',
        cancelLabel: 'Cancel',
      );

      if (shouldSignIn == true && mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
      return;
    }

    final cart = context.read<CartProvider>();
    final currentQty = cart.getQuantity(product.productId);
    final targetQty = currentQty + _selectedQuantity;

    if (targetQty > AppConfig.maxCartItemQuantity) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum ${AppConfig.maxCartItemQuantity} units allowed per product.'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (targetQty > product.stockQuantity) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only ${product.stockQuantity} units available in stock.'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 1. Instantaneous UI feedback on button (0ms)
    setState(() => _isAdded = true);
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _isAdded = false);
    });

    // 2. Instantaneous SnackBar display (0ms - zero network latency wait)
    final messenger = ScaffoldMessenger.of(context);
    _messenger = messenger;
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Added $_selectedQuantity item(s) to your bag'),
        duration: const Duration(milliseconds: 1800),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'View Bag',
          textColor: AppTheme.lightAccent,
          onPressed: () {
            messenger.clearSnackBars();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CartScreen()),
            );
          },
        ),
      ),
    );

    _snackBarTimer?.cancel();
    _snackBarTimer = Timer(const Duration(milliseconds: 1800), () {
      messenger.clearSnackBars();
    });

    // 3. Dispatch cart addition concurrently in background
    cart.addToCart(product, quantity: _selectedQuantity).then((success) {
      if (!mounted) return;
      if (!success) {
        _resetTimer?.cancel();
        setState(() => _isAdded = false);

        if (cart.errorMessage != null) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(cart.errorMessage!),
              backgroundColor: AppTheme.error,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });
  }

  Widget _buildImagePlaceholder(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chair_outlined,
            size: 64,
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            'Product Preview',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class BorderSet extends BorderSide {
  const BorderSet({super.color, super.width});
}
