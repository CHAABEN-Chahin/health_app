import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/vitals_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../models/session.dart';
import '../../widgets/vitals/vital_card.dart';
import '../../widgets/common/gradient_button.dart';

enum SessionType {
  running,
  walking,
  cycling,
  gym,
  yoga,
  other,
}

class StartSessionScreen extends StatefulWidget {
  const StartSessionScreen({Key? key}) : super(key: key);

  @override
  State<StartSessionScreen> createState() => _StartSessionScreenState();
}

class _StartSessionScreenState extends State<StartSessionScreen> {
  final DatabaseService _databaseService = DatabaseService();
  
  SessionType _selectedType = SessionType.running;
  bool _isActive = false;
  bool _isPaused = false;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  
  int _calories = 0;
  double _distance = 0.0;
  
  @override
  void dispose() {
    _timer?.cancel();
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
        title: Text('Start Workout', style: AppTextStyles.header3),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (!_isActive) _buildTypeSelector(),
            if (!_isActive) const SizedBox(height: 24),
            _buildTimerCard(),
            const SizedBox(height: 24),
            _buildMetricsCards(),
            const SizedBox(height: 24),
            _buildVitalsSection(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondaryDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Workout Type', style: AppTextStyles.header3),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildTypeChip(SessionType.running, Icons.directions_run, 'Running'),
              _buildTypeChip(SessionType.walking, Icons.directions_walk, 'Walking'),
              _buildTypeChip(SessionType.cycling, Icons.directions_bike, 'Cycling'),
              _buildTypeChip(SessionType.gym, Icons.fitness_center, 'Gym'),
              _buildTypeChip(SessionType.yoga, Icons.self_improvement, 'Yoga'),
              _buildTypeChip(SessionType.other, Icons.sports, 'Other'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(SessionType type, IconData icon, String label) {
    final isSelected = _selectedType == type;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : AppColors.tertiaryDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(label, style: AppTextStyles.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.secondaryDark, AppColors.secondaryDark.withAlpha(200)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.pinkPrimary.withAlpha(76)),
      ),
      child: Column(
        children: [
          Text(
            _formatDuration(_elapsed),
            style: AppTextStyles.header1.copyWith(fontSize: 64),
          ),
          const SizedBox(height: 8),
          Text(
            _isActive ? (_isPaused ? 'Paused' : 'In Progress') : 'Ready to Start',
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.mediumGray),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard('Calories', '$_calories', 'kcal', Icons.local_fire_department, AppColors.warningOrange),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard('Distance', _distance.toStringAsFixed(2), 'km', Icons.route, AppColors.infoBlue),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondaryDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(value, style: AppTextStyles.header2.copyWith(color: color)),
          Text(unit, style: AppTextStyles.caption.copyWith(color: AppColors.mediumGray)),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.mediumGray)),
        ],
      ),
    );
  }

  Widget _buildVitalsSection() {
    return Consumer<VitalsProvider>(
      builder: (context, vitalsProvider, _) {
        final vitals = vitalsProvider.currentVitals;
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.secondaryDark,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Live Vitals', style: AppTextStyles.header3),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: VitalCard(
                      icon: '❤️',
                      label: 'Heart Rate',
                      value: vitals?.heartRate?.toStringAsFixed(0) ?? '--',
                      unit: 'BPM',
                      iconColor: AppColors.pinkPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: VitalCard(
                      icon: '💧',
                      label: 'SpO₂',
                      value: vitals?.spo2?.toStringAsFixed(1) ?? '--',
                      unit: '%',
                      iconColor: AppColors.infoBlue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    if (!_isActive) {
      return GradientButton(
        text: 'Start Workout',
        onPressed: _startSession,
        icon: Icons.play_arrow,
        gradientColors: const [AppColors.pinkPrimary, AppColors.purplePrimary],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GradientButton(
                text: _isPaused ? 'Resume' : 'Pause',
                onPressed: _togglePause,
                icon: _isPaused ? Icons.play_arrow : Icons.pause,
                gradientColors: [AppColors.purplePrimary, AppColors.purpleSecondary],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GradientButton(
                text: 'Stop',
                onPressed: _stopSession,
                icon: Icons.stop,
                gradientColors: [AppColors.emergencyRed, AppColors.warningOrange],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _startSession() {
    setState(() {
      _isActive = true;
      _isPaused = false;
      _elapsed = Duration.zero;
      _calories = 0;
      _distance = 0.0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _elapsed += const Duration(seconds: 1);
          _updateMetrics();
        });
      }
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  Future<void> _stopSession() async {
    _timer?.cancel();
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId ?? '1';
    
    final startTime = DateTime.now().subtract(_elapsed);
    final endTime = DateTime.now();
    
    final session = Session(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      sessionType: _selectedType.toString().split('.').last,
      startTime: startTime.millisecondsSinceEpoch,
      endTime: endTime.millisecondsSinceEpoch,
      durationSeconds: _elapsed.inSeconds,
      caloriesBurned: _calories,
    );

    await _databaseService.insertSession(session);
    
    if (mounted) {
      _showSummary();
    }
  }

  void _updateMetrics() {
    // Simulate metrics based on activity type
    double caloriesPerMin = 0;
    double distancePerMin = 0;
    
    switch (_selectedType) {
      case SessionType.running:
        caloriesPerMin = 12;
        distancePerMin = 0.2;
        break;
      case SessionType.walking:
        caloriesPerMin = 5;
        distancePerMin = 0.08;
        break;
      case SessionType.cycling:
        caloriesPerMin = 10;
        distancePerMin = 0.3;
        break;
      case SessionType.gym:
        caloriesPerMin = 8;
        distancePerMin = 0;
        break;
      case SessionType.yoga:
        caloriesPerMin = 4;
        distancePerMin = 0;
        break;
      case SessionType.other:
        caloriesPerMin = 6;
        distancePerMin = 0.1;
        break;
    }
    
    _calories = (_elapsed.inMinutes * caloriesPerMin).round();
    _distance = _elapsed.inMinutes * distancePerMin;
  }

  void _showSummary() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.secondaryDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isDismissible: false,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.pinkPrimary, AppColors.purplePrimary]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 16),
              Text('Workout Complete!', style: AppTextStyles.header2),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryStat('Duration', _formatDuration(_elapsed)),
                  _buildSummaryStat('Calories', '$_calories kcal'),
                  _buildSummaryStat('Distance', '${_distance.toStringAsFixed(2)} km'),
                ],
              ),
              const SizedBox(height: 24),
              GradientButton(
                text: 'Done',
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                gradientColors: const [AppColors.pinkPrimary, AppColors.purplePrimary],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.header3.copyWith(color: AppColors.pinkPrimary)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.mediumGray)),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}
