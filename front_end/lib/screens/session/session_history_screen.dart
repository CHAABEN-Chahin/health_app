import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../services/database_service.dart';
import '../../models/session.dart';
import '../../providers/auth_provider.dart';

class SessionHistoryScreen extends StatefulWidget {
  const SessionHistoryScreen({Key? key}) : super(key: key);

  @override
  State<SessionHistoryScreen> createState() => _SessionHistoryScreenState();
}

class _SessionHistoryScreenState extends State<SessionHistoryScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Session> _sessions = [];
  bool _isLoading = true;
  String _filterPeriod = 'week'; // week, month, all

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userId ?? '1';
      
      // Get all sessions
      final allSessions = await _databaseService.getSessions(userId);
      
      // Filter based on selected period
      final now = DateTime.now();
      List<Session> filteredSessions = allSessions;
      
      if (_filterPeriod == 'week') {
        final weekAgo = now.subtract(const Duration(days: 7));
        filteredSessions = allSessions.where((session) {
          final sessionTime = DateTime.fromMillisecondsSinceEpoch(session.startTime * 1000);
          return sessionTime.isAfter(weekAgo);
        }).toList();
      } else if (_filterPeriod == 'month') {
        final monthAgo = now.subtract(const Duration(days: 30));
        filteredSessions = allSessions.where((session) {
          final sessionTime = DateTime.fromMillisecondsSinceEpoch(session.startTime * 1000);
          return sessionTime.isAfter(monthAgo);
        }).toList();
      }
      
      if (mounted) {
        setState(() {
          _sessions = filteredSessions;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading sessions: $e');
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
        title: Text('Workout Sessions', style: AppTextStyles.header3),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            color: AppColors.secondaryDark,
            onSelected: (value) {
              setState(() => _filterPeriod = value);
              _loadSessions();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'week',
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: _filterPeriod == 'week' ? AppColors.pinkPrimary : Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Last 7 Days',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: _filterPeriod == 'week' ? AppColors.pinkPrimary : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'month',
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      color: _filterPeriod == 'month' ? AppColors.pinkPrimary : Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Last 30 Days',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: _filterPeriod == 'month' ? AppColors.pinkPrimary : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(
                      Icons.all_inclusive,
                      color: _filterPeriod == 'all' ? AppColors.pinkPrimary : Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'All Sessions',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: _filterPeriod == 'all' ? AppColors.pinkPrimary : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _sessions.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadSessions,
                  backgroundColor: AppColors.secondaryDark,
                  color: AppColors.pinkPrimary,
                  child: Column(
                    children: [
                      _buildSummaryCards(),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _sessions.length,
                          itemBuilder: (context, index) {
                            return _buildSessionCard(_sessions[index]);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/start-session');
          if (result == true) {
            _loadSessions();
          }
        },
        backgroundColor: AppColors.pinkPrimary,
        icon: const Icon(Icons.play_arrow),
        label: Text('Start Session', style: AppTextStyles.bodyMedium),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.pinkPrimary),
          ),
          const SizedBox(height: 16),
          Text('Loading sessions...', style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondaryDark,
              border: Border.all(color: AppColors.pinkPrimary.withAlpha(76)),
            ),
            child: Icon(
              Icons.fitness_center,
              size: 80,
              color: AppColors.pinkPrimary.withAlpha(128),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Workout Sessions Yet',
            style: AppTextStyles.header3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Start your first workout session\nto track your progress',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mediumGray),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.pushNamed(context, '/start-session');
              if (result == true) {
                _loadSessions();
              }
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Session'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pinkPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalSessions = _sessions.length;
    final totalDuration = _sessions.fold<int>(0, (sum, s) => sum + (s.durationSeconds ?? 0));
    final totalCalories = _sessions.fold<int>(0, (sum, s) => sum + (s.caloriesBurned ?? 0));
    
    final hours = totalDuration ~/ 3600;
    final minutes = (totalDuration % 3600) ~/ 60;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              icon: Icons.fitness_center,
              label: 'Sessions',
              value: '$totalSessions',
              color: AppColors.pinkPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              icon: Icons.timer,
              label: 'Duration',
              value: hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m',
              color: AppColors.purplePrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              icon: Icons.local_fire_department,
              label: 'Calories',
              value: '$totalCalories',
              color: AppColors.warningOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondaryDark,
            AppColors.secondaryDark.withAlpha(200),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.header3.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.mediumGray),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(Session session) {
    final startTime = DateTime.fromMillisecondsSinceEpoch(session.startTime * 1000);
    final duration = Duration(seconds: session.durationSeconds ?? 0);
    final durationStr = '${duration.inMinutes}m ${duration.inSeconds % 60}s';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondaryDark,
            AppColors.secondaryDark.withAlpha(200),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.pinkPrimary.withAlpha(48)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showSessionDetails(session),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getSessionIcon(session.sessionType),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatSessionType(session.sessionType),
                            style: AppTextStyles.header3.copyWith(fontSize: 18),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd, yyyy • hh:mm a').format(startTime),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.mediumGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.successGreen.withAlpha(48),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.successGreen.withAlpha(76)),
                      ),
                      child: Text(
                        'Completed',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.successGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.mediumGray, thickness: 0.5),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSessionStat(
                      icon: Icons.timer,
                      label: 'Duration',
                      value: durationStr,
                    ),
                    _buildSessionStat(
                      icon: Icons.favorite,
                      label: 'Avg HR',
                      value: '${session.avgHeartRate ?? 0} BPM',
                    ),
                    _buildSessionStat(
                      icon: Icons.local_fire_department,
                      label: 'Calories',
                      value: '${session.caloriesBurned ?? 0}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.pinkPrimary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.mediumGray),
        ),
      ],
    );
  }

  void _showSessionDetails(Session session) {
    final startTime = DateTime.fromMillisecondsSinceEpoch(session.startTime * 1000);
    final endTime = session.endTime != null
        ? DateTime.fromMillisecondsSinceEpoch(session.endTime! * 1000)
        : null;
    final duration = Duration(seconds: session.durationSeconds ?? 0);

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getSessionIcon(session.sessionType),
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  _formatSessionType(session.sessionType),
                  style: AppTextStyles.header2,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Start Time', DateFormat('MMM dd, yyyy • hh:mm a').format(startTime)),
            if (endTime != null)
              _buildDetailRow('End Time', DateFormat('hh:mm a').format(endTime)),
            _buildDetailRow('Duration', '${duration.inMinutes}m ${duration.inSeconds % 60}s'),
            _buildDetailRow('Avg Heart Rate', '${session.avgHeartRate ?? 0} BPM'),
            _buildDetailRow('Max Heart Rate', '${session.maxHeartRate ?? 0} BPM'),
            _buildDetailRow('Calories Burned', '${session.caloriesBurned ?? 0} kcal'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mediumGray),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  IconData _getSessionIcon(String type) {
    switch (type.toLowerCase()) {
      case 'running':
        return Icons.directions_run;
      case 'walking':
        return Icons.directions_walk;
      case 'cycling':
        return Icons.directions_bike;
      case 'gym':
        return Icons.fitness_center;
      case 'yoga':
        return Icons.self_improvement;
      default:
        return Icons.sports;
    }
  }

  String _formatSessionType(String type) {
    return type[0].toUpperCase() + type.substring(1);
  }
}
