import 'package:flutter/material.dart';
import 'package:admivida/common/constants/app_colors.dart';

/// Custom reusable container card with clean borders, smooth shadows,
/// and optional interaction capabilities for Admivida UI design system.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final bool showShadow;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 16.0,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ?? Theme.of(context).cardColor;
    final effectiveBorderColor = borderColor ?? AppColors.kNeutral200;

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: effectiveBorderColor, width: 1.0),
        boxShadow: showShadow ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12.0, offset: const Offset(0, 4))] : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          highlightColor: Theme.of(context).primaryColor.withValues(alpha: 0.05),
          splashColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          child: Padding(padding: padding ?? const EdgeInsets.all(16.0), child: child),
        ),
      ),
    );
  }
}
