import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/vitals_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/charts/line_chart_widget.dart';
import '../../models/vital_sign.dart';
import '../../core/constants/constants.dart';

class VitalsDetailScreen extends StatefulWidget {
  const VitalsDetailScreen({Key? key}) : super(key: key);

  @override
  State<VitalsDetailScreen> createState() => _VitalsDetailScreenState();
}

class _VitalsDetailScreenState extends State<VitalsDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTimeRange = '24h';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final vitalsProvider = Provider.of<VitalsProvider>(context, listen: false);
    final userId = authProvider.userId ?? '1';
    
    final now = DateTime.now();
    DateTime startTime;
    
    switch (_selectedTimeRange) {
      case '24h':
        startTime = now.subtract(const Duration(hours: 24));
        break;
      case '7d':
        startTime = now.subtract(const Duration(days: 7));
        break;
      case '30d':
        startTime = now.subtract(const Duration(days: 30));
        break;
      default:
        startTime = now.subtract(const Duration(hours: 24));
    }
    
    await vitalsProvider.loadHistoricalVitals(
      userId: userId,
      startTime: startTime,
      endTime: now,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Vital Signs', style: AppTextStyles.header3),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.pinkPrimary,
          labelColor: AppColors.pinkPrimary,
          unselectedLabelColor: AppColors.mediumGray,
          labelStyle: AppTextStyles.bodyMedium,
          tabs: const [
            Tab(text: 'Heart Rate'),
            Tab(text: 'SpO₂'),
            Tab(text: 'Temperature'),
          ],
        ),
      ),
      body: Consumer<VitalsProvider>(
        builder: (context, vitalsProvider, _) {
          if (vitalsProvider.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.pinkPrimary),
              ),
            );
          }

          return Column(
            children: [
              _buildTimeRangeSelector(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildVitalTab(
                      vitalsProvider.historicalVitals,
                      'heartRate',
                      'Heart Rate',
                      'BPM',
                      AppColors.pinkPrimary,
                      Icons.favorite,
                    ),
                    _buildVitalTab(
                      vitalsProvider.historicalVitals,
                      'spo2',
                      'Blood Oxygen',
                      '%',
                      AppColors.infoBlue,
                      Icons.air,
                    ),
                    _buildVitalTab(
                      vitalsProvider.historicalVitals,
                      'temperature',
                      'Body Temperature',
                      '°C',
                      AppColors.warningOrange,
                      Icons.thermostat,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text('Time Range:', style: AppTextStyles.bodyMedium),
          const SizedBox(width: 16),
          _buildTimeRangeChip('24h', '24 Hours'),
          const SizedBox(width: 8),
          _buildTimeRangeChip('7d', '7 Days'),
          const SizedBox(width: 8),
          _buildTimeRangeChip('30d', '30 Days'),
        ],
      ),
    );
  }

  Widget _buildTimeRangeChip(String value, String label) {
    final isSelected = _selectedTimeRange == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTimeRange = value;
        });
        _loadData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : AppColors.secondaryDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.pinkPrimary.withAlpha(76),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildVitalTab(
    List<VitalSign> vitals,
    String vitalType,
    String title,
    String unit,
    Color color,
    IconData icon,
  ) {
    if (vitals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.mediumGray),
            const SizedBox(height: 16),
            Text(
              'No data available for $_selectedTimeRange',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mediumGray),
            ),
          ],
        ),
      );
    }

    final vitalsProvider = Provider.of<VitalsProvider>(context, listen: false);
    double avgValue, minValue, maxValue;
    
    switch (vitalType) {
      case 'heartRate':
        avgValue = vitalsProvider.getAverageHeartRate(vitals);
        final minMax = vitalsProvider.getMinMaxHeartRate(vitals);
        minValue = minMax['min']!;
        maxValue = minMax['max']!;
        break;
      case 'spo2':
        avgValue = vitalsProvider.getAverageSpO2(vitals);
        final minMax = vitalsProvider.getMinMaxSpO2(vitals);
        minValue = minMax['min']!;
        maxValue = minMax['max']!;
        break;
      case 'temperature':
        avgValue = vitalsProvider.getAverageTemperature(vitals);
        final minMax = vitalsProvider.getMinMaxTemperature(vitals);
        minValue = minMax['min']!;
        maxValue = minMax['max']!;
        break;
      default:
        avgValue = minValue = maxValue = 0;
    }

    // Aggregate data by day for week/month views
    final displayData = _selectedTimeRange == '24h' ? vitals : _aggregateDailyVitals(vitals, vitalType);
    final chartTitle = _selectedTimeRange == '24h' ? '$title Trend' : '$title Trend (Daily Avg)';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Value Hero Card
          _buildCurrentValueCard(vitals.first, vitalType, unit, color, icon),
          const SizedBox(height: 16),
          
          // Statistics Cards
          _buildStatisticsCards(avgValue, minValue, maxValue, unit, color),
          const SizedBox(height: 24),
          
          // Trend Chart
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secondaryDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withAlpha(76)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: color, size: 24),
                        const SizedBox(width: 12),
                        Text(chartTitle, style: AppTextStyles.header3),
                      ],
                    ),
                    Icon(Icons.trending_up, color: color, size: 20),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 250,
                  child: LineChartWidget(
                    data: displayData,
                    vitalType: vitalType,
                    color: color,
                    unit: unit,
                    showDays: _selectedTimeRange != '24h',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Distribution Analysis
          _buildDistributionCard(vitals, vitalType, unit, color, icon),
          const SizedBox(height: 24),
          
          // Health Zone Analysis
          _buildHealthZoneCard(vitals, vitalType, color, avgValue),
          const SizedBox(height: 24),
          
          // Insights Card
          _buildInsightsCard(vitals, vitalType, avgValue, minValue, maxValue, color, icon),
          const SizedBox(height: 24),
          
          // Recent Readings Table
          _buildReadingsTable(vitals, vitalType, unit, color),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards(double avg, double min, double max, String unit, Color color) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('Average', avg.toStringAsFixed(1), unit, color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Min', min.toStringAsFixed(1), unit, AppColors.infoBlue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Max', max.toStringAsFixed(1), unit, AppColors.warningOrange),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Column(
        children: [
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.mediumGray)),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.header2.copyWith(color: color)),
          Text(unit, style: AppTextStyles.caption.copyWith(color: AppColors.mediumGray)),
        ],
      ),
    );
  }

  Widget _buildCurrentValueCard(VitalSign vital, String vitalType, String unit, Color color, IconData icon) {
    double value;
    String status;
    Color statusColor;
    
    switch (vitalType) {
      case 'heartRate':
        value = vital.heartRate?.toDouble() ?? 0;
        if (value > AppConstants.criticalHRHigh || value < AppConstants.criticalHRLow) {
          status = 'CRITICAL';
          statusColor = AppColors.emergencyRed;
        } else if (value > AppConstants.warningRestingHRHigh || value < 60) {
          status = 'WARNING';
          statusColor = AppColors.warningOrange;
        } else {
          status = 'NORMAL';
          statusColor = AppColors.successGreen;
        }
        break;
      case 'spo2':
        value = vital.spo2?.toDouble() ?? 0;
        if (value < AppConstants.criticalSpO2) {
          status = 'CRITICAL';
          statusColor = AppColors.emergencyRed;
        } else if (value < AppConstants.warningSpO2) {
          status = 'WARNING';
          statusColor = AppColors.warningOrange;
        } else {
          status = 'NORMAL';
          statusColor = AppColors.successGreen;
        }
        break;
      case 'temperature':
        value = vital.temperature ?? 0;
        if (value > AppConstants.criticalTempHigh || value < AppConstants.warningTempLow) {
          status = 'CRITICAL';
          statusColor = AppColors.emergencyRed;
        } else if (value > AppConstants.warningTempHigh) {
          status = 'WARNING';
          statusColor = AppColors.warningOrange;
        } else {
          status = 'NORMAL';
          statusColor = AppColors.successGreen;
        }
        break;
      default:
        value = 0;
        status = 'UNKNOWN';
        statusColor = AppColors.mediumGray;
    }
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withAlpha(48), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withAlpha(48),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Reading', style: AppTextStyles.bodySmall.copyWith(color: AppColors.mediumGray)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value.toStringAsFixed(vitalType == 'temperature' ? 1 : 0),
                      style: AppTextStyles.header1.copyWith(color: color, fontSize: 48),
                    ),
                    const SizedBox(width: 8),
                    Text(unit, style: AppTextStyles.header3.copyWith(color: color)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(48),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withAlpha(128)),
                  ),
                  child: Text(
                    status,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionCard(List<VitalSign> vitals, String vitalType, String unit, Color color, IconData icon) {
    // Calculate distribution ranges
    Map<String, int> distribution = {};
    
    for (var vital in vitals) {
      double value;
      switch (vitalType) {
        case 'heartRate':
          value = vital.heartRate?.toDouble() ?? 0;
          if (value < 60) distribution['< 60'] = (distribution['< 60'] ?? 0) + 1;
          else if (value < 100) distribution['60-100'] = (distribution['60-100'] ?? 0) + 1;
          else if (value < 140) distribution['100-140'] = (distribution['100-140'] ?? 0) + 1;
          else distribution['> 140'] = (distribution['> 140'] ?? 0) + 1;
          break;
        case 'spo2':
          value = vital.spo2?.toDouble() ?? 0;
          if (value < 90) distribution['< 90%'] = (distribution['< 90%'] ?? 0) + 1;
          else if (value < 95) distribution['90-95%'] = (distribution['90-95%'] ?? 0) + 1;
          else if (value < 98) distribution['95-98%'] = (distribution['95-98%'] ?? 0) + 1;
          else distribution['98-100%'] = (distribution['98-100%'] ?? 0) + 1;
          break;
        case 'temperature':
          value = vital.temperature ?? 0;
          if (value < 36.0) distribution['< 36°C'] = (distribution['< 36°C'] ?? 0) + 1;
          else if (value < 37.5) distribution['36-37.5°C'] = (distribution['36-37.5°C'] ?? 0) + 1;
          else if (value < 38.0) distribution['37.5-38°C'] = (distribution['37.5-38°C'] ?? 0) + 1;
          else distribution['> 38°C'] = (distribution['> 38°C'] ?? 0) + 1;
          break;
      }
    }
    
    final maxCount = distribution.values.isEmpty ? 1 : distribution.values.reduce(math.max);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondaryDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: color, size: 24),
              const SizedBox(width: 12),
              Text('Distribution Analysis', style: AppTextStyles.header3),
            ],
          ),
          const SizedBox(height: 20),
          ...distribution.entries.map((entry) {
            final percentage = (entry.value / vitals.length * 100);
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key, style: AppTextStyles.bodyMedium),
                      Text(
                        '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                        style: AppTextStyles.bodySmall.copyWith(color: color),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: entry.value / maxCount,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color, color.withAlpha(144)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildHealthZoneCard(List<VitalSign> vitals, String vitalType, Color color, double avgValue) {
    String zoneName;
    Color zoneColor;
    String zoneDescription;
    IconData zoneIcon;
    
    switch (vitalType) {
      case 'heartRate':
        if (avgValue > 150) {
          zoneName = 'Maximum Intensity';
          zoneColor = AppColors.emergencyRed;
          zoneDescription = 'Sustained high intensity - ensure proper recovery';
          zoneIcon = Icons.warning_amber_rounded;
        } else if (avgValue > 120) {
          zoneName = 'High Intensity';
          zoneColor = AppColors.warningOrange;
          zoneDescription = 'Vigorous exercise zone - great for fitness';
          zoneIcon = Icons.fitness_center;
        } else if (avgValue > 100) {
          zoneName = 'Moderate Activity';
          zoneColor = AppColors.infoBlue;
          zoneDescription = 'Ideal for cardio and fat burning';
          zoneIcon = Icons.directions_run;
        } else if (avgValue > 80) {
          zoneName = 'Light Activity';
          zoneColor = AppColors.successGreen;
          zoneDescription = 'Perfect for warm-up and recovery';
          zoneIcon = Icons.directions_walk;
        } else {
          zoneName = 'Resting';
          zoneColor = AppColors.pinkPrimary;
          zoneDescription = 'Recovery and relaxation zone';
          zoneIcon = Icons.hotel;
        }
        break;
      case 'spo2':
        if (avgValue >= 98) {
          zoneName = 'Excellent';
          zoneColor = AppColors.successGreen;
          zoneDescription = 'Optimal oxygen saturation levels';
          zoneIcon = Icons.check_circle;
        } else if (avgValue >= 95) {
          zoneName = 'Good';
          zoneColor = AppColors.infoBlue;
          zoneDescription = 'Normal oxygen saturation';
          zoneIcon = Icons.thumb_up;
        } else if (avgValue >= 90) {
          zoneName = 'Fair';
          zoneColor = AppColors.warningOrange;
          zoneDescription = 'Consider consulting healthcare provider';
          zoneIcon = Icons.info;
        } else {
          zoneName = 'Critical';
          zoneColor = AppColors.emergencyRed;
          zoneDescription = 'Seek immediate medical attention';
          zoneIcon = Icons.warning;
        }
        break;
      case 'temperature':
        if (avgValue >= 38.0) {
          zoneName = 'Fever';
          zoneColor = AppColors.emergencyRed;
          zoneDescription = 'Elevated temperature - monitor closely';
          zoneIcon = Icons.local_fire_department;
        } else if (avgValue >= 37.5) {
          zoneName = 'Slightly Elevated';
          zoneColor = AppColors.warningOrange;
          zoneDescription = 'Mildly above normal range';
          zoneIcon = Icons.thermostat;
        } else if (avgValue >= 36.1) {
          zoneName = 'Normal';
          zoneColor = AppColors.successGreen;
          zoneDescription = 'Healthy body temperature';
          zoneIcon = Icons.check_circle;
        } else {
          zoneName = 'Low';
          zoneColor = AppColors.infoBlue;
          zoneDescription = 'Below normal - stay warm';
          zoneIcon = Icons.ac_unit;
        }
        break;
      default:
        zoneName = 'Unknown';
        zoneColor = AppColors.mediumGray;
        zoneDescription = 'No data';
        zoneIcon = Icons.help;
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [zoneColor.withOpacity(0.15), zoneColor.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: zoneColor.withAlpha(76), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: zoneColor.withAlpha(48),
              shape: BoxShape.circle,
            ),
            child: Icon(zoneIcon, size: 32, color: zoneColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Health Zone', style: AppTextStyles.bodySmall.copyWith(color: AppColors.mediumGray)),
                const SizedBox(height: 4),
                Text(zoneName, style: AppTextStyles.header3.copyWith(color: zoneColor)),
                const SizedBox(height: 8),
                Text(
                  zoneDescription,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.lightGray),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsCard(List<VitalSign> vitals, String vitalType, double avg, double min, double max, Color color, IconData icon) {
    List<String> insights = [];
    
    // Calculate variability
    final range = max - min;
    final variability = (range / avg * 100);
    
    switch (vitalType) {
      case 'heartRate':
        insights.add('Average heart rate: ${avg.toStringAsFixed(0)} BPM');
        insights.add('Range: ${min.toStringAsFixed(0)} - ${max.toStringAsFixed(0)} BPM');
        if (variability > 50) {
          insights.add('High variability detected - may indicate stress or varied activity levels');
        } else {
          insights.add('Stable heart rate pattern observed');
        }
        if (avg < 60) {
          insights.add('Lower than average resting heart rate - could indicate good cardiovascular fitness');
        } else if (avg > 100) {
          insights.add('Elevated average heart rate - consider stress management or medical consultation');
        }
        break;
      case 'spo2':
        insights.add('Average oxygen saturation: ${avg.toStringAsFixed(1)}%');
        insights.add('Range: ${min.toStringAsFixed(1)} - ${max.toStringAsFixed(1)}%');
        if (min < 95) {
          insights.add('Some readings below optimal range - monitor breathing patterns');
        } else {
          insights.add('Consistently healthy oxygen saturation levels');
        }
        if (variability > 5) {
          insights.add('Notable fluctuations detected - ensure proper sensor placement');
        }
        break;
      case 'temperature':
        insights.add('Average temperature: ${avg.toStringAsFixed(1)}°C');
        insights.add('Range: ${min.toStringAsFixed(1)} - ${max.toStringAsFixed(1)}°C');
        if (avg > 37.5) {
          insights.add('Elevated temperature detected - stay hydrated and monitor');
        } else if (avg < 36.0) {
          insights.add('Lower temperature readings - ensure warmth and proper circulation');
        } else {
          insights.add('Temperature within healthy normal range');
        }
        break;
    }
    
    // Time-based insights
    final duration = vitals.length * 5; // Assuming 5-second intervals
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    insights.add('Data collected over ${hours}h ${minutes}m from ${vitals.length} readings');
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondaryDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: color, size: 24),
              const SizedBox(width: 12),
              Text('AI Insights', style: AppTextStyles.header3),
            ],
          ),
          const SizedBox(height: 16),
          ...insights.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.lightGray),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildReadingsTable(List<VitalSign> vitals, String vitalType, String unit, Color color) {
    final recentVitals = vitals.take(10).toList();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Readings', style: AppTextStyles.header3),
              Text('${recentVitals.length} entries', style: AppTextStyles.caption.copyWith(color: AppColors.mediumGray)),
            ],
          ),
          const SizedBox(height: 16),
          ...recentVitals.asMap().entries.map((entry) {
            final index = entry.key;
            final vital = entry.value;
            double value;
            switch (vitalType) {
              case 'heartRate':
                value = vital.heartRate?.toDouble() ?? 0;
                break;
              case 'spo2':
                value = vital.spo2?.toDouble() ?? 0;
                break;
              case 'temperature':
                value = vital.temperature ?? 0;
                break;
              default:
                value = 0;
            }
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: color.withAlpha(48),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        () {
                          final dt = DateTime.fromMillisecondsSinceEpoch(vital.timestamp);
                          return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                        }(),
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mediumGray),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withAlpha(48),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withAlpha(76)),
                    ),
                    child: Text(
                      '${value.toStringAsFixed(vitalType == 'temperature' ? 1 : 0)} $unit',
                      style: AppTextStyles.bodyMedium.copyWith(color: color, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // Aggregate vitals by day for weekly/monthly views
  List<VitalSign> _aggregateDailyVitals(List<VitalSign> vitals, String vitalType) {
    if (vitals.isEmpty) return [];

    // Group by day
    final Map<String, List<VitalSign>> dailyGroups = {};
    for (final vital in vitals) {
      final date = DateTime.fromMillisecondsSinceEpoch(vital.timestamp);
      final dayKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      dailyGroups.putIfAbsent(dayKey, () => []).add(vital);
    }

    // Calculate daily averages
    final List<VitalSign> dailyAggregated = [];
    for (final entry in dailyGroups.entries) {
      final dayVitals = entry.value;
      if (dayVitals.isEmpty) continue;

      // Calculate averages
      final avgHeartRate = dayVitals
          .where((v) => v.heartRate != null)
          .map((v) => v.heartRate!)
          .fold<double>(0, (sum, val) => sum + val) / 
          dayVitals.where((v) => v.heartRate != null).length;
      
      final avgSpO2 = dayVitals
          .where((v) => v.spo2 != null)
          .map((v) => v.spo2!)
          .fold<double>(0, (sum, val) => sum + val) / 
          dayVitals.where((v) => v.spo2 != null).length;
      
      final avgTemp = dayVitals
          .where((v) => v.temperature != null)
          .map((v) => v.temperature!)
          .fold<double>(0, (sum, val) => sum + val) / 
          dayVitals.where((v) => v.temperature != null).length;

      // Use noon of that day as timestamp for visual clarity
      final date = DateTime.parse(entry.key);
      final dayTimestamp = DateTime(date.year, date.month, date.day, 12).millisecondsSinceEpoch;

      dailyAggregated.add(VitalSign(
        userId: dayVitals.first.userId,
        timestamp: dayTimestamp,
        heartRate: avgHeartRate.isNaN ? null : avgHeartRate.round(),
        spo2: avgSpO2.isNaN ? null : avgSpO2.round(),
        temperature: avgTemp.isNaN ? null : avgTemp,
      ));
    }

    // Sort by timestamp
    dailyAggregated.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return dailyAggregated;
  }
}
