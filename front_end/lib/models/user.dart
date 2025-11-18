import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String username;
  final String email;
  final String? fullName;
  final DateTime createdAt;
  final DateTime? lastLogin;

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
      'created_at': Timestamp.fromDate(createdAt),
      'last_login': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      username: map['username'] as String,
      email: map['email'] as String,
      fullName: map['full_name'] as String?,
      createdAt: _parseTimestamp(map['created_at']),
      lastLogin: _parseTimestamp(map['last_login']),
    );
  }

  /// Helper method to parse various timestamp formats
  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) {
      return DateTime.now();
    } else if (value is Timestamp) {
      return value.toDate();
    } else if (value is int) {
      // Handle milliseconds since epoch
      return DateTime.fromMillisecondsSinceEpoch(value);
    } else if (value is String) {
      return DateTime.parse(value);
    } else if (value is DateTime) {
      return value;
    }
    return DateTime.now();
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? fullName,
    DateTime? createdAt,
    DateTime? lastLogin,
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
  String? medicalConditions;
  String? allergies;
  String? medications;
  String? fitnessGoals;
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
  DateTime? updatedAt;

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
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      userId: map['user_id'] as String,
      age: map['age'] as int?,
      gender: map['gender'] as String?,
      weightKg: _parseDouble(map['weight_kg']),
      heightCm: _parseDouble(map['height_cm']),
      activityLevel: map['activity_level'] as String?,
      hasHypertension: _parseBool(map['has_hypertension']),
      hasDiabetes: _parseBool(map['has_diabetes']),
      hasHeartCondition: _parseBool(map['has_heart_condition']),
      hasAsthma: _parseBool(map['has_asthma']),
      hasHighCholesterol: _parseBool(map['has_high_cholesterol']),
      hasThyroidDisorder: _parseBool(map['has_thyroid_disorder']),
      otherConditions: map['other_conditions'] as String?,
      medicalConditions: map['medical_conditions'] as String?,
      allergies: map['allergies'] as String?,
      medications: map['medications'] as String?,
      fitnessGoals: map['fitness_goals'] as String?,
      goalType: map['goal_type'] as String?,
      goalIntensity: map['goal_intensity'] as String?,
      targetWeightKg: _parseDouble(map['target_weight_kg']),
      dailyCalorieGoal: map['daily_calorie_goal'] as int? ?? 2000,
      dailyStepGoal: map['daily_step_goal'] as int? ?? 10000,
      dailyDistanceGoal: _parseDouble(map['daily_distance_goal']) ?? 5.0,
      dailyActiveMinutesGoal: map['daily_active_minutes_goal'] as int? ?? 30,
      dailyProteinGoal: map['daily_protein_goal'] as int? ?? 150,
      dailyCarbsGoal: map['daily_carbs_goal'] as int? ?? 250,
      dailyFatsGoal: map['daily_fats_goal'] as int? ?? 70,
      updatedAt: _parseTimestamp(map['updated_at']),
    );
  }

  /// Helper method to parse boolean values (handles int 0/1 or bool)
  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  /// Helper method to parse double values
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Helper method to parse timestamp values
  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    if (value is DateTime) return value;
    return null;
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
    DateTime? updatedAt,
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