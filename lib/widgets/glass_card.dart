import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final LinearGradient? gradient;
  final BorderRadius? borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
    this.gradient,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final card = RepaintBoundary(
      child: Container(
        width: width,
        height: height,
        margin: margin ?? const EdgeInsets.only(bottom: 10),
        padding: padding ?? const EdgeInsets.all(AppTheme.spacingMD),
        decoration: BoxDecoration(
          gradient: gradient ?? AppTheme.cardGradient,
          borderRadius:
              borderRadius ?? BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
        child: child,
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: card,
      );
    }

    return card;
  }
}
