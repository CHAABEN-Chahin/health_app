import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../models/vital_sign.dart';

class LineChartWidget extends StatelessWidget {
  final List<VitalSign> data;
  final String vitalType; // 'heartRate', 'spo2', 'temperature'
  final Color color;
  final String unit;
  final double? minY;
  final double? maxY;
  final bool showDays;

  const LineChartWidget({
    Key? key,
    required this.data,
    required this.vitalType,
    required this.color,
    required this.unit,
    this.minY,
    this.maxY,
    this.showDays = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mediumGray),
        ),
      );
    }

    final spots = _getSpots();
    final calculatedMinY = minY ?? _calculateMinY(spots);
    final calculatedMaxY = maxY ?? _calculateMaxY(spots);

    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 16, bottom: 8),
      child: LineChart(
        LineChartData(
          minY: calculatedMinY,
          maxY: calculatedMaxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: spots.length < 20,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: color,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    color.withAlpha(76),
                    color.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
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
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) return const SizedBox();
                  
                  final timestamp = data[index].timestamp;
                  final time = DateTime.fromMillisecondsSinceEpoch(timestamp);
                  final showLabel = _shouldShowTimeLabel(index, data.length);
                  
                  if (!showLabel) return const SizedBox();
                  
                  String labelText;
                  if (showDays) {
                    labelText = '${time.month}/${time.day}';
                  } else {
                    labelText = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      labelText,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.mediumGray,
                        fontSize: 10,
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
            horizontalInterval: (calculatedMaxY - calculatedMinY) / 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppColors.mediumGray.withAlpha(24),
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: AppColors.secondaryDark,
              tooltipBorder: BorderSide(color: color, width: 1),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.toInt();
                  if (index < 0 || index >= data.length) return null;
                  
                  final vital = data[index];
                  final timestamp = vital.timestamp;
                  final time = DateTime.fromMillisecondsSinceEpoch(timestamp);
                  
                  String timeLabel;
                  if (showDays) {
                    timeLabel = '${time.month}/${time.day}';
                  } else {
                    timeLabel = '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
                  }
                  
                  return LineTooltipItem(
                    '${spot.y.toStringAsFixed(1)} $unit\n$timeLabel',
                    AppTextStyles.bodySmall.copyWith(color: Colors.white),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  List<FlSpot> _getSpots() {
    return List.generate(data.length, (index) {
      final vital = data[index];
      double yValue;
      
      switch (vitalType) {
        case 'heartRate':
          yValue = vital.heartRate?.toDouble() ?? 0;
          break;
        case 'spo2':
          yValue = vital.spo2?.toDouble() ?? 0;
          break;
        case 'temperature':
          yValue = vital.temperature ?? 0;
          break;
        default:
          yValue = 0;
      }
      
      return FlSpot(index.toDouble(), yValue);
    });
  }

  double _calculateMinY(List<FlSpot> spots) {
    if (spots.isEmpty) return 0;
    final minValue = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    return (minValue * 0.95).floorToDouble();
  }

  double _calculateMaxY(List<FlSpot> spots) {
    if (spots.isEmpty) return 100;
    final maxValue = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    return (maxValue * 1.05).ceilToDouble();
  }

  bool _shouldShowTimeLabel(int index, int totalCount) {
    if (totalCount <= 6) return true;
    final interval = (totalCount / 6).ceil();
    return index % interval == 0;
  }
}
