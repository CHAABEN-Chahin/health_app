import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';

class BarChartWidget extends StatelessWidget {
  final Map<int, double> hourlyData; // hour -> value
  final String title;
  final Color color;
  final String unit;

  const BarChartWidget({
    Key? key,
    required this.hourlyData,
    required this.title,
    required this.color,
    required this.unit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (hourlyData.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mediumGray),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 16, bottom: 8),
      child: BarChart(
        BarChartData(
          maxY: _calculateMaxY(),
          barGroups: _getBarGroups(),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.mediumGray,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final hour = value.toInt();
                  if (hour < 0 || hour > 23) return const SizedBox();
                  
                  // Show every 3rd hour
                  if (hour % 3 != 0) return const SizedBox();
                  
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '${hour.toString().padLeft(2, '0')}:00',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.mediumGray,
                        fontSize: 9,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _calculateMaxY() / 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppColors.mediumGray.withAlpha(24),
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: AppColors.secondaryDark,
              tooltipBorder: BorderSide(color: color, width: 1),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final hour = group.x.toInt();
                return BarTooltipItem(
                  '${rod.toY.toStringAsFixed(0)} $unit\n${hour.toString().padLeft(2, '0')}:00',
                  AppTextStyles.bodySmall.copyWith(color: Colors.white),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<BarChartGroupData> _getBarGroups() {
    return List.generate(24, (hour) {
      final value = hourlyData[hour] ?? 0;
      
      return BarChartGroupData(
        x: hour,
        barRods: [
          BarChartRodData(
            toY: value,
            gradient: LinearGradient(
              colors: [color, color.withAlpha(128)],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 12,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    });
  }

  double _calculateMaxY() {
    if (hourlyData.isEmpty) return 100;
    final maxValue = hourlyData.values.reduce((a, b) => a > b ? a : b);
    return (maxValue * 1.2).ceilToDouble();
  }
}
