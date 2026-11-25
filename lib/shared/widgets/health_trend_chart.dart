import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class HealthDataPoint {
  final String date;
  final double value;
  final String displayValue;
  final bool isOutOfRange;

  const HealthDataPoint({
    required this.date,
    required this.value,
    required this.displayValue,
    this.isOutOfRange = false,
  });
}

class HealthTrendChart extends StatefulWidget {
  final String title;
  final String unit;
  final double minReference;
  final double maxReference;
  final List<HealthDataPoint> points;
  final String referenceRangeLabel;

  const HealthTrendChart({
    super.key,
    required this.title,
    required this.unit,
    required this.minReference,
    required this.maxReference,
    required this.points,
    required this.referenceRangeLabel,
  });

  @override
  State<HealthTrendChart> createState() => _HealthTrendChartState();
}

class _HealthTrendChartState extends State<HealthTrendChart> {
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    if (widget.points.isNotEmpty) {
      _selectedIndex = widget.points.length - 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) {
      return const SizedBox.shrink();
    }

    final selected = _selectedIndex != null && _selectedIndex! < widget.points.length
        ? widget.points[_selectedIndex!]
        : widget.points.last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: AppTypography.sectionHeader),
                const SizedBox(height: 2),
                Text(
                  "Normal: ${widget.referenceRangeLabel}",
                  style: AppTypography.measurementRef,
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  selected.displayValue,
                  style: AppTypography.measurementValueLarge.copyWith(
                    color: selected.isOutOfRange ? AppColors.critical : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  widget.unit,
                  style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          width: double.infinity,
          child: GestureDetector(
            onTapDown: (details) {
              final box = context.findRenderObject() as RenderBox?;
              if (box != null && widget.points.length > 1) {
                final localX = details.localPosition.dx;
                final width = box.size.width;
                final step = width / (widget.points.length - 1);
                final index = (localX / step).round().clamp(0, widget.points.length - 1);
                setState(() => _selectedIndex = index);
              }
            },
            child: CustomPaint(
              painter: _ClinicalChartPainter(
                points: widget.points,
                minRef: widget.minReference,
                maxRef: widget.maxReference,
                selectedIndex: _selectedIndex,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: widget.points.map((p) {
            final isSel = widget.points.indexOf(p) == _selectedIndex;
            return Text(
              p.date,
              style: AppTypography.caption.copyWith(
                color: isSel ? AppColors.primary : AppColors.textTertiary,
                fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                fontSize: 10,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ClinicalChartPainter extends CustomPainter {
  final List<HealthDataPoint> points;
  final double minRef;
  final double maxRef;
  final int? selectedIndex;

  _ClinicalChartPainter({
    required this.points,
    required this.minRef,
    required this.maxRef,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    double minVal = minRef;
    double maxVal = maxRef;
    for (final p in points) {
      if (p.value < minVal) minVal = p.value;
      if (p.value > maxVal) maxVal = p.value;
    }

    final span = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);
    final topPadding = size.height * 0.15;
    final bottomPadding = size.height * 0.15;
    final usableHeight = size.height - topPadding - bottomPadding;

    double getY(double val) {
      final ratio = (val - minVal) / span;
      return size.height - bottomPadding - (ratio * usableHeight);
    }

    // 1. Draw Reference Range Corridor (Normal Band)
    final refTop = getY(maxRef);
    final refBottom = getY(minRef);
    final refPaint = Paint()
      ..color = AppColors.surfaceSecondary.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTRB(0, refTop, size.width, refBottom),
      refPaint,
    );

    // Reference boundary guideline
    final guidePaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, refTop), Offset(size.width, refTop), guidePaint);
    canvas.drawLine(Offset(0, refBottom), Offset(size.width, refBottom), guidePaint);

    // 2. Compute Points coordinates
    final coords = <Offset>[];
    final stepX = points.length == 1 ? size.width / 2 : size.width / (points.length - 1);
    for (int i = 0; i < points.length; i++) {
      final x = points.length == 1 ? size.width / 2 : i * stepX;
      final y = getY(points[i].value);
      coords.add(Offset(x, y));
    }

    // 3. Draw Trend Line
    if (coords.length > 1) {
      final linePath = Path();
      linePath.moveTo(coords[0].dx, coords[0].dy);
      for (int i = 1; i < coords.length; i++) {
        final p0 = coords[i - 1];
        final p1 = coords[i];
        final midX = (p0.dx + p1.dx) / 2;
        linePath.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
      }

      final strokePaint = Paint()
        ..color = AppColors.primary
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawPath(linePath, strokePaint);
    }

    // 4. Draw Data Points (Dots)
    for (int i = 0; i < coords.length; i++) {
      final pt = coords[i];
      final isSel = selectedIndex == i;
      final isOut = points[i].isOutOfRange;

      final outerPaint = Paint()
        ..color = isOut ? AppColors.critical : AppColors.primary
        ..style = PaintingStyle.fill;

      final innerPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(pt, isSel ? 6 : 4, outerPaint);
      canvas.drawCircle(pt, isSel ? 3 : 2, innerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ClinicalChartPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex || oldDelegate.points != points;
  }
}
