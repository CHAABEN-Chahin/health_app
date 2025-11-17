import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/helpers.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/gradient_button.dart';

class SetGoalsScreen extends StatefulWidget {
  final int age;
  final String gender;
  final double weight;
  final double height;
  final String activityLevel;
  final String? medicalConditions;
  final String? allergies;
  final String? medications;

  const SetGoalsScreen({
    Key? key,
    required this.age,
    required this.gender,
    required this.weight,
    required this.height,
    required this.activityLevel,
    this.medicalConditions,
    this.allergies,
    this.medications,
  }) : super(key: key);

  @override
  State<SetGoalsScreen> createState() => _SetGoalsScreenState();
}

class _SetGoalsScreenState extends State<SetGoalsScreen> {
  String _goalType = 'Lose Weight';
  double _targetWeight = 0;
  String _intensity = 'Moderate';
  int _timelineWeeks = 12;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _targetWeight = widget.weight;
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
        title: Text('Step 3 of 3', style: AppTextStyles.bodyMedium),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 20),
            Text('Set Your Goals', style: AppTextStyles.header1),
            const SizedBox(height: 8),
            Text(
              'Let\'s create a plan tailored for you',
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.mediumGray),
            ),
            const SizedBox(height: 40),
            _buildCurrentStatsCard(),
            const SizedBox(height: 24),
            Text('Fitness Goal', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildGoalTypeSelector(),
            const SizedBox(height: 24),
            if (_goalType != 'Maintain Weight') ...[
              Text('Target Weight (kg)', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildWeightSlider(),
              const SizedBox(height: 24),
            ],
            Text('Intensity', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildIntensitySelector(),
            const SizedBox(height: 24),
            Text('Timeline (weeks)', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildTimelineSlider(),
            const SizedBox(height: 24),
            _buildSummaryCard(),
            const SizedBox(height: 32),
            GradientButton(
              text: 'Complete Setup',
              onPressed: _completeOnboarding,
              isLoading: _isLoading,
              gradientColors: const [AppColors.pinkPrimary, AppColors.purplePrimary],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStatsCard() {
    final bmi = Helpers.calculateBMI(widget.weight, widget.height);
    final category = Helpers.getBMICategory(bmi);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondaryDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current Stats', style: AppTextStyles.header3),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat('Weight', '${widget.weight.toStringAsFixed(1)} kg'),
              _buildStat('BMI', '${bmi.toStringAsFixed(1)}\n$category'),
              _buildStat('Height', '${widget.height.toStringAsFixed(0)} cm'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.bodyLarge.copyWith(color: AppColors.pinkPrimary), textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.mediumGray)),
      ],
    );
  }

  Widget _buildGoalTypeSelector() {
    final goals = ['Lose Weight', 'Gain Weight', 'Maintain Weight', 'Build Muscle'];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: goals.map((goal) {
        final isSelected = _goalType == goal;
        return GestureDetector(
          onTap: () => setState(() => _goalType = goal),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected ? AppColors.primaryGradient : null,
              color: isSelected ? null : AppColors.secondaryDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Colors.transparent : AppColors.pinkPrimary.withOpacity(0.3),
              ),
            ),
            child: Text(goal, style: AppTextStyles.bodyMedium),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWeightSlider() {
    final minWeight = widget.weight * 0.7;
    final maxWeight = widget.weight * 1.3;
    
    return Column(
      children: [
        Slider(
          value: _targetWeight.clamp(minWeight, maxWeight),
          min: minWeight,
          max: maxWeight,
          divisions: 100,
          activeColor: AppColors.pinkPrimary,
          inactiveColor: AppColors.tertiaryDark,
          onChanged: (value) => setState(() => _targetWeight = value),
        ),
        Text(
          '${_targetWeight.toStringAsFixed(1)} kg (${(_targetWeight - widget.weight).toStringAsFixed(1)} kg ${_targetWeight > widget.weight ? 'gain' : 'loss'})',
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.pinkPrimary),
        ),
      ],
    );
  }

  Widget _buildIntensitySelector() {
    final intensities = ['Light', 'Moderate', 'Intense'];
    
    return Row(
      children: intensities.map((intensity) {
        final isSelected = _intensity == intensity;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _intensity = intensity),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
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
                intensity,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimelineSlider() {
    return Column(
      children: [
        Slider(
          value: _timelineWeeks.toDouble(),
          min: 4,
          max: 52,
          divisions: 12,
          activeColor: AppColors.purplePrimary,
          inactiveColor: AppColors.tertiaryDark,
          onChanged: (value) => setState(() => _timelineWeeks = value.round()),
        ),
        Text(
          '$_timelineWeeks weeks (${(_timelineWeeks / 4).toStringAsFixed(0)} months)',
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.purplePrimary),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final weeklyChange = (_targetWeight - widget.weight) / _timelineWeeks;
    final dailyCalorieAdjustment = weeklyChange * 7700 / 7; // 7700 kcal per kg
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.secondaryDark, AppColors.secondaryDark.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.pinkPrimary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppColors.pinkPrimary),
              const SizedBox(width: 12),
              Text('Your Plan', style: AppTextStyles.header3),
            ],
          ),
          const SizedBox(height: 16),
          _buildPlanItem('Goal', _goalType),
          _buildPlanItem('Timeline', '$_timelineWeeks weeks'),
          _buildPlanItem('Intensity', _intensity),
          if (_goalType != 'Maintain Weight')
            _buildPlanItem('Weekly Target', '${weeklyChange.abs().toStringAsFixed(2)} kg/week'),
          _buildPlanItem('Daily Calories', '${dailyCalorieAdjustment > 0 ? '+' : ''}${dailyCalorieAdjustment.toStringAsFixed(0)} kcal'),
        ],
      ),
    );
  }

  Widget _buildPlanItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mediumGray)),
          Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final goalText = '$_goalType: ${_targetWeight.toStringAsFixed(1)} kg in $_timelineWeeks weeks ($_intensity intensity)';
    
    final success = await authProvider.createProfile(
      age: widget.age,
      gender: widget.gender,
      weightKg: widget.weight,
      heightCm: widget.height,
      medicalConditions: widget.medicalConditions,
      allergies: widget.allergies,
      medications: widget.medications,
      fitnessGoals: goalText,
    );

    print(success);

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Setup failed'),
          backgroundColor: AppColors.emergencyRed,
        ),
      );
    }
  }
}
