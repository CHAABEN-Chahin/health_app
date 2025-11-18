import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../widgets/common/gradient_button.dart';
import '../../widgets/common/circular_progress.dart';
import '../../widgets/common/live_indicator.dart';
import '../../widgets/common/debug_scenario_banner.dart';
import '../../widgets/vitals/vital_card.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vitals_provider.dart';
import '../../providers/bluetooth_provider.dart';
import '../../providers/alerts_provider.dart';
import '../../services/database_service.dart';
import '../../models/wellness_metrics.dart';
import '../../models/nutrition_entry.dart';
import '../../models/user.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  WellnessMetrics? _todayMetrics;
  List<NutritionEntry> _todayNutrition = [];
  UserProfile? _userProfile;
  
  bool _isLoading = true;
  Timer? _refreshTimer;
  

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeData();
    
    // Start periodic refresh after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPeriodicRefresh();
    });
  }
  
  void _startPeriodicRefresh() {
    // Refresh wellness metrics every 5 seconds to show real-time calculated values
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _refreshWellnessMetrics();
    });
    debugPrint('🔄 Home: Started periodic refresh timer');
  }
  
  Future<void> _refreshWellnessMetrics() async {
    try {
      // Use hardcoded userId='1' to match VitalsProvider
      const userId = '1';
      
      final today = DateTime.now();
      final todayStart = today.toIso8601String().split('T')[0];
      
      debugPrint('🔍 Home: Querying database for date $todayStart with userId=$userId...');
      final metrics = await _databaseService.getWellnessMetricsForDate(userId, todayStart);
      
      if (mounted) {
        if (metrics != null) {
          setState(() {
            _todayMetrics = metrics;
          });
          debugPrint('🔄 Home: Refreshed metrics - steps=${metrics.steps}, calories=${metrics.caloriesBurned}, distance=${metrics.distanceKm?.toStringAsFixed(2)}');
        } else {
          debugPrint('⚠️ Home: No metrics found in database for today');
        }
      }
    } catch (e) {
      debugPrint('❌ Error refreshing wellness metrics: $e');
    }
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    
    try {
      // Use hardcoded userId='1' to match VitalsProvider
      const userId = '1';
      
      // Load user profile with goals
      _userProfile = await _databaseService.getUserProfile(userId);
      
      // Load today's wellness metrics
      final today = DateTime.now();
      final todayStart = today.toIso8601String().split('T')[0];
      _todayMetrics = await _databaseService.getWellnessMetricsForDate(userId, todayStart);
      
      // Load today's nutrition
      _todayNutrition = await _databaseService.getNutritionEntriesForDate(userId, todayStart);
      
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }  @override
  void dispose() {
    _animationController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: _isLoading 
        ? _buildLoadingState() 
        : RefreshIndicator(
            onRefresh: _initializeData,
            backgroundColor: AppColors.secondaryDark,
            color: AppColors.pinkPrimary,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreetingSection(),
                    const SizedBox(height: 16),
                    // Debug scenario indicator
                    Consumer<VitalsProvider>(
                      builder: (context, vitals, _) {
                        final currentVitals = vitals.currentVitals;
                        if (currentVitals != null && currentVitals.rawData != null) {
                          final scenario = currentVitals.rawData!['current_scenario'] as String?;
                          if (scenario != null) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: DebugScenarioBanner(scenario: scenario),
                            );
                          }
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    _buildDailyActivitySummary(),
                    const SizedBox(height: 24),
                    _buildLiveVitalsSection(),
                    const SizedBox(height: 24),
                    _buildNutritionCard(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 80), // Extra padding for floating button
                  ],
                ),
              ),
            ),
          ),
      floatingActionButton: _buildFloatingChatButton(),
    );
  }

  Widget _buildFloatingChatButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.pinkPrimary.withAlpha(128),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/chat'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Stack(
          children: [
            const Center(
              child: Icon(
                Icons.chat_bubble,
                color: Colors.white,
                size: 28,
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.successGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                constraints: const BoxConstraints(
                  minWidth: 10,
                  minHeight: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primaryDark,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppColors.pinkPrimary.withAlpha(76),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.favorite, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Text('VitalSync', style: AppTextStyles.header3),
        ],
      ),
      actions: [
        Consumer<BluetoothProvider>(
          builder: (context, bluetooth, _) => IconButton(
            icon: Icon(
              bluetooth.isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
              color: bluetooth.isConnected ? AppColors.successGreen : AppColors.mediumGray,
            ),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ),
        Consumer<AlertsProvider>(
          builder: (context, alerts, _) => Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () => Navigator.pushNamed(context, '/alerts'),
              ),
              if (alerts.unacknowledgedCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.emergencyRed,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.emergencyRed.withAlpha(128),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      alerts.unacknowledgedCount > 99 ? '99+' : '${alerts.unacknowledgedCount}',
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.secondaryDark,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white.withAlpha(48),
                  child: const Icon(Icons.person, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 12),
                Text('Welcome Back!', style: AppTextStyles.header3),
                const SizedBox(height: 4),
                Text('Track your health journey', style: AppTextStyles.caption),
              ],
            ),
          ),
          _buildDrawerItem(Icons.home, 'Home', () => Navigator.pop(context)),
          _buildDrawerItem(Icons.favorite, 'Vitals', () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/vitals-detail');
          }),
          _buildDrawerItem(Icons.directions_run, 'Activity', () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/daily-activity');
          }),
          _buildDrawerItem(Icons.restaurant, 'Nutrition', () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/nutrition');
          }),
          _buildDrawerItem(Icons.warning_amber, 'Alerts', () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/alerts');
          }),
          _buildDrawerItem(Icons.fitness_center, 'Start Session', () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/start-session');
          }),
          const Divider(color: AppColors.mediumGray, thickness: 0.5),
          _buildDrawerItem(Icons.person, 'Profile', () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/profile');
          }),
          _buildDrawerItem(Icons.settings, 'Settings', () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/settings');
          }),
          _buildDrawerItem(Icons.logout, 'Logout', () async {
            Navigator.pop(context);
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            await authProvider.logout();
            Navigator.pushReplacementNamed(context, '/login');
          }),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.pinkPrimary),
      title: Text(title, style: AppTextStyles.bodyMedium),
      onTap: onTap,
      hoverColor: AppColors.pinkPrimary.withAlpha(24),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.pinkPrimary),
          ),
          const SizedBox(height: 16),
          Text('Loading your health data...', style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildGreetingSection() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 18) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return Consumer<BluetoothProvider>(
      builder: (context, bluetooth, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(greeting, style: AppTextStyles.header2),
                      const SizedBox(height: 8),
                      Text(
                        'Stay healthy, stay strong! 💪',
                        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.mediumGray),
                      ),
                    ],
                  ),
                ),
                LiveIndicator(
                  isLive: bluetooth.isConnected,
                  deviceName: bluetooth.deviceName,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildDailyActivitySummary() {
    final caloriesBurned = _todayMetrics?.caloriesBurned ?? 0;
    final steps = _todayMetrics?.steps ?? 0;
    final distance = _todayMetrics?.distanceKm ?? 0.0;
    
    final calorieGoal = _userProfile?.dailyCalorieGoal ?? 2000;
    final stepGoal = _userProfile?.dailyStepGoal ?? 10000;
    final distanceGoal = _userProfile?.dailyDistanceGoal ?? 5.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondaryDark,
            AppColors.secondaryDark.withAlpha(200),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.pinkPrimary.withAlpha(76), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.pinkPrimary.withAlpha(24),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_fire_department, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Today\'s Activity', style: AppTextStyles.header3),
                    if (_userProfile != null)
                      Text(
                        'Personalized Goals',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.successGreen,
                          fontStyle: FontStyle.italic,
                        ),
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
              Column(
                children: [
                  CircularProgress(
                    value: caloriesBurned / calorieGoal,
                    label: 'Calories',
                    centerText: '$caloriesBurned',
                    size: 90,
                    gradientColors: [AppColors.pinkPrimary, AppColors.purplePrimary],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        size: 12,
                        color: AppColors.mediumGray.withAlpha(156),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$calorieGoal kcal',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.mediumGray,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                children: [
                  CircularProgress(
                    value: steps / stepGoal,
                    label: 'Steps',
                    centerText: '$steps',
                    size: 90,
                    gradientColors: const [AppColors.purplePrimary, AppColors.purpleSecondary],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        size: 12,
                        color: AppColors.mediumGray.withAlpha(156),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${stepGoal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} steps',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.mediumGray,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                children: [
                  CircularProgress(
                    value: distance / distanceGoal,
                    label: 'Distance',
                    centerText: distance < 1.0 ? '${(distance * 1000).toStringAsFixed(0)} m' : '${distance.toStringAsFixed(2)} km',
                    size: 90,
                    gradientColors: const [AppColors.infoBlue, AppColors.infoBlue],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        size: 12,
                        color: AppColors.mediumGray.withAlpha(156),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${distanceGoal.toStringAsFixed(1)} km',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.mediumGray,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveVitalsSection() {
    return Consumer<VitalsProvider>(
      builder: (context, vitalsProvider, _) {
        final currentVitals = vitalsProvider.currentVitals;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Live Vitals', style: AppTextStyles.header3),
                        const SizedBox(width: 8),
                        if (currentVitals != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.successGreen.withAlpha(48),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.successGreen,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'LIVE',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.successGreen,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (currentVitals != null && currentVitals.activityState != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _getActivityColor(currentVitals.activityState!).withAlpha(38),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _getActivityColor(currentVitals.activityState!).withAlpha(76),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _getActivityIcon(currentVitals.activityState!),
                                style: TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatActivityState(currentVitals.activityState!),
                                style: AppTextStyles.caption.copyWith(
                                  color: _getActivityColor(currentVitals.activityState!),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/vitals-detail'),
                  icon: const Icon(Icons.arrow_forward, color: AppColors.pinkPrimary, size: 18),
                  label: Text('View All', style: AppTextStyles.bodySmall.copyWith(color: AppColors.pinkPrimary)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                VitalCard(
                  icon: '❤️',
                  label: 'Heart Rate',
                  value: currentVitals?.heartRate?.toStringAsFixed(0) ?? '--',
                  unit: 'BPM',
                  iconColor: AppColors.pinkPrimary,
                  trend: currentVitals != null ? 'stable' : null,
                  isLive: currentVitals != null,
                ),
                VitalCard(
                  icon: '💨',
                  label: 'SpO₂',
                  value: currentVitals?.spo2?.toStringAsFixed(1) ?? '--',
                  unit: '%',
                  iconColor: AppColors.infoBlue,
                  trend: currentVitals != null ? 'stable' : null,
                  isLive: currentVitals != null,
                ),
                VitalCard(
                  icon: '🌡️',
                  label: 'Temperature',
                  value: currentVitals?.temperature?.toStringAsFixed(1) ?? '--',
                  unit: '°C',
                  iconColor: AppColors.warningOrange,
                  trend: currentVitals != null ? 'stable' : null,
                  isLive: currentVitals != null,
                ),
                VitalCard(
                  icon: '🚶',
                  label: 'Steps',
                  value: '${_todayMetrics?.steps ?? 0}',
                  unit: 'steps',
                  iconColor: AppColors.purplePrimary,
                  trend: null,
                  isLive: false,
                ),
                VitalCard(
                  icon: '🔥',
                  label: 'Calories',
                  value: '${_todayMetrics?.caloriesBurned ?? 0}',
                  unit: 'kcal',
                  iconColor: AppColors.warningOrange,
                  trend: null,
                  isLive: false,
                ),
                VitalCard(
                  icon: '🗺️',
                  label: 'Distance',
                  value: () {
                    final dist = _todayMetrics?.distanceKm ?? 0.0;
                    return dist < 1.0 ? (dist * 1000).toStringAsFixed(0) : dist.toStringAsFixed(2);
                  }(),
                  unit: () {
                    final dist = _todayMetrics?.distanceKm ?? 0.0;
                    return dist < 1.0 ? 'm' : 'km';
                  }(),
                  iconColor: AppColors.infoBlue,
                  trend: null,
                  isLive: false,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildNutritionCard() {
    final totalCalories = _todayNutrition.fold<double>(
      0, 
      (sum, entry) => sum + (entry.calories ?? 0)
    );
    final totalProtein = _todayNutrition.fold<double>(
      0, 
      (sum, entry) => sum + (entry.proteinG ?? 0)
    );
    final totalCarbs = _todayNutrition.fold<double>(
      0, 
      (sum, entry) => sum + (entry.carbsG ?? 0)
    );
    final totalFats = _todayNutrition.fold<double>(
      0, 
      (sum, entry) => sum + (entry.fatsG ?? 0)
    );

    const calorieGoal = 2000;
    const proteinGoal = 150;
    const carbsGoal = 200;
    const fatsGoal = 65;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondaryDark,
            AppColors.secondaryDark.withAlpha(200),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.purplePrimary.withAlpha(76), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.purplePrimary, AppColors.purpleSecondary],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.restaurant, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text('Nutrition', style: AppTextStyles.header3),
                ],
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/nutrition'),
                child: Text('Log Meal', style: AppTextStyles.bodySmall.copyWith(color: AppColors.purplePrimary)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildNutrientBar('Calories', totalCalories, calorieGoal, 'kcal', AppColors.pinkPrimary),
          const SizedBox(height: 12),
          _buildNutrientBar('Protein', totalProtein, proteinGoal, 'g', AppColors.infoBlue),
          const SizedBox(height: 12),
          _buildNutrientBar('Carbs', totalCarbs, carbsGoal, 'g', AppColors.purplePrimary),
          const SizedBox(height: 12),
          _buildNutrientBar('Fats', totalFats, fatsGoal, 'g', AppColors.warningOrange),
        ],
      ),
    );
  }

  Widget _buildNutrientBar(String label, double value, int goal, String unit, Color color) {
    final percentage = (value / goal).clamp(0.0, 1.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.bodyMedium),
            Text(
              '${value.toStringAsFixed(0)} / $goal $unit',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.mediumGray),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.tertiaryDark.withAlpha(76),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: AppTextStyles.header3),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GradientButton(
                text: 'Start Session',
                onPressed: () => Navigator.pushNamed(context, '/start-session'),
                icon: Icons.play_arrow,
                gradientColors: const [AppColors.pinkPrimary, AppColors.purplePrimary],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GradientButton(
                text: 'Log Meal',
                onPressed: () => Navigator.pushNamed(context, '/nutrition'),
                icon: Icons.restaurant,
                gradientColors: const [AppColors.purplePrimary, AppColors.purpleSecondary],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GradientButton(
                text: 'View Sessions',
                onPressed: () => Navigator.pushNamed(context, '/session-history'),
                icon: Icons.fitness_center,
                gradientColors: const [AppColors.infoBlue, AppColors.purplePrimary],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GradientButton(
                text: 'View Activity',
                onPressed: () => Navigator.pushNamed(context, '/daily-activity'),
                icon: Icons.bar_chart,
                isOutlined: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GradientButton(
                text: 'Check Alerts',
                onPressed: () => Navigator.pushNamed(context, '/alerts'),
                icon: Icons.notifications,
                isOutlined: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getActivityIcon(String activityState) {
    switch (activityState.toLowerCase()) {
      case 'running':
        return '🏃';
      case 'walking':
        return '🚶';
      case 'sleeping':
        return '😴';
      case 'resting':
      default:
        return '🧘';
    }
  }

  String _formatActivityState(String activityState) {
    return activityState[0].toUpperCase() + activityState.substring(1);
  }

  Color _getActivityColor(String activityState) {
    switch (activityState.toLowerCase()) {
      case 'running':
        return AppColors.emergencyRed;
      case 'walking':
        return AppColors.purplePrimary;
      case 'sleeping':
        return AppColors.infoBlue;
      case 'resting':
      default:
        return AppColors.successGreen;
    }
  }
}
