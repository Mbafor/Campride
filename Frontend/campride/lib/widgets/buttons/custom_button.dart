import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum ButtonVariant { primary, secondary, outline, ghost }

class CustomButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonVariant variant;
  final Widget? icon;
  final double? width;
  final double height;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.width,
    this.height = 54,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _controller.reverse();
  void _onTapUp(_) => _controller.forward();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDisabled = widget.onPressed == null || widget.isLoading;

    Color bgColor;
    Color fgColor;
    Border? border;

    switch (widget.variant) {
      case ButtonVariant.primary:
        bgColor = scheme.primary;
        fgColor = scheme.onPrimary;
        break;
      case ButtonVariant.secondary:
        bgColor = scheme.secondary;
        fgColor = scheme.onSecondary;
        break;
      case ButtonVariant.outline:
        bgColor = Colors.transparent;
        fgColor = scheme.primary;
        border = Border.all(color: scheme.primary, width: 2);
        break;
      case ButtonVariant.ghost:
        bgColor = Colors.transparent;
        fgColor = scheme.primary;
        break;
    }

    return GestureDetector(
      onTapDown: isDisabled ? null : _onTapDown,
      onTapUp: isDisabled ? null : _onTapUp,
      onTapCancel: () => _controller.forward(),
      onTap: isDisabled ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            color: isDisabled ? bgColor.withOpacity(0.6) : bgColor,
            borderRadius: BorderRadius.circular(12),
            border: border,
            boxShadow: widget.variant == ButtonVariant.primary && !isDisabled
                ? [BoxShadow(color: scheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                : null,
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: fgColor,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        IconTheme(data: IconThemeData(color: fgColor, size: 20), child: widget.icon!),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: fgColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
