import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool compact;

  const StatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final lower = status.toLowerCase();
    Color bgColor;
    Color textColor;
    Color borderColor;
    IconData icon;
    String labelText;

    if (lower.contains("high")) {
      bgColor = AppColors.criticalLight;
      textColor = AppColors.critical;
      borderColor = AppColors.criticalBorder;
      icon = Icons.arrow_upward_rounded;
      labelText = compact ? "High" : "High (Out of Range)";
    } else if (lower.contains("low")) {
      bgColor = const Color(0xFFEFF6FF); // Soft Muted Blue
      textColor = const Color(0xFF1D4ED8);
      borderColor = const Color(0xFFBFDBFE);
      icon = Icons.arrow_downward_rounded;
      labelText = compact ? "Low" : "Low (Out of Range)";
    } else if (lower.contains("border") || lower.contains("warn")) {
      bgColor = AppColors.warningLight;
      textColor = AppColors.warning;
      borderColor = AppColors.warningBorder;
      icon = Icons.warning_amber_rounded;
      labelText = compact ? "Borderline" : "Borderline";
    } else {
      bgColor = AppColors.successLight;
      textColor = AppColors.success;
      borderColor = AppColors.successBorder;
      icon = Icons.check_circle_outline_rounded;
      labelText = "Normal Range";
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 12 : 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            labelText,
            style: AppTypography.badge.copyWith(color: textColor, fontSize: compact ? 10 : 11),
          ),
        ],
      ),
    );
  }
}
