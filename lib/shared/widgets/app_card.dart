import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum CardVariant { standard, tonal, sage, elevated }

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final CardVariant variant;
  final VoidCallback? onTap;
  final double borderRadius;
  final Border? customBorder;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.variant = CardVariant.standard,
    this.onTap,
    this.borderRadius = 20,
    this.customBorder,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Border border;
    List<BoxShadow> shadows;

    switch (variant) {
      case CardVariant.standard:
        bgColor = AppColors.surface;
        border = customBorder ?? Border.all(color: AppColors.border, width: 1);
        shadows = const [AppColors.subtleShadow];
        break;
      case CardVariant.tonal:
        bgColor = AppColors.surfaceSubtle;
        border = customBorder ?? Border.all(color: AppColors.border.withValues(alpha: 0.6), width: 1);
        shadows = const [];
        break;
      case CardVariant.sage:
        bgColor = AppColors.surfaceSecondary.withValues(alpha: 0.45);
        border = customBorder ?? Border.all(color: AppColors.surfaceSecondary, width: 1);
        shadows = const [];
        break;
      case CardVariant.elevated:
        bgColor = AppColors.surface;
        border = customBorder ?? Border.all(color: AppColors.border, width: 1);
        shadows = const [AppColors.cardShadow];
        break;
    }

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
        boxShadow: shadows,
      ),
      child: child,
    );

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      );
    }

    return content;
  }
}
