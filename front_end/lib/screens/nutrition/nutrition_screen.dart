import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../widgets/common/gradient_button.dart';
import '../../services/database_service.dart';
import '../../models/nutrition_entry.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import 'log_meal_screen.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({Key? key}) : super(key: key);

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final DatabaseService _databaseService = DatabaseService();
  DateTime _selectedDate = DateTime.now();
  List<NutritionEntry> _entries = [];
  UserProfile? _userProfile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadEntries();
  }
  
  Future<void> _loadUserProfile() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userId ?? '1';
      final profile = await _databaseService.getUserProfile(userId);
      if (mounted) {
        setState(() {
          _userProfile = profile;
        });
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userId ?? '1';
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      
      _entries = await _databaseService.getNutritionEntriesForDate(userId, dateStr);
    } catch (e) {
      debugPrint('Error loading nutrition entries: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _loadEntries();
  }

  double get _totalCalories => _entries.fold(0, (sum, entry) => sum + (entry.calories ?? 0));
  double get _totalProtein => _entries.fold(0, (sum, entry) => sum + (entry.proteinG ?? 0));
  double get _totalCarbs => _entries.fold(0, (sum, entry) => sum + (entry.carbsG ?? 0));
  double get _totalFats => _entries.fold(0, (sum, entry) => sum + (entry.fatsG ?? 0));

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
        title: Text('Nutrition Log', style: AppTextStyles.header3),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: AppColors.pinkPrimary),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.dark(
                        primary: AppColors.pinkPrimary,
                        surface: AppColors.secondaryDark,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
                _loadEntries();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadEntries,
        backgroundColor: AppColors.secondaryDark,
        color: AppColors.pinkPrimary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateSelector(),
              const SizedBox(height: 24),
              _buildNutritionSummary(),
              const SizedBox(height: 24),
              _buildMealsList(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LogMealScreen()),
          );
          if (result == true) {
            _loadEntries();
          }
        },
        backgroundColor: AppColors.pinkPrimary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Log Meal', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
      ),
    );
  }

  Widget _buildDateSelector() {
    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.secondaryDark, AppColors.secondaryDark.withAlpha(200)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.purplePrimary.withAlpha(76)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _changeDate(-1),
            icon: const Icon(Icons.chevron_left, color: AppColors.pinkPrimary),
          ),
          Column(
            children: [
              Text(
                DateFormat('EEEE').format(_selectedDate),
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mediumGray),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('MMM d, yyyy').format(_selectedDate),
                style: AppTextStyles.header3,
              ),
              if (isToday)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'TODAY',
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            onPressed: isToday ? null : () => _changeDate(1),
            icon: Icon(
              Icons.chevron_right,
              color: isToday ? AppColors.darkGray : AppColors.pinkPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionSummary() {
    final calorieGoal = _userProfile?.dailyCalorieGoal ?? 2000;
    final proteinGoal = _userProfile?.dailyProteinGoal ?? 150;
    final carbsGoal = _userProfile?.dailyCarbsGoal ?? 250;
    final fatsGoal = _userProfile?.dailyFatsGoal ?? 70;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.pinkPrimary.withAlpha(48),
            AppColors.purplePrimary.withAlpha(48),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.pinkPrimary.withAlpha(76), width: 1),
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
                child: const Icon(Icons.pie_chart, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Text('Daily Summary', style: AppTextStyles.header3),
            ],
          ),
          const SizedBox(height: 20),
          _buildNutrientRow(
            'Calories',
            _totalCalories,
            calorieGoal,
            'kcal',
            AppColors.pinkPrimary,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMacroCard('Protein', _totalProtein, proteinGoal, 'g', AppColors.infoBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMacroCard('Carbs', _totalCarbs, carbsGoal, 'g', AppColors.purplePrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMacroCard('Fats', _totalFats, fatsGoal, 'g', AppColors.warningOrange),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientRow(String label, double value, int goal, String unit, Color color) {
    final percentage = (value / goal).clamp(0.0, 1.0);
    final remaining = (goal - value).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.bodyLarge),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${value.toInt()}',
                    style: AppTextStyles.header3.copyWith(color: color),
                  ),
                  TextSpan(
                    text: ' / $goal $unit',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mediumGray),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.tertiaryDark.withAlpha(76),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [color, color.withAlpha(144)]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          remaining > 0 ? '$remaining $unit remaining' : 'Goal reached! 🎉',
          style: AppTextStyles.caption.copyWith(
            color: remaining > 0 ? AppColors.mediumGray : AppColors.successGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildMacroCard(String label, double value, int goal, String unit, Color color) {
    final percentage = (value / goal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.tertiaryDark.withAlpha(128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Column(
        children: [
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.mediumGray)),
          const SizedBox(height: 8),
          Text(
            '${value.toInt()}',
            style: AppTextStyles.header3.copyWith(color: color),
          ),
          Text(
            '/ $goal$unit',
            style: AppTextStyles.caption.copyWith(color: AppColors.mediumGray),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: AppColors.darkGray,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.pinkPrimary),
        ),
      );
    }

    if (_entries.isEmpty) {
      return _buildEmptyState();
    }

    // Group entries by meal type
    final breakfast = _entries.where((e) => e.mealType == 'breakfast').toList();
    final lunch = _entries.where((e) => e.mealType == 'lunch').toList();
    final dinner = _entries.where((e) => e.mealType == 'dinner').toList();
    final snacks = _entries.where((e) => e.mealType == 'snack').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Meals', style: AppTextStyles.header3),
        const SizedBox(height: 16),
        if (breakfast.isNotEmpty) _buildMealSection('🌅 Breakfast', breakfast),
        if (lunch.isNotEmpty) _buildMealSection('☀️ Lunch', lunch),
        if (dinner.isNotEmpty) _buildMealSection('🌙 Dinner', dinner),
        if (snacks.isNotEmpty) _buildMealSection('🍎 Snacks', snacks),
      ],
    );
  }

  Widget _buildMealSection(String title, List<NutritionEntry> meals) {
    final totalCals = meals.fold(0.0, (sum, m) => sum + (m.calories ?? 0));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.secondaryDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.mediumGray.withAlpha(48)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: AppTextStyles.bodyLarge),
                Text(
                  '${totalCals.toInt()} kcal',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.pinkPrimary),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.darkGray, height: 1),
          ...meals.map((meal) => _buildMealItem(meal)),
        ],
      ),
    );
  }

  Widget _buildMealItem(NutritionEntry entry) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Text(
        entry.description ?? 'Meal',
        style: AppTextStyles.bodyMedium,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          'P: ${entry.proteinG?.toInt() ?? 0}g  C: ${entry.carbsG?.toInt() ?? 0}g  F: ${entry.fatsG?.toInt() ?? 0}g',
          style: AppTextStyles.caption.copyWith(color: AppColors.mediumGray),
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${entry.calories?.toInt() ?? 0}',
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.pinkPrimary),
          ),
          Text(
            'kcal',
            style: AppTextStyles.caption.copyWith(color: AppColors.mediumGray),
          ),
        ],
      ),
      onTap: () {
        _showMealDetails(entry);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.secondaryDark,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.purplePrimary.withAlpha(76), width: 2),
            ),
            child: Icon(
              Icons.restaurant_menu,
              size: 60,
              color: AppColors.purplePrimary.withAlpha(128),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No meals logged yet',
            style: AppTextStyles.header3.copyWith(color: AppColors.mediumGray),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to log your first meal',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mediumGray),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showMealDetails(NutritionEntry entry) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.secondaryDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Meal Details', style: AppTextStyles.header3),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.mediumGray),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (entry.imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  entry.imagePath!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: AppColors.tertiaryDark,
                    child: const Icon(Icons.image_not_supported, size: 48, color: AppColors.mediumGray),
                  ),
                ),
              ),
            if (entry.imagePath != null) const SizedBox(height: 16),
            Text(
              entry.description ?? 'Meal',
              style: AppTextStyles.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('h:mm a').format(DateTime.fromMillisecondsSinceEpoch(entry.timestamp * 1000)),
              style: AppTextStyles.caption.copyWith(color: AppColors.mediumGray),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.tertiaryDark.withAlpha(128),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildNutrientDetail('Calories', '${entry.calories?.toInt() ?? 0}', 'kcal', AppColors.pinkPrimary),
                  const Divider(color: AppColors.darkGray, height: 24),
                  _buildNutrientDetail('Protein', '${entry.proteinG?.toInt() ?? 0}', 'g', AppColors.infoBlue),
                  const SizedBox(height: 12),
                  _buildNutrientDetail('Carbs', '${entry.carbsG?.toInt() ?? 0}', 'g', AppColors.purplePrimary),
                  const SizedBox(height: 12),
                  _buildNutrientDetail('Fats', '${entry.fatsG?.toInt() ?? 0}', 'g', AppColors.warningOrange),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GradientButton(
              text: 'Delete Meal',
              onPressed: () async {
                Navigator.pop(context);
                await _databaseService.database.then((db) => db.delete(
                  'nutrition_log',
                  where: 'id = ?',
                  whereArgs: [entry.id],
                ));
                _loadEntries();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Meal deleted')),
                  );
                }
              },
              gradientColors: [AppColors.emergencyRed, AppColors.warningOrange],
              icon: Icons.delete,
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientDetail(String label, String value, String unit, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: AppTextStyles.bodyLarge.copyWith(color: color, fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: ' $unit',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mediumGray),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
