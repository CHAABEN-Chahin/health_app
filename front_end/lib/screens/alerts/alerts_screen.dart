import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/alerts_provider.dart';
import '../../models/alert.dart';
import 'package:intl/intl.dart';


class AlertSeverity {
  static const String emergency = 'EMERGENCY';
  static const String critical = 'CRITICAL';
  static const String warning = 'WARNING';
  static const String info = 'INFO';
}

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({Key? key}) : super(key: key);

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AlertsProvider>(context, listen: false).loadAlerts();
    });
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
        title: Text('Health Alerts', style: AppTextStyles.header3),
        actions: [
          Consumer<AlertsProvider>(
            builder: (context, alertsProvider, _) => IconButton(
              icon: Icon(
                Icons.check_circle_outline,
                color: alertsProvider.unacknowledgedCount > 0 ? Colors.white : Colors.grey,
              ),
              onPressed: alertsProvider.unacknowledgedCount > 0
                  ? () async {
                      final alertIds = alertsProvider.unacknowledgedAlerts
                          .map((a) => a.id)
                          .cast<String>()
                          .toList();
                      await alertsProvider.acknowledgeMultiple(alertIds);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.check_circle, color: AppColors.successGreen, size: 20),
                                const SizedBox(width: 8),
                                Text('All ${alertIds.length} alerts acknowledged'),
                              ],
                            ),
                            backgroundColor: AppColors.secondaryDark,
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    }
                  : null,
              tooltip: 'Acknowledge all alerts',
            ),
          ),
        ],
      ),
      body: Consumer<AlertsProvider>(
        builder: (context, alertsProvider, _) {
          if (alertsProvider.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.pinkPrimary),
              ),
            );
          }

          return Column(
            children: [
              _buildFilterTabs(alertsProvider),
              _buildStatsBar(alertsProvider),
              Expanded(
                child: alertsProvider.filteredAlerts.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () => alertsProvider.loadAlerts(),
                        backgroundColor: AppColors.secondaryDark,
                        color: AppColors.pinkPrimary,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: alertsProvider.filteredAlerts.length,
                          itemBuilder: (context, index) {
                            final alert = alertsProvider.filteredAlerts[index];
                            return _buildAlertCard(alert, alertsProvider);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterTabs(AlertsProvider alertsProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', null, alertsProvider),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Emergency',
              'EMERGENCY',
              alertsProvider,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Critical',
              'CRITICAL',
              alertsProvider,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Warning',
              'WARNING',
              alertsProvider,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String? severity,
    AlertsProvider alertsProvider,
  ) {
    final isSelected = alertsProvider.currentFilter == severity;
    Color chipColor;
    
    if (severity == null) {
      chipColor = AppColors.pinkPrimary;
    } else {
      chipColor = Alert(
        id: '1',
        userId: '1',
        severity: severity,
        vitalType: 'heart_rate',
        message: '',
        recommendation: '',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ).getSeverityColorObj();
    }

    return GestureDetector(
      onTap: () => alertsProvider.setFilter(severity),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : AppColors.secondaryDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : chipColor.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBar(AlertsProvider alertsProvider) {
    final counts = alertsProvider.getAlertCountsBySeverity();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Emergency',
            counts[AlertSeverity.emergency]!,
            AppColors.emergencyRed,
          ),
          _buildStatItem(
            'Critical',
            counts[AlertSeverity.critical]!,
            AppColors.warningOrange,
          ),
          _buildStatItem(
            'Warning',
            counts[AlertSeverity.warning]!,
            AppColors.warningOrange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: AppTextStyles.header2.copyWith(color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.mediumGray),
        ),
      ],
    );
  }

  Widget _buildAlertCard(Alert alert, AlertsProvider alertsProvider) {
    final color = alert.getSeverityColorObj();
    final timeAgo = _getTimeAgo(DateTime.fromMillisecondsSinceEpoch(alert.timestamp));

    return Dismissible(
      key: Key(alert.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.emergencyRed,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        alertsProvider.deleteAlert(alert.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alert deleted'),
            backgroundColor: AppColors.secondaryDark,
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          if (!alert.isRead) {
            alertsProvider.markAsRead(alert.id);
          }
          _showAlertDetails(alert);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: alert.isRead
                ? AppColors.secondaryDark
                : AppColors.secondaryDark.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: alert.isRead ? color.withOpacity(0.3) : color,
              width: alert.isRead ? 1 : 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      alert.getSeverityIcon(),
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                alert.title ?? 'Alert',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                            if (!alert.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppColors.pinkPrimary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timeAgo,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.mediumGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                alert.message,
                style: AppTextStyles.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (alert.vitalValue != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${alert.vitalType}: ${alert.vitalValue}',
                    style: AppTextStyles.bodySmall.copyWith(color: color),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        await alertsProvider.acknowledgeAlert(alert.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.check_circle, color: AppColors.successGreen, size: 20),
                                  SizedBox(width: 8),
                                  Text('Alert acknowledged'),
                                ],
                              ),
                              backgroundColor: AppColors.secondaryDark,
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              color.withOpacity(0.8),
                              color,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check, color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Acknowledge',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAlertDetails(Alert alert) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.secondaryDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final color = alert.getSeverityColorObj();
        
        return Padding(
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
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      alert.getSeverityIcon(),
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alert.title ?? 'Alert', style: AppTextStyles.header3.copyWith(color: color)),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy • HH:mm').format(DateTime.fromMillisecondsSinceEpoch(alert.timestamp)),
                          style: AppTextStyles.caption.copyWith(color: AppColors.mediumGray),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Description', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(alert.message, style: AppTextStyles.bodyMedium),
              ...[
                const SizedBox(height: 16),
                Text('Recommendation', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.successGreen.withOpacity(0.3)),
                  ),
                  child: Text(alert.recommendation, style: AppTextStyles.bodyMedium),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.successGreen.withOpacity(0.2),
                    AppColors.successGreen.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle, 
                size: 80, 
                color: AppColors.successGreen,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'All Clear! 🎉',
              style: AppTextStyles.header2.copyWith(color: AppColors.successGreen),
            ),
            const SizedBox(height: 12),
            Text(
              'No pending alerts',
              style: AppTextStyles.bodyLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'All your health alerts have been acknowledged.\nYour vitals are being monitored.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mediumGray),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd').format(timestamp);
    }
  }
}
