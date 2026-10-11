import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Contextual promotional banner for the Catalog screen.
/// Tailored per category or storewide with dismiss support.
class CatalogPromoBanner extends StatelessWidget {
  final String? categoryId;
  final VoidCallback onDismiss;
  final VoidCallback? onTap;

  const CatalogPromoBanner({
    super.key,
    required this.categoryId,
    required this.onDismiss,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final config = _getPromoConfig(categoryId);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space4,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: isDark
              ? [const Color(0xFF241A16), const Color(0xFF18181E)]
              : [const Color(0xFFFFF7ED), const Color(0xFFFAF7F5)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
          color: isDark ? const Color(0xFF3F2B20) : const Color(0xFFF7DAC9),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            child: Row(
              children: [
                // Icon pill
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: (isDark ? AppTheme.darkAccent : AppTheme.lightAccent)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    config.icon,
                    size: 15,
                    color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                  ),
                ),

                const SizedBox(width: 10),

                // Text details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            config.tag,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.7,
                              color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              config.headline,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        config.subtext,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Dismiss button
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  splashRadius: 14,
                  tooltip: 'Dismiss offer',
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  onPressed: onDismiss,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static _PromoConfig _getPromoConfig(String? categoryId) {
    switch (categoryId) {
      case 'electronics':
        return const _PromoConfig(
          icon: Icons.headphones_rounded,
          tag: 'STUDIO SOUND',
          headline: '1-Year Coverage Included',
          subtext: 'Authentic acoustic wearables & precision audio.',
        );
      case 'clothing':
        return const _PromoConfig(
          icon: Icons.checkroom_rounded,
          tag: 'SPRING WARDROBE',
          headline: 'Up to 25% Off Tailored Fits',
          subtext: 'Bespoke silhouettes and sustainable linen drops.',
        );
      case 'home-kitchen':
        return const _PromoConfig(
          icon: Icons.chair_rounded,
          tag: 'ARTISANAL LIVING',
          headline: 'Complimentary White Glove Delivery',
          subtext: 'On select bespoke ceramics & minimalist seating.',
        );
      case 'personal-care':
        return const _PromoConfig(
          icon: Icons.spa_rounded,
          tag: 'CLEAN ESSENTIALS',
          headline: '100% Certified Formulations',
          subtext: 'Handcrafted botanicals and cruelty-free wellness.',
        );
      default:
        return const _PromoConfig(
          icon: Icons.local_offer_rounded,
          tag: 'LIMITED DROP',
          headline: 'Free Delivery Over PKR 5,000',
          subtext: 'Explore our full architectural & artisan catalog.',
        );
    }
  }
}

class _PromoConfig {
  final IconData icon;
  final String tag;
  final String headline;
  final String subtext;

  const _PromoConfig({
    required this.icon,
    required this.tag,
    required this.headline,
    required this.subtext,
  });
}
