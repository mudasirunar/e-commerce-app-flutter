import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/cart/cart_screen.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_config.dart';
import 'stock_badge.dart';

/// Product card designed for grid and list browsing.
class ProductCard extends StatefulWidget {
  final Product product;
  final String? categoryName;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    this.categoryName,
    this.onTap,
    this.onAddToCart,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isAdded = false;
  Timer? _resetTimer;
  Timer? _snackBarTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    _snackBarTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final categoryName = widget.categoryName;
    final onTap = widget.onTap;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with aspect ratio and fallback
            AspectRatio(
              aspectRatio: 1.2,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceWarm,
                    child: product.imageUrl.isNotEmpty
                        ? Image.network(
                            product.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(isDark),
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Center(
                                child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    value: progress.expectedTotalBytes != null
                                        ? progress.cumulativeBytesLoaded /
                                            progress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                          )
                        : _buildPlaceholder(isDark),
                  ),
                  if (product.isFeatured)
                    Positioned(
                      top: AppTheme.space8,
                      left: AppTheme.space8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: Text(
                          'Featured',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  if (product.isOutOfStock)
                    Positioned(
                      top: AppTheme.space8,
                      right: AppTheme.space8,
                      child: StockBadge(product: product),
                    ),
                ],
              ),
            ),

            // Content details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (categoryName != null) ...[
                          Text(
                            categoryName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                        ],
                        Text(
                          product.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // Rating & Reviews row
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              product.rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '(${product.reviewCount})',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Price & Quick Action button row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            product.formattedPrice,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (product.isInStock)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            decoration: BoxDecoration(
                              color: _isAdded
                                  ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5))
                                  : (isDark ? AppTheme.darkAccent : AppTheme.lightAccent),
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                              border: Border.all(
                                color: _isAdded
                                    ? const Color(0xFF10B981)
                                    : Colors.transparent,
                                width: 1,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _isAdded ? null : () => _handleAddToCart(isDark),
                                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    transitionBuilder: (child, animation) {
                                      return ScaleTransition(scale: animation, child: child);
                                    },
                                    child: _isAdded
                                        ? Row(
                                            key: const ValueKey('added'),
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.check_rounded,
                                                size: 13,
                                                color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                'Added',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                                                ),
                                              ),
                                            ],
                                          )
                                        : Row(
                                            key: const ValueKey('add'),
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.add_shopping_cart_rounded,
                                                size: 13,
                                                color: isDark ? Colors.black : Colors.white,
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                'Add',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: isDark ? Colors.black : Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            ),
                            child: Text(
                              'Sold Out',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAddToCart(bool isDark) {
    if (widget.onAddToCart != null) {
      widget.onAddToCart!();
      return;
    }

    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please sign in to add items to your bag'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'SIGN IN',
            textColor: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ),
      );
      return;
    }

    final cart = context.read<CartProvider>();
    final currentQty = cart.getQuantity(widget.product.productId);
    if (currentQty >= widget.product.stockQuantity) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only ${widget.product.stockQuantity} units available in stock.'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (currentQty >= AppConfig.maxCartItemQuantity) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum ${AppConfig.maxCartItemQuantity} units allowed per product.'),
          duration: Duration(seconds: 2),
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
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text('${widget.product.name} added to bag'),
        duration: const Duration(milliseconds: 1800),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'VIEW BAG',
          textColor: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
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
    cart.addToCart(widget.product, quantity: 1).then((success) {
      if (!mounted) return;
      if (!success) {
        _resetTimer?.cancel();
        setState(() => _isAdded = false);

        if (cart.errorMessage != null) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(cart.errorMessage!),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });
  }

  Widget _buildPlaceholder(bool isDark) {
    return Center(
      child: Icon(
        Icons.inventory_2_outlined,
        size: 32,
        color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
      ),
    );
  }
}
