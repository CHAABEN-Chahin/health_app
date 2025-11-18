import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../widgets/common/gradient_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../services/database_service.dart';
import '../../models/nutrition_entry.dart';
import '../../providers/auth_provider.dart';
import 'package:http/http.dart' as http;

class LogMealScreen extends StatefulWidget {
  const LogMealScreen({Key? key}) : super(key: key);

  @override
  State<LogMealScreen> createState() => _LogMealScreenState();
}

class _LogMealScreenState extends State<LogMealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  
  String _selectedMealType = 'breakfast';
  bool _isLoading = false;
  bool _isAnalyzing = false;
  File? _selectedImage;
  
  // AI-generated nutrition data (will be populated by API)
  Map<String, dynamic>? _aiNutritionData;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _aiNutritionData = null; // Reset previous analysis
        });
        
        // Automatically analyze the image
        await _analyzeWithAI();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: AppColors.emergencyRed,
          ),
        );
      }
    }
  }

  Future<void> _analyzeWithAI() async {
    if (_selectedImage == null && _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add an image or description first'),
          backgroundColor: AppColors.warningOrange,
        ),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      // Prepare multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://4562ef6ed30f.ngrok-free.app/get_calories'),
      );

      // Add image file if available
      if (_selectedImage != null) {
        var imageBytes = await _selectedImage!.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            imageBytes,
            filename: 'meal_image.jpg',
          ),
        );
      }

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check if food was detected
        if (data['food_detected'] == false) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'No food detected in the image'),
                backgroundColor: AppColors.warningOrange,
              ),
            );
          }
          return;
        }

        // Extract nutrition facts
        final nutritionFacts = data['nutrition_facts'];

        setState(() {
          _aiNutritionData = {
            'calories': nutritionFacts['calories'] ?? 0,
            'protein_g': double.tryParse(nutritionFacts['protein']?.replaceAll('g', '') ?? '0') ?? 0.0,
            'carbs_g': double.tryParse(nutritionFacts['carbs']?.replaceAll('g', '') ?? '0') ?? 0.0,
            'fats_g': double.tryParse(nutritionFacts['total_fat']?.replaceAll('g', '') ?? '0') ?? 0.0,
            'analysis': data['notes'] ?? 'AI analysis complete',
          };
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✨ AI analysis complete!'),
              backgroundColor: AppColors.successGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error analyzing with AI: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error analyzing meal: $e'),
            backgroundColor: AppColors.emergencyRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  Future<void> _logMeal() async {
    if (_aiNutritionData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please analyze the meal first'),
          backgroundColor: AppColors.warningOrange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userId ?? '1';

      final entry = NutritionEntry(
        id: const Uuid().v4(),
        userId: userId,
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        mealType: _selectedMealType,
        description: _aiNutritionData!['analysis'] ?? _descriptionController.text.trim(),
        calories: _aiNutritionData!['calories'],
        proteinG: _aiNutritionData!['protein_g'],
        carbsG: _aiNutritionData!['carbs_g'],
        fatsG: _aiNutritionData!['fats_g'],
      );

      await DatabaseService().insertNutritionEntry(entry);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Meal logged successfully! 🎉'),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error logging meal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging meal: $e'),
            backgroundColor: AppColors.emergencyRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Log Meal', style: AppTextStyles.header3),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMealTypeSelector(),
              const SizedBox(height: 24),
              _buildImageSection(),
              const SizedBox(height: 24),
              Text('Meal Description (Optional)', style: AppTextStyles.bodyLarge),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _descriptionController,
                hint: 'e.g., Grilled chicken breast, 200g, with quinoa',
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              
              // Analyze Button
              if (_aiNutritionData == null)
                GradientButton(
                  text: 'Analyze with AI',
                  onPressed: _analyzeWithAI,
                  isLoading: _isAnalyzing,
                  icon: Icons.auto_awesome,
                  gradientColors: const [AppColors.purplePrimary, AppColors.purpleSecondary],
                ),
              
              // AI Results Section
              if (_aiNutritionData != null) ...[
                _buildAIResultsCard(),
                const SizedBox(height: 24),
                GradientButton(
                  text: 'Save Meal',
                  onPressed: _logMeal,
                  isLoading: _isLoading,
                  icon: Icons.check,
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.secondaryDark, AppColors.secondaryDark.withAlpha(200)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.purplePrimary.withAlpha(76)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Meal Type', style: AppTextStyles.bodyLarge),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMealTypeChip('🌅 Breakfast', 'breakfast'),
              _buildMealTypeChip('☀️ Lunch', 'lunch'),
              _buildMealTypeChip('🌙 Dinner', 'dinner'),
              _buildMealTypeChip('🍎 Snack', 'snack'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMealTypeChip(String label, String value) {
    final isSelected = _selectedMealType == value;
    
    return ChoiceChip(
      label: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(
          color: isSelected ? Colors.white : AppColors.mediumGray,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedMealType = value);
      },
      backgroundColor: AppColors.tertiaryDark,
      selectedColor: AppColors.pinkPrimary,
      side: BorderSide(
        color: isSelected ? AppColors.pinkPrimary : AppColors.mediumGray.withAlpha(76),
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      height: _selectedImage != null ? 250 : 180,
      decoration: BoxDecoration(
        color: AppColors.secondaryDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.purplePrimary.withAlpha(76),
          width: 2,
        ),
      ),
      child: _selectedImage != null
          ? Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    _selectedImage!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(144),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit, color: Colors.white, size: 20),
                        ),
                        onPressed: () => _showImageSourceDialog(),
                      ),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(144),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedImage = null;
                            _aiNutritionData = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showImageSourceDialog,
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 56,
                        color: AppColors.purplePrimary.withAlpha(156),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Add Photo or Camera',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.purplePrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'AI will analyze your meal',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.mediumGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.secondaryDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select Image Source', style: AppTextStyles.header3),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildImageSourceOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                _buildImageSourceOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildAIResultsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.successGreen.withAlpha(24),
            AppColors.successGreen.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.successGreen.withAlpha(76)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Analysis Complete', style: AppTextStyles.header3.copyWith(fontSize: 16)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.purplePrimary),
                onPressed: _analyzeWithAI,
                tooltip: 'Re-analyze',
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.mediumGray, thickness: 0.5),
          const SizedBox(height: 16),
          
          // Nutrition breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNutrientCard(
                icon: Icons.local_fire_department,
                label: 'Calories',
                value: '${_aiNutritionData!['calories']}',
                unit: 'kcal',
                color: AppColors.pinkPrimary,
              ),
              _buildNutrientCard(
                icon: Icons.fitness_center,
                label: 'Protein',
                value: '${_aiNutritionData!['protein_g']}',
                unit: 'g',
                color: AppColors.infoBlue,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNutrientCard(
                icon: Icons.eco,
                label: 'Carbs',
                value: '${_aiNutritionData!['carbs_g']}',
                unit: 'g',
                color: AppColors.purplePrimary,
              ),
              _buildNutrientCard(
                icon: Icons.water_drop,
                label: 'Fats',
                value: '${_aiNutritionData!['fats_g']}',
                unit: 'g',
                color: AppColors.warningOrange,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.mediumGray, thickness: 0.5),
          const SizedBox(height: 12),
          Text('AI Description:', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            _aiNutritionData!['analysis'],
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mediumGray),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color.withAlpha(24),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(76)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.header3.copyWith(fontSize: 20, color: color),
            ),
            Text(
              unit,
              style: AppTextStyles.caption.copyWith(color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
