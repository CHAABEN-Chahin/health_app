import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../widgets/common/gradient_button.dart';
import 'set_goals_screen.dart';

class HealthInfoScreen extends StatefulWidget {
  final int age;
  final String gender;
  final double weight;
  final double height;
  final String activityLevel;

  const HealthInfoScreen({
    super.key,
    required this.age,
    required this.gender,
    required this.weight,
    required this.height,
    required this.activityLevel,
  });

  @override
  State<HealthInfoScreen> createState() => _HealthInfoScreenState();
}

class _HealthInfoScreenState extends State<HealthInfoScreen> {
  final _conditionsController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _medicationsController = TextEditingController();
  
  final Set<String> _selectedConditions = {};
  
  final List<String> _commonConditions = [
    'Diabetes',
    'Hypertension',
    'Asthma',
    'Heart Disease',
    'Arthritis',
    'None',
  ];

  @override
  void dispose() {
    _conditionsController.dispose();
    _allergiesController.dispose();
    _medicationsController.dispose();
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
        title: Text('Step 2 of 3', style: AppTextStyles.bodyMedium),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 20),
            Text('Health Information', style: AppTextStyles.header1),
            const SizedBox(height: 8),
            Text(
              'This helps us monitor your health better',
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.mediumGray),
            ),
            const SizedBox(height: 40),
            Text('Medical Conditions', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _commonConditions.map((condition) {
                final isSelected = _selectedConditions.contains(condition);
                return FilterChip(
                  label: Text(condition),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (condition == 'None') {
                        if (selected) {
                          _selectedConditions.clear();
                          _selectedConditions.add('None');
                        } else {
                          _selectedConditions.remove('None');
                        }
                      } else {
                        _selectedConditions.remove('None');
                        if (selected) {
                          _selectedConditions.add(condition);
                        } else {
                          _selectedConditions.remove(condition);
                        }
                      }
                    });
                  },
                  backgroundColor: AppColors.secondaryDark,
                  selectedColor: AppColors.pinkPrimary.withAlpha(76),
                  checkmarkColor: AppColors.pinkPrimary,
                  labelStyle: AppTextStyles.bodyMedium,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _allergiesController,
              decoration: InputDecoration(
                labelText: 'Allergies (optional)',
                hintText: 'e.g., Penicillin, Peanuts',
                labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.mediumGray),
                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.mediumGray.withAlpha(128)),
                filled: true,
                fillColor: AppColors.tertiaryDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: AppTextStyles.bodyMedium,
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _medicationsController,
              decoration: InputDecoration(
                labelText: 'Current Medications (optional)',
                hintText: 'List any medications you\'re taking',
                labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.mediumGray),
                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.mediumGray.withAlpha(128)),
                filled: true,
                fillColor: AppColors.tertiaryDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: AppTextStyles.bodyMedium,
              maxLines: 2,
            ),
            const SizedBox(height: 40),
            GradientButton(
              text: 'Continue',
              onPressed: _continue,
              gradientColors: const [AppColors.pinkPrimary, AppColors.purplePrimary],
            ),
          ],
        ),
      ),
    );
  }

  void _continue() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SetGoalsScreen(
          age: widget.age,
          gender: widget.gender,
          weight: widget.weight,
          height: widget.height,
          activityLevel: widget.activityLevel,
          medicalConditions: _selectedConditions.isEmpty ? null : _selectedConditions.join(', '),
          allergies: _allergiesController.text.isEmpty ? null : _allergiesController.text,
          medications: _medicationsController.text.isEmpty ? null : _medicationsController.text,
        ),
      ),
    );
  }
}
