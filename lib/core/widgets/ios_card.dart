import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class IOSCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final bool glassEffect;

  const IOSCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.glassEffect = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget content = Container(
      padding: padding ?? const EdgeInsets.all(AppTheme.spaceM),
      decoration: BoxDecoration(
        color: glassEffect
            ? (isDark
                  ? Colors.grey.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.7))
            : (isDark ? AppTheme.darkSurface : AppTheme.lightSurface),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: glassEffect ? [] : AppTheme.shadowXS,
      ),
      child: child,
    );

    if (glassEffect) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: content,
        ),
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: MouseRegion(cursor: SystemMouseCursors.click, child: content),
      );
    }

    return content;
  }
}
