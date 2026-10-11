import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../theme/app_theme.dart';

/// Instagram-style circular category story avatar with gradient border ring,
/// smooth tap feedback, and crisp micro-typography.
class CategoryStoryBubble extends StatefulWidget {
  final Category category;
  final String? imageUrl;
  final IconData? iconFallback;
  final VoidCallback onTap;

  const CategoryStoryBubble({
    super.key,
    required this.category,
    this.imageUrl,
    this.iconFallback,
    required this.onTap,
  });

  @override
  State<CategoryStoryBubble> createState() => _CategoryStoryBubbleState();
}

class _CategoryStoryBubbleState extends State<CategoryStoryBubble> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryAccent = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final secondaryAccent = isDark ? const Color(0xFFF59E0B) : const Color(0xFFEA580C);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: Container(
          width: 72,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Outer Gradient Story Ring
              Container(
                width: 64,
                height: 64,
                padding: const EdgeInsets.all(2.5), // Ring thickness
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryAccent,
                      secondaryAccent,
                      const Color(0xFFF97316),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryAccent.withValues(alpha: isDark ? 0.25 : 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(2.0), // Gap inside ring
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF18181B) : Colors.white,
                  ),
                  child: ClipOval(
                    child: Container(
                      color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceWarm,
                      child: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                          ? Image.network(
                              widget.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildFallback(isDark),
                            )
                          : _buildFallback(isDark),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // Category Label
              Text(
                widget.category.name,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  letterSpacing: -0.1,
                  height: 1.15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallback(bool isDark) {
    return Center(
      child: Icon(
        widget.iconFallback ?? Icons.category_outlined,
        size: 26,
        color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
      ),
    );
  }
}
