import 'package:admivida/common/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Custom reusable container card with clean borders, smooth shadows,
/// subtle desktop hover state, and tactile ink interaction for Admivida UI.
class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final Border? border;
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
    this.border,
    this.borderRadius = 16.0,
    this.showShadow = true,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = widget.backgroundColor ?? Theme.of(context).cardColor;
    final bool isInteractive = widget.onTap != null;
    final bool activeHover = _isHovered && isInteractive;
    final effectiveBorderColor = activeHover
        ? AppColors.kPrimary300.withValues(alpha: 0.85)
        : (widget.borderColor ?? AppColors.kNeutral200.withValues(alpha: 0.85));

    return MouseRegion(
      onEnter: isInteractive ? (_) => setState(() => _isHovered = true) : null,
      onExit: isInteractive ? (_) => setState(() => _isHovered = false) : null,
      cursor: isInteractive ? SystemMouseCursors.click : MouseCursor.defer,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, activeHover ? -2.0 : 0.0, 0),
        margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        decoration: BoxDecoration(
          color: effectiveBackgroundColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: widget.border ??
              Border.all(
                color: effectiveBorderColor,
                width: activeHover ? 1.3 : 1.0,
              ),
          boxShadow: widget.showShadow
              ? [
                  BoxShadow(
                    color: AppColors.kPrimaryColor.withValues(alpha: activeHover ? 0.07 : 0.03),
                    blurRadius: activeHover ? 20.0 : 12.0,
                    spreadRadius: activeHover ? 0.5 : 0.0,
                    offset: Offset(0, activeHover ? 8 : 3),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: activeHover ? 0.03 : 0.015),
                    blurRadius: 4.0,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: InkWell(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            onTap: widget.onTap,
            highlightColor: AppColors.kPrimaryColor.withValues(alpha: 0.03),
            splashColor: AppColors.kPrimaryColor.withValues(alpha: 0.06),
            hoverColor: Colors.transparent,
            child: Padding(
              padding: widget.padding ?? const EdgeInsets.all(16.0),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
