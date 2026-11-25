import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/report_model.dart';
import 'status_badge.dart';

class MetricTile extends StatelessWidget {
  final ReportParameter parameter;

  const MetricTile({
    super.key,
    required this.parameter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(parameter.name, style: AppTypography.h3),
                    const SizedBox(height: 2),
                    Text(
                      parameter.explanation,
                      style: AppTypography.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    parameter.value,
                    style: AppTypography.measurementValue,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Ref: ${parameter.referenceRange}",
                    style: AppTypography.measurementRef,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusBadge(status: parameter.status, compact: true),
              if (parameter.biologicalLimitations.isNotEmpty)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      parameter.biologicalLimitations,
                      style: AppTypography.caption.copyWith(fontSize: 10, fontStyle: FontStyle.italic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
