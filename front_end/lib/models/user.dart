class User {
  final String id;
  final String username;
  final String email;
  final String? fullName;
  final int createdAt;
  final int? lastLogin;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
    required this.createdAt,
    this.lastLogin,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'created_at': createdAt,
      'last_login': lastLogin,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      email: map['email'],
      fullName: map['full_name'],
      createdAt: map['created_at'],
      lastLogin: map['last_login'],
    );
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? fullName,
    int? createdAt,
    int? lastLogin,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}

class UserProfile {
  final String userId;
  int? age;
  String? gender;
  double? weightKg;
  double? heightCm;
  String? activityLevel;
  bool hasHypertension;
  bool hasDiabetes;
  bool hasHeartCondition;
  bool hasAsthma;
  bool hasHighCholesterol;
  bool hasThyroidDisorder;
  String? otherConditions;
  String? medicalConditions;  // Added
  String? allergies;           // Added
  String? medications;         // Added
  String? fitnessGoals;        // Added
  String? goalType;
  String? goalIntensity;
  double? targetWeightKg;
  int dailyCalorieGoal;
  int dailyStepGoal;
  double dailyDistanceGoal;
  int dailyActiveMinutesGoal;
  int dailyProteinGoal;
  int dailyCarbsGoal;
  int dailyFatsGoal;
  int? updatedAt;              // Added

  UserProfile({
    required this.userId,
    this.age,
    this.gender,
    this.weightKg,
    this.heightCm,
    this.activityLevel,
    this.hasHypertension = false,
    this.hasDiabetes = false,
    this.hasHeartCondition = false,
    this.hasAsthma = false,
    this.hasHighCholesterol = false,
    this.hasThyroidDisorder = false,
    this.otherConditions,
    this.medicalConditions,
    this.allergies,
    this.medications,
    this.fitnessGoals,
    this.goalType,
    this.goalIntensity,
    this.targetWeightKg,
    this.dailyCalorieGoal = 2000,
    this.dailyStepGoal = 10000,
    this.dailyDistanceGoal = 5.0,
    this.dailyActiveMinutesGoal = 30,
    this.dailyProteinGoal = 150,
    this.dailyCarbsGoal = 250,
    this.dailyFatsGoal = 70,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'age': age,
      'gender': gender,
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'activity_level': activityLevel,
      'has_hypertension': hasHypertension ? 1 : 0,
      'has_diabetes': hasDiabetes ? 1 : 0,
      'has_heart_condition': hasHeartCondition ? 1 : 0,
      'has_asthma': hasAsthma ? 1 : 0,
      'has_high_cholesterol': hasHighCholesterol ? 1 : 0,
      'has_thyroid_disorder': hasThyroidDisorder ? 1 : 0,
      'other_conditions': otherConditions,
      'medical_conditions': medicalConditions,
      'allergies': allergies,
      'medications': medications,
      'fitness_goals': fitnessGoals,
      'goal_type': goalType,
      'goal_intensity': goalIntensity,
      'target_weight_kg': targetWeightKg,
      'daily_calorie_goal': dailyCalorieGoal,
      'daily_step_goal': dailyStepGoal,
      'daily_distance_goal': dailyDistanceGoal,
      'daily_active_minutes_goal': dailyActiveMinutesGoal,
      'daily_protein_goal': dailyProteinGoal,
      'daily_carbs_goal': dailyCarbsGoal,
      'daily_fats_goal': dailyFatsGoal,
      'updated_at': updatedAt,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      userId: map['user_id'],
      age: map['age'],
      gender: map['gender'],
      weightKg: map['weight_kg'],
      heightCm: map['height_cm'],
      activityLevel: map['activity_level'],
      hasHypertension: map['has_hypertension'] == 1,
      hasDiabetes: map['has_diabetes'] == 1,
      hasHeartCondition: map['has_heart_condition'] == 1,
      hasAsthma: map['has_asthma'] == 1,
      hasHighCholesterol: map['has_high_cholesterol'] == 1,
      hasThyroidDisorder: map['has_thyroid_disorder'] == 1,
      otherConditions: map['other_conditions'],
      medicalConditions: map['medical_conditions'],
      allergies: map['allergies'],
      medications: map['medications'],
      fitnessGoals: map['fitness_goals'],
      goalType: map['goal_type'],
      goalIntensity: map['goal_intensity'],
      targetWeightKg: map['target_weight_kg'],
      dailyCalorieGoal: map['daily_calorie_goal'] ?? 2000,
      dailyStepGoal: map['daily_step_goal'] ?? 10000,
      dailyDistanceGoal: map['daily_distance_goal'] ?? 5.0,
      dailyActiveMinutesGoal: map['daily_active_minutes_goal'] ?? 30,
      dailyProteinGoal: map['daily_protein_goal'] ?? 150,
      dailyCarbsGoal: map['daily_carbs_goal'] ?? 250,
      dailyFatsGoal: map['daily_fats_goal'] ?? 70,
      updatedAt: map['updated_at'],
    );
  }

  UserProfile copyWith({
    String? userId,
    int? age,
    String? gender,
    double? weightKg,
    double? heightCm,
    String? activityLevel,
    bool? hasHypertension,
    bool? hasDiabetes,
    bool? hasHeartCondition,
    bool? hasAsthma,
    bool? hasHighCholesterol,
    bool? hasThyroidDisorder,
    String? otherConditions,
    String? medicalConditions,
    String? allergies,
    String? medications,
    String? fitnessGoals,
    String? goalType,
    String? goalIntensity,
    double? targetWeightKg,
    int? dailyCalorieGoal,
    int? dailyStepGoal,
    double? dailyDistanceGoal,
    int? dailyActiveMinutesGoal,
    int? dailyProteinGoal,
    int? dailyCarbsGoal,
    int? dailyFatsGoal,
    int? updatedAt,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      activityLevel: activityLevel ?? this.activityLevel,
      hasHypertension: hasHypertension ?? this.hasHypertension,
      hasDiabetes: hasDiabetes ?? this.hasDiabetes,
      hasHeartCondition: hasHeartCondition ?? this.hasHeartCondition,
      hasAsthma: hasAsthma ?? this.hasAsthma,
      hasHighCholesterol: hasHighCholesterol ?? this.hasHighCholesterol,
      hasThyroidDisorder: hasThyroidDisorder ?? this.hasThyroidDisorder,
      otherConditions: otherConditions ?? this.otherConditions,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      allergies: allergies ?? this.allergies,
      medications: medications ?? this.medications,
      fitnessGoals: fitnessGoals ?? this.fitnessGoals,
      goalType: goalType ?? this.goalType,
      goalIntensity: goalIntensity ?? this.goalIntensity,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      dailyCalorieGoal: dailyCalorieGoal ?? this.dailyCalorieGoal,
      dailyStepGoal: dailyStepGoal ?? this.dailyStepGoal,
      dailyDistanceGoal: dailyDistanceGoal ?? this.dailyDistanceGoal,
      dailyActiveMinutesGoal: dailyActiveMinutesGoal ?? this.dailyActiveMinutesGoal,
      dailyProteinGoal: dailyProteinGoal ?? this.dailyProteinGoal,
      dailyCarbsGoal: dailyCarbsGoal ?? this.dailyCarbsGoal,
      dailyFatsGoal: dailyFatsGoal ?? this.dailyFatsGoal,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
