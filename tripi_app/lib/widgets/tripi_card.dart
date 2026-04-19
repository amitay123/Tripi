import 'package:flutter/material.dart';
import '../theme/tripi_colors.dart';

class TripiCard extends StatelessWidget {
  final Widget child;
  final double? height;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const TripiCard({
    super.key,
    required this.child,
    this.height,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: TripiColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: TripiColors.onSurface.withOpacity(0.04),
              blurRadius: 32,
              offset: const Offset(0, 12),
              spreadRadius: -4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: child,
        ),
      ),
    );
  }
}
