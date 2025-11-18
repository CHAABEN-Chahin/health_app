import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/vital_sign.dart';
import '../models/alert.dart';
import '../models/session.dart';
import '../models/wellness_metrics.dart';
import '../models/nutrition_entry.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'healthtrack.db');
    debugPrint('📁 Database path: $path');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }
  
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new goal columns to user_profile table
      await db.execute('ALTER TABLE user_profile ADD COLUMN daily_distance_goal REAL DEFAULT 5.0');
      await db.execute('ALTER TABLE user_profile ADD COLUMN daily_active_minutes_goal INTEGER DEFAULT 30');
      await db.execute('ALTER TABLE user_profile ADD COLUMN daily_protein_goal INTEGER DEFAULT 150');
      await db.execute('ALTER TABLE user_profile ADD COLUMN daily_carbs_goal INTEGER DEFAULT 250');
      await db.execute('ALTER TABLE user_profile ADD COLUMN daily_fats_goal INTEGER DEFAULT 70');
      debugPrint('✅ Database upgraded from version $oldVersion to $newVersion');
    }
    if (oldVersion < 3) {
      // Add username column to user_profile table
      await db.execute('ALTER TABLE user_profile ADD COLUMN username TEXT');
      debugPrint('✅ Database upgraded to version 3 - Added username to user_profile');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT UNIQUE NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        full_name TEXT,
        created_at INTEGER NOT NULL,
        last_login INTEGER
      )
    ''');

    // User profile table
    await db.execute('''
      CREATE TABLE user_profile (
        user_id TEXT PRIMARY KEY,
        username TEXT,
        age INTEGER,
        gender TEXT,
        weight_kg REAL,
        height_cm REAL,
        activity_level TEXT,
        has_hypertension INTEGER DEFAULT 0,
        has_diabetes INTEGER DEFAULT 0,
        has_heart_condition INTEGER DEFAULT 0,
        has_asthma INTEGER DEFAULT 0,
        has_high_cholesterol INTEGER DEFAULT 0,
        has_thyroid_disorder INTEGER DEFAULT 0,
        other_conditions TEXT,
        medical_conditions TEXT,
        allergies TEXT,
        medications TEXT,
        fitness_goals TEXT,
        goal_type TEXT,
        goal_intensity TEXT,
        target_weight_kg REAL,
        daily_calorie_goal INTEGER DEFAULT 2000,
        daily_step_goal INTEGER DEFAULT 10000,
        daily_distance_goal REAL DEFAULT 5.0,
        daily_active_minutes_goal INTEGER DEFAULT 30,
        daily_protein_goal INTEGER DEFAULT 150,
        daily_carbs_goal INTEGER DEFAULT 250,
        daily_fats_goal INTEGER DEFAULT 70,
        updated_at INTEGER,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Raw sensor data table
    await db.execute('''
      CREATE TABLE raw_sensor_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        heart_rate INTEGER,
        spo2 INTEGER,
        temperature REAL,
        accel_x REAL,
        accel_y REAL,
        accel_z REAL,
        gyro_x REAL,
        gyro_y REAL,
        gyro_z REAL,
        battery INTEGER,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Wellness metrics table
    await db.execute('''
      CREATE TABLE wellness_metrics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        date TEXT NOT NULL,
        hrv REAL,
        stress_level TEXT,
        steps INTEGER,
        distance_km REAL,
        active_minutes INTEGER,
        calories_burned INTEGER,
        resting_hr INTEGER,
        avg_hr INTEGER,
        max_hr INTEGER,
        avg_spo2 INTEGER,
        sleep_hours REAL,
        wellness_score INTEGER,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        UNIQUE(user_id, date)
      )
    ''');

    // Alerts table
    await db.execute('''
      CREATE TABLE alerts (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        severity TEXT NOT NULL,
        vital_type TEXT NOT NULL,
        message TEXT NOT NULL,
        recommendation TEXT NOT NULL,
        vital_value REAL,
        acknowledged INTEGER DEFAULT 0,
        title TEXT,
        is_read INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Sessions table
    await db.execute('''
      CREATE TABLE sessions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        session_type TEXT NOT NULL,
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        duration_seconds INTEGER,
        avg_heart_rate INTEGER,
        max_heart_rate INTEGER,
        calories_burned INTEGER,
        avg_spo2 INTEGER,
        notes TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Nutrition log table
    await db.execute('''
      CREATE TABLE nutrition_log (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        meal_type TEXT NOT NULL,
        image_path TEXT,
        calories INTEGER,
        protein_g REAL,
        carbs_g REAL,
        fats_g REAL,
        description TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better query performance
    await db.execute('CREATE INDEX idx_sensor_data_user_time ON raw_sensor_data(user_id, timestamp DESC)');
    await db.execute('CREATE INDEX idx_alerts_user_time ON alerts(user_id, timestamp DESC)');
    await db.execute('CREATE INDEX idx_sessions_user_time ON sessions(user_id, start_time DESC)');
    await db.execute('CREATE INDEX idx_nutrition_user_time ON nutrition_log(user_id, timestamp DESC)');
  }

  // ========== USER OPERATIONS ==========
  Future<int> insertUser(User user) async {
    final db = await database;
    await db.insert('users', user.toMap());
    return await db.insert('user_profile', UserProfile(userId: user.id).toMap());
  }

  Future<User?> getUserByUsername(String username) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (results.isEmpty) return null;
    return User.fromMap(results.first);
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (results.isEmpty) return null;
    return User.fromMap(results.first);
  }

  Future<User?> getUserById(String id) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return User.fromMap(results.first);
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // ========== USER PROFILE OPERATIONS ==========
  Future<int> insertOrUpdateUserProfile(UserProfile profile) async {
    final db = await database;
    return await db.insert(
      'user_profile',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  Future<int> updateUserProfile(UserProfile profile) async {
    final db = await database;
    return await db.update(
      'user_profile',
      profile.toMap(),
      where: 'user_id = ?',
      whereArgs: [profile.userId],
    );
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    final db = await database;
    final results = await db.query(
      'user_profile',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (results.isEmpty) {
      // Create default profile if none exists
      // TODO: When backend is connected, these goals should be AI-generated based on:
      // - User age, gender, weight, height
      // - Activity level
      // - Fitness goals (weight loss, muscle gain, maintenance)
      // - Medical conditions
      // The AI will calculate personalized TDEE, macro split, and activity targets
      final defaultProfile = UserProfile(
        userId: userId,
        dailyCalorieGoal: 2000,
        dailyStepGoal: 10000,
        dailyDistanceGoal: 5.0,
        dailyActiveMinutesGoal: 30,
        dailyProteinGoal: 150,
        dailyCarbsGoal: 250,
        dailyFatsGoal: 70,
      );
      await insertOrUpdateUserProfile(defaultProfile);
      return defaultProfile;
    }
    return UserProfile.fromMap(results.first);
  }

  // ========== VITAL SIGNS OPERATIONS ==========
  Future<int> insertVitalSign(VitalSign vitalSign) async {
    final db = await database;
    return await db.insert('raw_sensor_data', vitalSign.toMap());
  }

  Future<List<VitalSign>> getVitalSigns(String userId, {int? limit, int? sinceTimestamp}) async {
    final db = await database;
    List<Map<String, dynamic>> results;
    
    if (sinceTimestamp != null) {
      results = await db.query(
        'raw_sensor_data',
        where: 'user_id = ? AND timestamp >= ?',
        whereArgs: [userId, sinceTimestamp],
        orderBy: 'timestamp DESC',
        limit: limit,
      );
    } else {
      results = await db.query(
        'raw_sensor_data',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'timestamp DESC',
        limit: limit,
      );
    }
    
    return results.map((map) => VitalSign.fromMap(map)).toList();
  }

  Future<VitalSign?> getLatestVitalSign(String userId) async {
    final db = await database;
    final results = await db.query(
      'raw_sensor_data',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (results.isEmpty) return null;
    return VitalSign.fromMap(results.first);
  }

  Future<int> getUnsyncedVitalSignsCount(String userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM raw_sensor_data WHERE user_id = ? AND synced = 0',
      [userId],
    );
    return result.first['count'] as int;
  }

  Future<List<VitalSign>> getUnsyncedVitalSigns(String userId) async {
    final db = await database;
    final results = await db.query(
      'raw_sensor_data',
      where: 'user_id = ? AND synced = 0',
      whereArgs: [userId],
      orderBy: 'timestamp ASC',
    );
    return results.map((map) => VitalSign.fromMap(map)).toList();
  }

  Future<int> markVitalSignsSynced(List<int> ids) async {
    final db = await database;
    return await db.update(
      'raw_sensor_data',
      {'synced': 1},
      where: 'id IN (${ids.join(',')})',
    );
  }

  // ========== ALERT OPERATIONS ==========
  Future<int> insertAlert(Alert alert) async {
    final db = await database;
    return await db.insert('alerts', alert.toMap());
  }

  Future<List<Alert>> getAlerts(String userId, {int? limit, bool? acknowledged}) async {
    final db = await database;
    String where = 'user_id = ?';
    List<dynamic> whereArgs = [userId];
    
    if (acknowledged != null) {
      where += ' AND acknowledged = ?';
      whereArgs.add(acknowledged ? 1 : 0);
    }
    
    final results = await db.query(
      'alerts',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    
    return results.map((map) => Alert.fromMap(map)).toList();
  }

  Future<int> getUnacknowledgedAlertsCount(String userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM alerts WHERE user_id = ? AND acknowledged = 0',
      [userId],
    );
    return result.first['count'] as int;
  }

  Future<int> acknowledgeAlert(String alertId) async {
    final db = await database;
    return await db.update(
      'alerts',
      {'acknowledged': 1},
      where: 'id = ?',
      whereArgs: [alertId],
    );
  }

  Future<List<Alert>> getAlertsForUser(int userId) async {
    return getAlerts(userId.toString());
  }

  Future<List<Alert>> getAlertsInRange(int userId, int startTime, int endTime) async {
    final db = await database;
    final results = await db.query(
      'alerts',
      where: 'user_id = ? AND timestamp >= ? AND timestamp <= ?',
      whereArgs: [userId.toString(), startTime, endTime],
      orderBy: 'timestamp DESC',
    );
    return results.map((map) => Alert.fromMap(map)).toList();
  }

  Future<bool> markAlertAsRead(String alertId) async {
    final db = await database;
    final count = await db.update(
      'alerts',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [alertId],
    );
    return count > 0;
  }

  Future<bool> deleteAlert(String alertId) async {
    final db = await database;
    final count = await db.delete(
      'alerts',
      where: 'id = ?',
      whereArgs: [alertId],
    );
    return count > 0;
  }

  // ========== SESSION OPERATIONS ==========
  Future<int> insertSession(Session session) async {
    final db = await database;
    return await db.insert('sessions', session.toMap());
  }

  Future<int> updateSession(Session session) async {
    final db = await database;
    return await db.update(
      'sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<List<Session>> getSessions(String userId, {int? limit}) async {
    final db = await database;
    final results = await db.query(
      'sessions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'start_time DESC',
      limit: limit,
    );
    return results.map((map) => Session.fromMap(map)).toList();
  }

  Future<Session?> getActiveSession(String userId) async {
    final db = await database;
    final results = await db.query(
      'sessions',
      where: 'user_id = ? AND end_time IS NULL',
      whereArgs: [userId],
      orderBy: 'start_time DESC',
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Session.fromMap(results.first);
  }

  // ========== WELLNESS METRICS OPERATIONS ==========
  Future<int> insertOrUpdateWellnessMetrics(WellnessMetrics metrics) async {
    final db = await database;
    debugPrint('💾 DB: Saving wellness metrics - userId=${metrics.userId}, date=${metrics.date}, steps=${metrics.steps}');
    return await db.insert(
      'wellness_metrics',
      metrics.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<WellnessMetrics?> getWellnessMetrics(String userId, String date) async {
    final db = await database;
    final results = await db.query(
      'wellness_metrics',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, date],
    );
    if (results.isEmpty) return null;
    return WellnessMetrics.fromMap(results.first);
  }

  Future<List<WellnessMetrics>> getWellnessMetricsRange(String userId, String startDate, String endDate) async {
    final db = await database;
    final results = await db.query(
      'wellness_metrics',
      where: 'user_id = ? AND date >= ? AND date <= ?',
      whereArgs: [userId, startDate, endDate],
      orderBy: 'date DESC',
    );
    return results.map((map) => WellnessMetrics.fromMap(map)).toList();
  }

  // ========== NUTRITION OPERATIONS ==========
  Future<int> insertNutritionEntry(NutritionEntry entry) async {
    final db = await database;
    return await db.insert('nutrition_log', entry.toMap());
  }

  Future<List<NutritionEntry>> getNutritionEntries(String userId, String date) async {
    final db = await database;
    final dayStart = DateTime.parse(date).millisecondsSinceEpoch ~/ 1000;
    final dayEnd = dayStart + 86400; // 24 hours
    
    final results = await db.query(
      'nutrition_log',
      where: 'user_id = ? AND timestamp >= ? AND timestamp < ?',
      whereArgs: [userId, dayStart, dayEnd],
      orderBy: 'timestamp DESC',
    );
    return results.map((map) => NutritionEntry.fromMap(map)).toList();
  }

  Future<int> getTodayCaloriesConsumed(String userId, String date) async {
    final db = await database;
    final dayStart = DateTime.parse(date).millisecondsSinceEpoch ~/ 1000;
    final dayEnd = dayStart + 86400;
    
    final result = await db.rawQuery(
      'SELECT SUM(calories) as total FROM nutrition_log WHERE user_id = ? AND timestamp >= ? AND timestamp < ?',
      [userId, dayStart, dayEnd],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  // ========== UTILITY OPERATIONS ==========
  Future<void> deleteOldData(String userId, int daysToKeep) async {
    final db = await database;
    final cutoffTimestamp = DateTime.now().subtract(Duration(days: daysToKeep)).millisecondsSinceEpoch ~/ 1000;
    
    await db.delete(
      'raw_sensor_data',
      where: 'user_id = ? AND timestamp < ? AND synced = 1',
      whereArgs: [userId, cutoffTimestamp],
    );
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('nutrition_log');
    await db.delete('sessions');
    await db.delete('alerts');
    await db.delete('wellness_metrics');
    await db.delete('raw_sensor_data');
    await db.delete('user_profile');
    await db.delete('users');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // Missing methods for VitalsProvider
  Future<List<VitalSign>> getVitalSignsInRange(String userId, int startTime, int endTime) async {
    final db = await database;
    final results = await db.query(
      'raw_sensor_data',
      where: 'user_id = ? AND timestamp >= ? AND timestamp <= ?',
      whereArgs: [userId, startTime, endTime],
      orderBy: 'timestamp ASC',
    );
    return results.map((map) => VitalSign.fromMap(map)).toList();
  }

  // Missing methods for HomeScreen
  Future<WellnessMetrics?> getWellnessMetricsForDate(String userId, String date) async {
    final db = await database;
    debugPrint('🔍 DB: Querying wellness metrics - userId=$userId, date=$date');
    final results = await db.query(
      'wellness_metrics',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, date],
      limit: 1,
    );
    debugPrint('📊 DB: Found ${results.length} results');
    if (results.isNotEmpty) {
      debugPrint('📊 DB: Result - ${results.first}');
    }
    if (results.isEmpty) return null;
    return WellnessMetrics.fromMap(results.first);
  }

  Future<List<NutritionEntry>> getNutritionEntriesForDate(String userId, String date) async {
    return getNutritionEntries(userId, date);
  }

  // Missing methods for ActivityScreen
  Future<List<WellnessMetrics>> getWellnessMetricsInRange(String userId, String startDate, String endDate) async {
    final db = await database;
    final results = await db.query(
      'wellness_metrics',
      where: 'user_id = ? AND date >= ? AND date <= ?',
      whereArgs: [userId, startDate, endDate],
      orderBy: 'date ASC',
    );
    return results.map((map) => WellnessMetrics.fromMap(map)).toList();
  }
}
