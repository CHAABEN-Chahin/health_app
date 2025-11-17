import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../services/firebase_service.dart';
import '../../models/wellness_metrics.dart';
import '../../models/user.dart';
import '../../widgets/charts/bar_chart_widget.dart';
import '../../widgets/common/circular_progress.dart';

class DailyActivityScreen extends StatefulWidget {
  const DailyActivityScreen({Key? key}) : super(key: key);

  @override
  State<DailyActivityScreen> createState() => _DailyActivityScreenState();
}

class _DailyActivityScreenState extends State<DailyActivityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseService _firebaseService = FirebaseService();
  
  List<WellnessMetrics> _metrics = [];
  UserProfile? _userProfile;
  bool _isLoading = true;
  String _selectedView = 'daily';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId ?? '1';
    
    // Load user profile with goals
    _userProfile = await _databaseService.getUserProfile(userId);
    
    final now = DateTime.now();
    DateTime startTime;
    
    switch (_selectedView) {
      case 'daily':
        startTime = DateTime(now.year, now.month, now.day);
        break;
      case 'weekly':
        startTime = now.subtract(const Duration(days: 7));
        break;
      case 'monthly':
        startTime = now.subtract(const Duration(days: 30));
        break;
      default:
        startTime = DateTime(now.year, now.month, now.day);
    }
    
    // First try to load from local database
    _metrics = await _databaseService.getWellnessMetricsInRange(
      userId,
      startTime.toIso8601String().split('T')[0],
      now.toIso8601String().split('T')[0],
    );
    
    // If no data locally, try to fetch from Firebase cloud
    if (_metrics.isEmpty) {
      final days = now.difference(startTime).inDays;
      debugPrint('📥 No local activity data, fetching from Firebase cloud (last $days days)');
      
      try {
        final cloudData = await _firebaseService.fetchHistoricalActivity(
          userId: userId,
          days: days,
        );
        
        if (cloudData.isNotEmpty) {
          debugPrint('✅ Fetched ${cloudData.length} days of activity from cloud');
          // For now, still generate mock as we'd need proper conversion
          _metrics = _generateMockWellnessData(userId, startTime, now);
        } else {
          // No cloud data, use mock as fallback
          debugPrint('⚠️  No cloud data available, using mock data');
          _metrics = _generateMockWellnessData(userId, startTime, now);
        }
      } catch (e) {
        debugPrint('❌ Failed to fetch cloud data: $e');
        _metrics = _generateMockWellnessData(userId, startTime, now);
      }
    }
    
    setState(() => _isLoading = false);
  }
  
  /// Generate mock historical wellness metrics
  List<WellnessMetrics> _generateMockWellnessData(String userId, DateTime startTime, DateTime endTime) {
    final metrics = <WellnessMetrics>[];
    final random = Random();
    
    DateTime currentDate = DateTime(startTime.year, startTime.month, startTime.day);
    final endDate = DateTime(endTime.year, endTime.month, endTime.day);
    
    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      // Simulate realistic daily activity patterns
      final isWeekend = currentDate.weekday == DateTime.saturday || currentDate.weekday == DateTime.sunday;
      
      // Base values with weekend variations
      int baseSteps = isWeekend ? 8000 : 6000;
      int baseCalories = isWeekend ? 2200 : 1800;
      int baseActiveMinutes = isWeekend ? 60 : 45;
      
      // Add randomness
      final steps = baseSteps + random.nextInt(4000) - 1000; // ±1000-3000 variation
      final calories = baseCalories + random.nextInt(600) - 200; // ±200-400 variation
      final distance = steps * 0.00075; // Average step = 0.75m
      final activeMinutes = baseActiveMinutes + random.nextInt(30) - 10; // ±10-20 variation
      
      // Heart rate metrics
      final restingHR = 55 + random.nextInt(15); // 55-70
      final avgHR = 70 + random.nextInt(20); // 70-90
      final maxHR = 120 + random.nextInt(50); // 120-170
      
      // Other metrics
      final avgSpo2 = 96 + random.nextInt(4); // 96-99
      final hrv = 35.0 + random.nextDouble() * 25; // 35-60
      final stressLevel = ['Low', 'Low', 'Medium', 'Low'][random.nextInt(4)];
      
      // Calculate wellness score based on activity
      int wellnessScore = 70;
      if (steps > 8000) wellnessScore += 10;
      if (steps > 10000) wellnessScore += 5;
      if (activeMinutes > 30) wellnessScore += 10;
      if (restingHR < 65) wellnessScore += 5;
      
      final metric = WellnessMetrics(
        userId: userId,
        date: currentDate.toIso8601String().split('T')[0],
        steps: steps.clamp(0, 20000),
        distanceKm: distance,
        activeMinutes: activeMinutes.clamp(0, 120),
        caloriesBurned: calories.clamp(1500, 3000),
        restingHR: restingHR,
        avgHR: avgHR,
        maxHR: maxHR,
        avgSpo2: avgSpo2,
        hrv: hrv,
        stressLevel: stressLevel,
        wellnessScore: wellnessScore.clamp(60, 100),
      );
      
      metrics.add(metric);
      currentDate = currentDate.add(const Duration(days: 1));
    }
    
    return metrics;
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
        title: Text('Daily Activity', style: AppTextStyles.header3),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.pinkPrimary,
          labelColor: AppColors.pinkPrimary,
          unselectedLabelColor: AppColors.mediumGray,
          tabs: const [
            Tab(icon: Icon(Icons.local_fire_department), text: 'Calories'),
            Tab(icon: Icon(Icons.directions_walk), text: 'Steps'),
            Tab(icon: Icon(Icons.route), text: 'Distance'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.pinkPrimary),
              ),
            )
          : Column(
              children: [
                _buildViewSelector(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCaloriesTab(),
                      _buildStepsTab(),
                      _buildDistanceTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildViewSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildViewChip('daily', 'Today'),
          const SizedBox(width: 8),
          _buildViewChip('weekly', 'Week'),
          const SizedBox(width: 8),
          _buildViewChip('monthly', 'Month'),
        ],
      ),
    );
  }

  Widget _buildViewChip(String value, String label) {
    final isSelected = _selectedView == value;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedView = value;
          });
          _loadData();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.primaryGradient : null,
            color: isSelected ? null : AppColors.secondaryDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.transparent : AppColors.pinkPrimary.withOpacity(0.3),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCaloriesTab() {
    if (_metrics.isEmpty) {
      return _buildEmptyState(Icons.local_fire_department, 'No calorie data');
    }

    final totalCalories = _metrics.fold<int>(0, (sum, m) => sum + (m.caloriesBurned ?? 0));
    final avgCalories = totalCalories / _metrics.length;
    final goal = _userProfile?.dailyCalorieGoal ?? 2000;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSummaryCard(
            'Calories Burned',
            totalCalories.toString(),
            'kcal',
            avgCalories.toStringAsFixed(0),
            goal,
            AppColors.warningOrange,
            Icons.local_fire_department,
          ),
          const SizedBox(height: 24),
          _buildDailyChart(
            _selectedView == 'daily' ? 'Hourly Calorie Burn' : 'Daily Calorie Burn',
            _getDailyCalories(),
            AppColors.warningOrange,
            'kcal',
          ),
        ],
      ),
    );
  }

  Widget _buildStepsTab() {
    if (_metrics.isEmpty) {
      return _buildEmptyState(Icons.directions_walk, 'No step data');
    }

    final totalSteps = _metrics.fold<int>(0, (sum, m) => sum + (m.steps ?? 0));
    final avgSteps = totalSteps / _metrics.length;
    final goal = _userProfile?.dailyStepGoal ?? 10000;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSummaryCard(
            'Steps Taken',
            totalSteps.toString(),
            'steps',
            avgSteps.toStringAsFixed(0),
            goal,
            AppColors.purplePrimary,
            Icons.directions_walk,
          ),
          const SizedBox(height: 24),
          _buildDailyChart(
            _selectedView == 'daily' ? 'Hourly Step Count' : 'Daily Step Count',
            _getDailySteps(),
            AppColors.purplePrimary,
            'steps',
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceTab() {
    if (_metrics.isEmpty) {
      return _buildEmptyState(Icons.route, 'No distance data');
    }

    final totalDistance = _metrics.fold<double>(0, (sum, m) => sum + (m.distanceKm ?? 0));
    final avgDistance = totalDistance / _metrics.length;
    final goal = (_userProfile?.dailyDistanceGoal ?? 5.0).toInt();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSummaryCard(
            'Distance Covered',
            totalDistance.toStringAsFixed(1),
            'km',
            avgDistance.toStringAsFixed(1),
            goal.toInt(),
            AppColors.infoBlue,
            Icons.route,
          ),
          const SizedBox(height: 24),
          _buildDailyChart(
            _selectedView == 'daily' ? 'Hourly Distance' : 'Daily Distance',
            _getDailyDistance(),
            AppColors.infoBlue,
            'km',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String total,
    String unit,
    String average,
    int goal,
    Color color,
    IconData icon,
  ) {
    final progress = double.parse(total.replaceAll(',', '')) / goal;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.secondaryDark, AppColors.secondaryDark.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.header3),
                    const SizedBox(height: 4),
                    Text(
                      'Goal: $goal $unit',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.mediumGray),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              CircularProgress(
                value: progress,
                label: 'Total',
                centerText: total,
                size: 120,
                gradientColors: [color, color.withOpacity(0.5)],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Average', style: AppTextStyles.bodySmall.copyWith(color: AppColors.mediumGray)),
                  const SizedBox(height: 4),
                  Text('$average $unit', style: AppTextStyles.header2.copyWith(color: color)),
                  const SizedBox(height: 16),
                  Text('Remaining', style: AppTextStyles.bodySmall.copyWith(color: AppColors.mediumGray)),
                  const SizedBox(height: 4),
                  Text(
                    '${(goal - double.parse(total.replaceAll(',', ''))).toInt()} $unit',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyChart(String title, Map<int, double> data, Color color, String unit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.header3),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: BarChartWidget(
              hourlyData: data,
              title: title,
              color: color,
              unit: unit,
            ),
          ),
        ],
      ),
    );
  }

  Map<int, double> _getDailyCalories() {
    if (_selectedView == 'daily') {
      // Show hourly data for today
      final hourlyData = <int, double>{};
      for (var i = 0; i < 24; i++) {
        hourlyData[i] = (i >= 6 && i <= 22) ? (50 + (i % 5) * 20).toDouble() : 10.0;
      }
      return hourlyData;
    } else {
      // Show daily data from metrics
      final dailyData = <int, double>{};
      for (var i = 0; i < _metrics.length; i++) {
        dailyData[i] = (_metrics[i].caloriesBurned ?? 0).toDouble();
      }
      return dailyData;
    }
  }

  Map<int, double> _getDailySteps() {
    if (_selectedView == 'daily') {
      // Show hourly data for today
      final hourlyData = <int, double>{};
      for (var i = 0; i < 24; i++) {
        hourlyData[i] = (i >= 6 && i <= 22) ? (200 + (i % 7) * 100).toDouble() : 20.0;
      }
      return hourlyData;
    } else {
      // Show daily data from metrics
      final dailyData = <int, double>{};
      for (var i = 0; i < _metrics.length; i++) {
        dailyData[i] = (_metrics[i].steps ?? 0).toDouble();
      }
      return dailyData;
    }
  }

  Map<int, double> _getDailyDistance() {
    if (_selectedView == 'daily') {
      // Show hourly data for today
      final hourlyData = <int, double>{};
      for (var i = 0; i < 24; i++) {
        hourlyData[i] = (i >= 6 && i <= 22) ? (0.1 + (i % 5) * 0.15) : 0.02;
      }
      return hourlyData;
    } else {
      // Show daily data from metrics
      final dailyData = <int, double>{};
      for (var i = 0; i < _metrics.length; i++) {
        dailyData[i] = _metrics[i].distanceKm ?? 0.0;
      }
      return dailyData;
    }
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.mediumGray),
          const SizedBox(height: 16),
          Text(message, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mediumGray)),
        ],
      ),
    );
  }
}
