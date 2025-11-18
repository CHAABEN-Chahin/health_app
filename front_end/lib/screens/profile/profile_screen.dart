import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/helpers.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/gradient_button.dart';
import '../../widgets/common/custom_text_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _conditionsController;
  late TextEditingController _allergiesController;
  late TextEditingController _medicationsController;
  late TextEditingController _goalsController;
  
  String _selectedGender = 'Male';

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profile = authProvider.userProfile;
    
    _ageController = TextEditingController(text: profile?.age.toString() ?? '');
    _weightController = TextEditingController(text: profile?.weightKg.toString() ?? '');
    _heightController = TextEditingController(text: profile?.heightCm.toString() ?? '');
    _conditionsController = TextEditingController(text: profile?.medicalConditions ?? '');
    _allergiesController = TextEditingController(text: profile?.allergies ?? '');
    _medicationsController = TextEditingController(text: profile?.medications ?? '');
    _goalsController = TextEditingController(text: profile?.fitnessGoals ?? '');
    _selectedGender = profile?.gender ?? 'Male';
  }

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _conditionsController.dispose();
    _allergiesController.dispose();
    _medicationsController.dispose();
    _goalsController.dispose();
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
        title: Text('Profile', style: AppTextStyles.header3),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit, color: Colors.white),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.currentUser;
          final profile = authProvider.userProfile;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildProfileHeader(user?.username ?? 'User', user?.email ?? ''),
                  const SizedBox(height: 24),
                  if (profile != null && profile.weightKg != null && profile.heightCm != null) ...[
                    _buildBMICard(profile.weightKg!, profile.heightCm!),
                    const SizedBox(height: 24),
                  ],
                  _buildBasicInfoSection(),
                  const SizedBox(height: 24),
                  _buildHealthInfoSection(),
                  const SizedBox(height: 24),
                  _buildGoalsSection(),
                  if (_isEditing) ...[
                    const SizedBox(height: 24),
                    GradientButton(
                      text: 'Save Changes',
                      onPressed: _saveProfile,
                      gradientColors: const [AppColors.pinkPrimary, AppColors.purplePrimary],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(String name, String email) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.pinkPrimary, AppColors.purplePrimary],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.pinkPrimary.withAlpha(76),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.person, size: 60, color: Colors.white),
            ),
            if (_isEditing)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.pinkPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(name, style: AppTextStyles.header2),
        const SizedBox(height: 4),
        Text(email, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mediumGray)),
      ],
    );
  }

  Widget _buildBMICard(double weight, double height) {
    final bmi = Helpers.calculateBMI(weight, height);
    final bmiCategory = Helpers.getBMICategory(bmi);
    Color bmiColor;
    
    if (bmi < 18.5) {
      bmiColor = AppColors.infoBlue;
    } else if (bmi < 25) {
      bmiColor = AppColors.successGreen;
    } else if (bmi < 30) {
      bmiColor = AppColors.warningOrange;
    } else {
      bmiColor = AppColors.emergencyRed;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.secondaryDark, AppColors.secondaryDark.withAlpha(200)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bmiColor.withAlpha(76)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text('BMI', style: AppTextStyles.bodySmall.copyWith(color: AppColors.mediumGray)),
              const SizedBox(height: 8),
              Text(bmi.toStringAsFixed(1), style: AppTextStyles.header1.copyWith(color: bmiColor)),
              const SizedBox(height: 4),
              Text(bmiCategory, style: AppTextStyles.bodySmall.copyWith(color: bmiColor)),
            ],
          ),
          Container(
            width: 1,
            height: 60,
            color: AppColors.mediumGray.withAlpha(48),
          ),
          Column(
            children: [
              Text('Weight', style: AppTextStyles.bodySmall.copyWith(color: AppColors.mediumGray)),
              const SizedBox(height: 8),
              Text('${weight.toStringAsFixed(1)} kg', style: AppTextStyles.header3),
            ],
          ),
          Container(
            width: 1,
            height: 60,
            color: AppColors.mediumGray.withAlpha(48),
          ),
          Column(
            children: [
              Text('Height', style: AppTextStyles.bodySmall.copyWith(color: AppColors.mediumGray)),
              const SizedBox(height: 8),
              Text('${height.toStringAsFixed(0)} cm', style: AppTextStyles.header3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSection(
      'Basic Information',
      Icons.person_outline,
      [
        Row(
          children: [
            Expanded(
              child: _buildInfoField('Age', _ageController, 'years', _isEditing),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGenderSelector(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildInfoField('Weight', _weightController, 'kg', _isEditing),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoField('Height', _heightController, 'cm', _isEditing),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHealthInfoSection() {
    return _buildSection(
      'Health Information',
      Icons.medical_services_outlined,
      [
        _buildInfoField('Medical Conditions', _conditionsController, 'None', _isEditing, maxLines: 3),
        const SizedBox(height: 16),
        _buildInfoField('Allergies', _allergiesController, 'None', _isEditing, maxLines: 2),
        const SizedBox(height: 16),
        _buildInfoField('Current Medications', _medicationsController, 'None', _isEditing, maxLines: 2),
      ],
    );
  }

  Widget _buildGoalsSection() {
    return _buildSection(
      'Fitness Goals',
      Icons.flag_outlined,
      [
        _buildInfoField('Goals', _goalsController, 'Set your fitness goals', _isEditing, maxLines: 3),
      ],
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondaryDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.pinkPrimary, size: 24),
              const SizedBox(width: 12),
              Text(title, style: AppTextStyles.header3),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoField(
    String label,
    TextEditingController controller,
    String suffix,
    bool enabled, {
    int maxLines = 1,
  }) {
    if (!enabled) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.mediumGray)),
          const SizedBox(height: 8),
          Text(
            controller.text.isEmpty ? suffix : '${controller.text} ${maxLines == 1 ? suffix : ''}',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      );
    }

    return CustomTextField(
      controller: controller,
      label: label,
      enabled: enabled,
      maxLines: maxLines,
    );
  }

  Widget _buildGenderSelector() {
    if (!_isEditing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gender', style: AppTextStyles.bodySmall.copyWith(color: AppColors.mediumGray)),
          const SizedBox(height: 8),
          Text(_selectedGender, style: AppTextStyles.bodyMedium),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gender', style: AppTextStyles.bodySmall.copyWith(color: AppColors.mediumGray)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedGender,
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
            return DropdownMenuItem(
              value: gender,
              child: Text(gender),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedGender = value!;
            });
          },
        ),
      ],
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profile = authProvider.userProfile;
    
    if (profile == null) return;

    final updatedProfile = profile.copyWith(
      age: int.tryParse(_ageController.text) ?? profile.age,
      gender: _selectedGender,
      weightKg: double.tryParse(_weightController.text) ?? profile.weightKg,
      heightCm: double.tryParse(_heightController.text) ?? profile.heightCm,
      medicalConditions: _conditionsController.text.isEmpty ? null : _conditionsController.text,
      allergies: _allergiesController.text.isEmpty ? null : _allergiesController.text,
      medications: _medicationsController.text.isEmpty ? null : _medicationsController.text,
      fitnessGoals: _goalsController.text.isEmpty ? null : _goalsController.text,
      updatedAt: DateTime.now(),
    );

    final success = await authProvider.updateProfile(updatedProfile);
    
    if (success && mounted) {
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }
}
