# 🔍 Implementation Specifications - Technical Reference

This document provides exact specifications for implementing remaining features.

---

## 📋 Screen Specifications

### 1. HOME SCREEN (`home_screen.dart`)

**Layout Structure:**
```
AppBar (Transparent)
├─ Logo (left)
├─ Bluetooth Icon (status indicator)
└─ Notification Bell (with badge)

Body (SingleChildScrollView)
├─ Section 1: Daily Activity Summary Card
│   ├─ CircularProgress (calories: value/goal)
│   ├─ Mini line chart (hourly steps)
│   └─ Distance row (icon + "5.2 km")
│
├─ Section 2: Live Vitals Grid (2x3)
│   ├─ VitalCard: Heart Rate
│   ├─ VitalCard: SpO2
│   ├─ VitalCard: Temperature
│   ├─ VitalCard: Stress Level
│   ├─ VitalCard: Wellness Score
│   └─ VitalCard: Battery
│
├─ Section 3: Nutrition Card
│   ├─ "Log your meal" text
│   ├─ Meal chips (if logged)
│   └─ "📷 Scan Food" button
│
└─ Section 4: Quick Actions
    ├─ "Start Workout Session" (large gradient button)
    └─ Secondary buttons row

Drawer (NavigationDrawer)
├─ User Header (avatar + name)
├─ View Profile
├─ Statistics
├─ Achievements
├─ Health Library
├─ Help & Support
└─ Logout
```

**Data Sources:**
- `VitalsProvider` - Latest vital signs
- `WellnessMetrics` - Today's activity data
- `DatabaseService` - Nutrition entries

**Key Widgets:**
```dart
CircularProgress(
  value: caloriesBurned / calorieGoal,
  centerText: '$caloriesBurned',
  label: 'CALORIES',
)

GridView.count(
  crossAxisCount: 2,
  children: [
    VitalCard(icon: '❤️', value: '72', label: 'BPM'),
    VitalCard(icon: '🫁', value: '98', label: 'SpO2'),
    // ...
  ],
)
```

**Animations:**
- Card entrance: Stagger animation (50ms delay each)
- Pull to refresh: Custom refresh indicator
- Vitals update: Pulse effect on change

---

### 2. VITALS DETAIL SCREEN (`vitals_detail_screen.dart`)

**Layout:**
```
AppBar
└─ "Health Vitals" title

TabBar (scrollable)
├─ Heart Rate
├─ SpO2
├─ Temperature
├─ Stress Level
└─ Wellness Score

TabBarView
└─ For each vital:
    ├─ Current Value Card (large)
    │   ├─ Number (48sp)
    │   ├─ Trend arrow + change
    │   └─ Status indicator
    │
    ├─ Time Range Selector
    │   [1H] [6H] [24H] [7D] [30D]
    │
    ├─ Line Chart (FL Chart)
    │   ├─ Gradient fill below line
    │   ├─ Data points with tooltips
    │   └─ Zone backgrounds (for HR)
    │
    └─ Statistics Card
        ├─ Min / Avg / Max
        ├─ Resting (for HR)
        └─ HRV (for HR)
```

**Chart Configuration:**
```dart
LineChart(
  LineChartData(
    lineBarsData: [
      LineChartBarData(
        spots: dataPoints,
        isCurved: true,
        gradient: AppColors.primaryGradient,
        dotData: FlDotData(show: true),
        belowBarData: BarAreaData(
          show: true,
          gradient: AppColors.chartGradient,
        ),
      ),
    ],
    gridData: FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: 20,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: AppColors.darkGray,
          strokeWidth: 1,
        );
      },
    ),
  ),
)
```

**Data Queries:**
```dart
// Get vitals for time range
final vitals = await DatabaseService().getVitalSigns(
  userId,
  sinceTimestamp: selectedRange.startTimestamp,
);

// Process for chart
final chartData = vitals.map((v) => FlSpot(
  v.timestamp.toDouble(),
  v.heartRate!.toDouble(),
)).toList();
```

---

### 3. DAILY ACTIVITY SCREEN (`daily_activity_screen.dart`)

**Layout:**
```
AppBar
├─ Date selector (< Today >)
└─ Tab navigation

TabBar
├─ Today
├─ This Week
└─ This Month

TabBarView > Today Tab:
├─ Calories Burned Card
│   ├─ Large number + goal
│   ├─ Hourly bar chart (24 hours)
│   └─ Peak hour indicator
│
├─ Steps Card
│   ├─ Large number + goal
│   ├─ Line chart (hourly)
│   └─ Average steps/hour
│
├─ Distance Card
│   ├─ Total km
│   ├─ Map view (optional)
│   └─ Average pace
│
└─ Active Minutes Card
    ├─ Total minutes
    ├─ Pie chart (Light/Moderate/Vigorous)
    └─ Goal progress
```

**Bar Chart (Hourly Calories):**
```dart
BarChart(
  BarChartData(
    barGroups: List.generate(24, (hour) {
      return BarChartGroupData(
        x: hour,
        barRods: [
          BarChartRodData(
            toY: hourlyData[hour].toDouble(),
            gradient: AppColors.primaryGradient,
            width: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }),
    titlesData: FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            return Text('${value.toInt()}h');
          },
        ),
      ),
    ),
  ),
)
```

**Week/Month Tabs:**
- 7-day comparison (bar chart per day)
- Monthly calendar heatmap
- Best day highlight
- Weekly/monthly averages

---

### 4. ALERTS SCREEN (`alerts_screen.dart`)

**Layout:**
```
AppBar
└─ "Alerts & Suggestions"

Filter TabBar
├─ All
├─ Critical
├─ Warnings
└─ Suggestions

ListView
└─ For each alert:
    AlertCard
    ├─ Left border (severity color)
    ├─ Icon (severity emoji)
    ├─ Timestamp (relative)
    ├─ Title (bold)
    ├─ Message
    ├─ Recommendation
    └─ Actions
        ├─ "Acknowledge" button
        └─ "View Details" button
```

**AlertCard Widget:**
```dart
Container(
  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: AppColors.secondaryDark,
    borderRadius: BorderRadius.circular(16),
    border: Border(
      left: BorderSide(
        color: alert.getSeverityColor(),
        width: 4,
      ),
    ),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(alert.getSeverityIcon()),
          SizedBox(width: 8),
          Text(
            Helpers.formatRelativeTime(alert.timestamp),
            style: AppTextStyles.caption,
          ),
        ],
      ),
      SizedBox(height: 8),
      Text(alert.message, style: AppTextStyles.bodyLarge.copyWith(
        fontWeight: FontWeight.bold,
      )),
      SizedBox(height: 4),
      Text(alert.recommendation, style: AppTextStyles.bodyMedium),
      SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (!alert.acknowledged)
            TextButton(
              onPressed: () => acknowledgeAlert(alert.id),
              child: Text('Acknowledge'),
            ),
          TextButton(
            onPressed: () => viewAlertDetails(alert),
            child: Text('View Details'),
          ),
        ],
      ),
    ],
  ),
)
```

**Data Query:**
```dart
// Stream of alerts
StreamBuilder<List<Alert>>(
  stream: AlertsProvider.alertsStream,
  builder: (context, snapshot) {
    if (!snapshot.hasData) return LoadingIndicator();
    
    final alerts = snapshot.data!;
    // Filter by selected tab
    final filtered = alerts.where((a) {
      if (selectedTab == 'Critical') {
        return a.severity == 'CRITICAL' || a.severity == 'EMERGENCY';
      }
      // ...
    }).toList();
    
    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return AlertCard(alert: filtered[index]);
      },
    );
  },
)
```

---

### 5. PROFILE SCREEN (`profile_screen.dart`)

**Layout:**
```
AppBar
└─ "Profile" + Edit icon

Body (ScrollView)
├─ Header Card (gradient background)
│   ├─ Avatar (large, tappable)
│   ├─ Name
│   └─ "Welcome, {username}!"
│
├─ Personal Details Card
│   ├─ Name, Age, Gender
│   └─ Edit button
│
├─ Body Measurements Card
│   ├─ Weight, Height
│   └─ BMI Display
│       ├─ BMI value
│       ├─ Category (Underweight/Normal/Overweight/Obese)
│       └─ BMI Chart (horizontal bar with ranges)
│
├─ Activity Level Card
│   └─ Current setting with icon
│
├─ Health Conditions Card
│   └─ List of checked conditions
│
├─ Goals Card
│   ├─ Current goal
│   ├─ Target weight
│   └─ Progress percentage
│
└─ Account Settings Card
    ├─ Email, Username
    ├─ Change Password button
    └─ Delete Account button (red)
```

**BMI Chart Widget:**
```dart
Container(
  height: 40,
  child: CustomPaint(
    painter: BMIChartPainter(
      bmi: calculatedBMI,
      ranges: [
        BMIRange(0, 18.5, Colors.blue, 'Under'),
        BMIRange(18.5, 25, Colors.green, 'Normal'),
        BMIRange(25, 30, Colors.orange, 'Over'),
        BMIRange(30, 50, Colors.red, 'Obese'),
      ],
    ),
    child: // Pin marker at user's BMI
  ),
)
```

**Edit Mode:**
- Toggle between view/edit
- TextFields replace Text widgets
- Save/Cancel buttons appear
- Validation on save

---

### 6. START SESSION SCREEN (`start_session_screen.dart`)

**Layout:**
```
Full Screen (Dark overlay)

Center Content
├─ Session Timer (huge)
│   └─ "00:12:45"
│
├─ Live Vitals Grid (2x2)
│   ├─ Heart Rate (with mini chart)
│   ├─ Calories Burned
│   ├─ SpO2
│   └─ Temperature
│
├─ Session Type Chip
│   └─ "Cardio" | "Strength" | "Yoga" | "Custom"
│
├─ Intensity Indicator
│   └─ HR zone bar (color-coded)
│
└─ Controls
    ├─ Pause/Resume button (large, center)
    └─ End Session button (smaller, red)

Bottom
└─ Motivational Messages (fade in periodically)
```

**Real-time Updates:**
```dart
StreamBuilder<Map<String, dynamic>>(
  stream: BluetoothService().dataStream,
  builder: (context, snapshot) {
    if (!snapshot.hasData) return Container();
    
    final data = snapshot.data!;
    final hr = data['heart_rate'];
    final calories = calculateCalories(duration, hr);
    
    return GridView.count(
      crossAxisCount: 2,
      children: [
        VitalCard(
          icon: '❤️',
          value: '$hr',
          label: 'BPM',
          trend: calculateTrend(hr),
        ),
        VitalCard(
          icon: '🔥',
          value: '$calories',
          label: 'CAL',
        ),
        // ...
      ],
    );
  },
)
```

**Timer Logic:**
```dart
class _StartSessionScreenState extends State<StartSessionScreen> {
  int _elapsedSeconds = 0;
  Timer? _timer;
  bool _isPaused = false;
  
  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() => _elapsedSeconds++);
      }
    });
  }
  
  void _pauseResume() {
    setState(() => _isPaused = !_isPaused);
  }
  
  void _endSession() async {
    _timer?.cancel();
    
    // Calculate averages
    final session = Session(
      id: Uuid().v4(),
      userId: userId,
      sessionType: selectedType,
      startTime: startTimestamp,
      endTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      durationSeconds: _elapsedSeconds,
      avgHeartRate: calculateAvgHR(),
      maxHeartRate: maxHR,
      caloriesBurned: totalCalories,
    );
    
    // Save to database
    await DatabaseService().insertSession(session);
    
    // Show summary
    _showSummary(session);
  }
}
```

**Summary Dialog:**
```dart
Dialog(
  child: Container(
    padding: EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Lottie.asset('assets/animations/success.json'), // Confetti
        SizedBox(height: 16),
        Text('Workout Complete! 🎉', style: AppTextStyles.header2),
        SizedBox(height: 24),
        StatRow(label: 'Duration', value: session.formattedDuration),
        StatRow(label: 'Calories', value: '${session.caloriesBurned}'),
        StatRow(label: 'Avg HR', value: '${session.avgHeartRate} bpm'),
        StatRow(label: 'Max HR', value: '${session.maxHeartRate} bpm'),
        SizedBox(height: 24),
        GradientButton(
          text: 'Share Achievement',
          onPressed: () {}, // TODO: Share functionality
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    ),
  ),
)
```

---

### 7. SETTINGS SCREEN (`settings_screen.dart`)

**Layout:**
```
AppBar
└─ "Settings"

ListView
├─ Section: Account
│   ├─ Profile info (read-only)
│   ├─ Login credentials
│   └─ Sync preferences
│
├─ Section: Wearable Device
│   ├─ Device name (if connected)
│   ├─ Battery level
│   ├─ Connection status indicator
│   ├─ "Pair New Device" button
│   ├─ "Disconnect" button
│   └─ Sync frequency slider (5s - 60s)
│
├─ Section: Notifications
│   ├─ Enable/Disable toggle
│   ├─ Notification types (checkboxes)
│   │   ├─ Critical health alerts
│   │   ├─ Daily motivation
│   │   ├─ Workout reminders
│   │   ├─ Goal achievements
│   │   └─ Low battery warnings
│   └─ Quiet hours picker
│
├─ Section: Alert Thresholds (Advanced)
│   ├─ Max HR slider (150-220)
│   ├─ Min SpO2 slider (80-95)
│   ├─ Temperature slider (37-40°C)
│   └─ "Reset to Defaults" button
│
├─ Section: Display
│   ├─ Units toggle (Metric/Imperial)
│   └─ Language selector
│
├─ Section: Data & Privacy
│   ├─ Cloud sync toggle
│   ├─ Sync only on WiFi toggle
│   ├─ "Export Data" button
│   ├─ "Clear Local Data" button (confirmation)
│   └─ "Delete Account" button (red, double confirmation)
│
└─ Section: About
    ├─ App version
    ├─ Privacy policy link
    ├─ Terms of service link
    └─ Contact support
```

**Toggle Example:**
```dart
SwitchListTile(
  title: Text('Cloud Sync'),
  subtitle: Text('Automatically sync data to cloud'),
  value: _cloudSyncEnabled,
  activeColor: AppColors.pinkPrimary,
  onChanged: (value) {
    setState(() => _cloudSyncEnabled = value);
    // Save to preferences
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('cloud_sync', value);
    });
  },
)
```

**Slider Example:**
```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text('Sync Frequency: ${_syncInterval}s'),
    Slider(
      value: _syncInterval.toDouble(),
      min: 5,
      max: 60,
      divisions: 11,
      label: '${_syncInterval}s',
      activeColor: AppColors.pinkPrimary,
      onChanged: (value) {
        setState(() => _syncInterval = value.toInt());
      },
    ),
  ],
)
```

---

## 🔗 Provider Implementation

### VitalsProvider
```dart
class VitalsProvider with ChangeNotifier {
  VitalSign? _latestVital;
  List<VitalSign> _recentVitals = [];
  StreamSubscription? _dataSubscription;

  VitalSign? get latestVital => _latestVital;
  List<VitalSign> get recentVitals => _recentVitals;

  void startListening(String userId) {
    _dataSubscription = BluetoothService().dataStream.listen((data) {
      final vital = VitalSign.fromJson(data, userId);
      
      // Update latest
      _latestVital = vital;
      _recentVitals.insert(0, vital);
      
      // Keep only last 100
      if (_recentVitals.length > 100) {
        _recentVitals.removeLast();
      }
      
      // Save to database
      DatabaseService().insertVitalSign(vital);
      
      // Check for alerts
      AlertEngine().checkVitals(vital, /* profile */);
      
      notifyListeners();
    });
  }

  void dispose() {
    _dataSubscription?.cancel();
    super.dispose();
  }
}
```

### Usage in Widget:
```dart
// In build method
final vitalsProvider = context.watch<VitalsProvider>();
final latestHR = vitalsProvider.latestVital?.heartRate ?? 0;

return VitalCard(
  icon: '❤️',
  value: '$latestHR',
  label: 'BPM',
);
```

---

## 📊 Chart Implementation Examples

### Line Chart (Vitals over Time)
```dart
Widget _buildLineChart(List<VitalSign> data) {
  return Container(
    height: 200,
    padding: EdgeInsets.all(16),
    child: LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: data.map((v) => FlSpot(
              v.timestamp.toDouble(),
              v.heartRate!.toDouble(),
            )).toList(),
            isCurved: true,
            gradient: AppColors.primaryGradient,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.white,
                  strokeWidth: 2,
                  strokeColor: AppColors.pinkPrimary,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.pinkPrimary.withAlpha(76),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final date = DateTime.fromMillisecondsSinceEpoch(
                  value.toInt() * 1000,
                );
                return Text(
                  DateFormat('HH:mm').format(date),
                  style: AppTextStyles.caption,
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}',
                  style: AppTextStyles.caption,
                );
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.darkGray,
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
      ),
    ),
  );
}
```

### Bar Chart (Activity per Hour)
```dart
Widget _buildBarChart(Map<int, int> hourlyData) {
  return Container(
    height: 180,
    padding: EdgeInsets.all(16),
    child: BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: hourlyData.values.reduce(max).toDouble() * 1.2,
        barGroups: List.generate(24, (hour) {
          final value = hourlyData[hour] ?? 0;
          return BarChartGroupData(
            x: hour,
            barRods: [
              BarChartRodData(
                toY: value.toDouble(),
                gradient: LinearGradient(
                  colors: [
                    AppColors.pinkPrimary,
                    AppColors.purplePrimary,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 8,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 3,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}h',
                  style: AppTextStyles.caption,
                );
              },
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    ),
  );
}
```

---

## 🎨 Animation Patterns

### Card Entrance (Stagger)
```dart
class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<Offset>> _animations;

  @override
  void initState() {
    super.initState();
    
    _controllers = List.generate(
      6, // Number of cards
      (index) => AnimationController(
        duration: Duration(milliseconds: 400),
        vsync: this,
      ),
    );
    
    _animations = _controllers.map((controller) {
      return Tween<Offset>(
        begin: Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ));
    }).toList();
    
    // Start animations with delay
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 50), () {
        _controllers[i].forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: 6,
      itemBuilder: (context, index) {
        return SlideTransition(
          position: _animations[index],
          child: FadeTransition(
            opacity: _controllers[index],
            child: VitalCard(/* ... */),
          ),
        );
      },
    );
  }
}
```

### Value Change Pulse
```dart
class _VitalCardState extends State<VitalCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void didUpdateWidget(VitalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _pulseController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: // Card content
    );
  }
}
```

---

## 📱 Responsive Design

### Breakpoints
```dart
class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 650;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 650 &&
      MediaQuery.of(context).size.width < 1100;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;
}

// Usage
GridView.count(
  crossAxisCount: Responsive.isMobile(context) ? 2 : 3,
  children: // ...
)
```

---

This technical reference provides the exact specifications needed to implement all remaining features. Follow these patterns for consistency with the existing codebase.
