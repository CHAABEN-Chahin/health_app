import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/validators.dart';
import '../../widgets/common/gradient_button.dart';
import '../../widgets/common/custom_text_field.dart';
import 'health_info_screen.dart';

class GetToKnowYouScreen extends StatefulWidget {
  const GetToKnowYouScreen({Key? key}) : super(key: key);

  @override
  State<GetToKnowYouScreen> createState() => _GetToKnowYouScreenState();
}

class _GetToKnowYouScreenState extends State<GetToKnowYouScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  
  String _selectedGender = 'Male';
  String _activityLevel = 'Moderate';

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
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
        title: Text('Step 1 of 3', style: AppTextStyles.bodyMedium),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 20),
              Text('Get to Know You', style: AppTextStyles.header1),
              const SizedBox(height: 8),
              Text(
                'Help us personalize your experience',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.mediumGray),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _ageController,
                      label: 'Age',
                      keyboardType: TextInputType.number,
                      validator: Validators.validateAge,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildGenderDropdown(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _weightController,
                      label: 'Weight (kg)',
                      keyboardType: TextInputType.number,
                      validator: Validators.validateWeight,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _heightController,
                      label: 'Height (cm)',
                      keyboardType: TextInputType.number,
                      validator: Validators.validateHeight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Activity Level', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildActivityLevelSelector(),
              const SizedBox(height: 40),
              GradientButton(
                text: 'Continue',
                onPressed: _continue,
                gradientColors: const [AppColors.pinkPrimary, AppColors.purplePrimary],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gender', style: AppTextStyles.bodySmall.copyWith(color: AppColors.mediumGray)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedGender,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.tertiaryDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          dropdownColor: AppColors.secondaryDark,
          style: AppTextStyles.bodyMedium,
          items: ['Male', 'Female', 'Other'].map((gender) {
            return DropdownMenuItem(value: gender, child: Text(gender));
          }).toList(),
          onChanged: (value) => setState(() => _selectedGender = value!),
        ),
      ],
    );
  }

  Widget _buildActivityLevelSelector() {
    final levels = ['Sedentary', 'Light', 'Moderate', 'Active', 'Very Active'];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: levels.map((level) {
        final isSelected = _activityLevel == level;
        return GestureDetector(
          onTap: () => setState(() => _activityLevel = level),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected ? AppColors.primaryGradient : null,
              color: isSelected ? null : AppColors.secondaryDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Colors.transparent : AppColors.pinkPrimary.withAlpha(76),
              ),
            ),
            child: Text(level, style: AppTextStyles.bodyMedium),
          ),
        );
      }).toList(),
    );
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthInfoScreen(
          age: int.parse(_ageController.text),
          gender: _selectedGender,
          weight: double.parse(_weightController.text),
          height: double.parse(_heightController.text),
          activityLevel: _activityLevel,
        ),
      ),
    );
  }
}
