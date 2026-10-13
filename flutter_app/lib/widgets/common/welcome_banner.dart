import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Data payload for configuring dynamic welcome banner and sign-out messages.
class WelcomeBannerData {
  final bool isNewSignup;
  final String name;
  final bool isAdmin;
  final bool isSignOut;
  final IconData? icon;
  final String? customTitle;
  final String? customSubtitle;

  const WelcomeBannerData({
    this.isNewSignup = false,
    this.name = '',
    this.isAdmin = false,
    this.isSignOut = false,
    this.icon,
    this.customTitle,
    this.customSubtitle,
  });

  const WelcomeBannerData.signOut({
    this.name = '',
    this.icon = Icons.logout_rounded,
    this.customTitle,
    this.customSubtitle,
  })  : isNewSignup = false,
        isAdmin = false,
        isSignOut = true;

  String get firstName {
    final clean = name.trim();
    if (clean.isEmpty) return '';
    return clean.split(RegExp(r'\s+')).first;
  }

  String get title {
    if (customTitle != null) return customTitle!;
    final cleanName = firstName;
    final hasName = cleanName.isNotEmpty && cleanName.toLowerCase() != 'customer';
    if (isSignOut) {
      return hasName ? 'Signed out, $cleanName' : 'Signed out';
    }
    if (isAdmin) {
      if (isNewSignup) {
        return hasName ? 'Welcome, Admin $cleanName!' : 'Welcome, Admin!';
      } else {
        return hasName ? 'Welcome back, Admin $cleanName!' : 'Welcome back, Admin!';
      }
    } else {
      if (isNewSignup) {
        return hasName ? 'Welcome, $cleanName!' : 'Welcome to the family!';
      } else {
        return hasName ? 'Welcome back, $cleanName!' : 'Welcome back!';
      }
    }
  }

  String get subtitle {
    if (customSubtitle != null) return customSubtitle!;
    if (isSignOut) {
      return 'You have been signed out successfully. See you soon!';
    }
    if (isAdmin) {
      return isNewSignup
          ? 'Your administrative privileges are active.'
          : 'Admin management controls are ready.';
    } else {
      return isNewSignup
          ? 'Your account is ready. Enjoy your shopping!'
          : 'Great to have you back with us.';
    }
  }
}

/// Floating top banner featuring waving hand micro-animation,
/// dynamic user role messaging, 3-second auto-dismiss, and manual close button.
class WelcomeBanner extends StatefulWidget {
  final WelcomeBannerData data;
  final VoidCallback? onDismissed;

  const WelcomeBanner({
    super.key,
    required this.data,
    this.onDismissed,
  });

  @override
  State<WelcomeBanner> createState() => _WelcomeBannerState();
}

class _WelcomeBannerState extends State<WelcomeBanner> with TickerProviderStateMixin {
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  late final AnimationController _waveController;
  late final Animation<double> _waveAnimation;

  Timer? _dismissTimer;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();

    // Slide in/out animation controller
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 350),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    // Waving hand rocking animation
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _waveAnimation = Tween<double>(
      begin: -0.22,
      end: 0.22,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));

    // Start wave rocking 6 times (3 complete waves back & forth)
    _waveController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _waveController.reverse();
      } else if (status == AnimationStatus.dismissed && _waveCount < 4) {
        _waveCount++;
        _waveController.forward();
      }
    });

    // Animate in, then schedule auto-dismiss after 3 seconds
    _slideController.forward().then((_) {
      if (mounted) {
        _waveController.forward();
        _dismissTimer = Timer(const Duration(seconds: 3), () {
          _dismiss();
        });
      }
    });
  }

  int _waveCount = 0;

  void _dismiss() {
    if (_isDismissing || !mounted) return;
    _isDismissing = true;
    _dismissTimer?.cancel();
    _dismissTimer = null;

    _slideController.reverse().then((_) {
      if (mounted) {
        widget.onDismissed?.call();
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _slideController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF1E2430) : Colors.white;
    final borderColor = isDark
        ? AppTheme.darkAccent.withValues(alpha: 0.35)
        : AppTheme.lightAccent.withValues(alpha: 0.25);
    final titleColor = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final subtitleColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space16,
              vertical: AppTheme.space8,
            ),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space16,
                  vertical: AppTheme.space12,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(color: borderColor, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Animated Leading Icon (waving hand or custom sign-out icon)
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: (isDark ? AppTheme.darkAccent : AppTheme.lightAccent)
                            .withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: widget.data.icon != null
                          ? AnimatedBuilder(
                              animation: _waveAnimation,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _waveAnimation.value * 0.35,
                                  alignment: Alignment.center,
                                  child: child,
                                );
                              },
                              child: Icon(
                                widget.data.icon,
                                size: 20,
                                color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                              ),
                            )
                          : AnimatedBuilder(
                              animation: _waveAnimation,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _waveAnimation.value,
                                  alignment: Alignment.bottomRight,
                                  child: child,
                                );
                              },
                              child: const Text(
                                '👋',
                                style: TextStyle(fontSize: 22),
                              ),
                            ),
                    ),
                    const SizedBox(width: AppTheme.space12),

                    // Title & Dynamic Subtitle
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.data.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: titleColor,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.data.subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: subtitleColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppTheme.space8),

                    // Close Button
                    InkWell(
                      onTap: _dismiss,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.space4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: subtitleColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
