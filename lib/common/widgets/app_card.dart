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
    final effectiveBorderColor = _isHovered && isInteractive
        ? AppColors.kPrimary300
        : (widget.borderColor ?? AppColors.kNeutral200);

    return MouseRegion(
      onEnter: isInteractive ? (_) => setState(() => _isHovered = true) : null,
      onExit: isInteractive ? (_) => setState(() => _isHovered = false) : null,
      cursor: isInteractive ? SystemMouseCursors.click : MouseCursor.defer,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        decoration: BoxDecoration(
          color: effectiveBackgroundColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: widget.border ?? Border.all(color: effectiveBorderColor, width: _isHovered && isInteractive ? 1.3 : 1.0),
          boxShadow: widget.showShadow
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: _isHovered && isInteractive ? 0.07 : 0.035),
                    blurRadius: _isHovered && isInteractive ? 16.0 : 12.0,
                    offset: Offset(0, _isHovered && isInteractive ? 6 : 3),
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
            highlightColor: Theme.of(context).primaryColor.withValues(alpha: 0.04),
            splashColor: Theme.of(context).primaryColor.withValues(alpha: 0.08),
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
