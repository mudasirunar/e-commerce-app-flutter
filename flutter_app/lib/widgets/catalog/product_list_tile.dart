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

/// Horizontal list card for the Catalog list view mode.
/// Displays product thumbnail on the left, descriptive details in the center,
/// and formatted price with quick Add-to-Bag action on the right.
class ProductListTile extends StatefulWidget {
  final Product product;
  final String? categoryName;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;

  const ProductListTile({
    super.key,
    required this.product,
    this.categoryName,
    this.onTap,
    this.onAddToCart,
  });

  @override
  State<ProductListTile> createState() => _ProductListTileState();
}

class _ProductListTileState extends State<ProductListTile> {
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
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Thumbnail with Badges
              Stack(
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceWarm,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      border: Border.all(
                        color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                        width: 0.8,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      child: product.imageUrl.isNotEmpty
                          ? Image.network(
                              product.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildPlaceholder(isDark),
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Center(
                                  child: SizedBox(
                                    height: 18,
                                    width: 18,
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
                  ),

                  if (product.isFeatured)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: Text(
                          'Featured',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    ),

                  if (product.isOutOfStock)
                    Positioned(
                      bottom: 4,
                      left: 4,
                      right: 4,
                      child: StockBadge(product: product),
                    ),
                ],
              ),

              const SizedBox(width: AppTheme.space12),

              // Center Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (categoryName != null) ...[
                      Text(
                        categoryName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.7,
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
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Rating & Review row
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
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                          ),
                        ),
                        if (product.reviewCount > 0) ...[
                          const SizedBox(width: 2),
                          Text(
                            '(${product.reviewCount})',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ],
                        if (product.isLowStock) ...[
                          const SizedBox(width: 8),
                          Text(
                            'Only ${product.stockQuantity} left',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber.shade700,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Price & Add to Bag
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          product.formattedPrice,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                          ),
                        ),

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
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                                              const SizedBox(width: 4),
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
                                              const SizedBox(width: 4),
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
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            ),
                            child: Text(
                              'Sold Out',
                              style: TextStyle(
                                fontSize: 10.5,
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
            ],
          ),
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

        final msg = cart.errorMessage ?? 'Could not add item';
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  Widget _buildPlaceholder(bool isDark) {
    return Center(
      child: Icon(
        Icons.inventory_2_outlined,
        size: 32,
        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
      ),
    );
  }
}
