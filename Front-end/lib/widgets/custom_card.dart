import 'package:flutter/material.dart';

class CustomCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final List<Color>? gradient;
  final Color? backgroundColor;
  final double? borderRadius;
  final BorderSide? borderSide;
  final EdgeInsetsGeometry? padding;
  final bool hasShadow;

  const CustomCard({
    Key? key,
    required this.child,
    this.onTap,
    this.gradient,
    this.backgroundColor,
    this.borderRadius,
    this.borderSide,
    this.padding,
    this.hasShadow = true,
  }) : super(key: key);

  @override
  State<CustomCard> createState() => _CustomCardState();
}

class _CustomCardState extends State<CustomCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultBg = isDark
        ? theme.cardColor
        : Colors.white;

    final defaultBorder = isDark
        ? BorderSide(color: theme.dividerColor, width: 1)
        : BorderSide(color: theme.dividerColor, width: 1);

    final cardBorderRadius = BorderRadius.circular(widget.borderRadius ?? 16);

    Widget cardWidget = Container(
      padding: widget.padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.gradient != null ? null : (widget.backgroundColor ?? defaultBg),
        gradient: widget.gradient != null
            ? LinearGradient(
                colors: widget.gradient!,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: cardBorderRadius,
        border: widget.borderSide != null
            ? Border.fromBorderSide(widget.borderSide!)
            : widget.gradient != null
                ? null
                : Border.fromBorderSide(defaultBorder),
        boxShadow: widget.hasShadow
            ? [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.15)
                      : Colors.black.withOpacity(0.01),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: widget.child,
    );

    if (widget.onTap != null) {
      cardWidget = Semantics(
        button: true,
        enabled: true,
        child: GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          onTap: widget.onTap,
          child: ScaleTransition(
            scale: _scale,
            child: cardWidget,
          ),
        ),
      );
    }

    return cardWidget;
  }
}
