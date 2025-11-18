import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bluetooth_provider.dart';
import '../../widgets/common/gradient_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _criticalAlertsEnabled = true;
  bool _warningAlertsEnabled = true;
  bool _autoSync = true;

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
        title: Text('Settings', style: AppTextStyles.header3),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDeviceSection(),
            const SizedBox(height: 24),
            _buildNotificationsSection(),
            const SizedBox(height: 24),
            _buildDataSection(),
            const SizedBox(height: 24),
            _buildAccountSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceSection() {
    return Consumer<BluetoothProvider>(
      builder: (context, bluetooth, _) {
        return _buildSection(
          'Device Connection',
          Icons.bluetooth,
          [
            _buildDeviceStatus(bluetooth),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GradientButton(
                    text: bluetooth.isConnected ? 'Disconnect' : 'Scan Devices',
                    onPressed: bluetooth.isConnected
                        ? () => bluetooth.disconnect()
                        : () => bluetooth.startScan(),
                    gradientColors: const [AppColors.pinkPrimary, AppColors.purplePrimary],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GradientButton(
                    text: bluetooth.isMockMode ? 'Real Mode' : 'Mock Mode',
                    onPressed: () => bluetooth.toggleMockMode(),
                    isOutlined: true,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildDeviceStatus(BluetoothProvider bluetooth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.tertiaryDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            bluetooth.isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
            color: bluetooth.isConnected ? AppColors.successGreen : AppColors.mediumGray,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bluetooth.deviceName ?? 'No device connected',
                  style: AppTextStyles.bodyMedium,
                ),
                Text(
                  bluetooth.connectionStatus,
                  style: AppTextStyles.caption.copyWith(color: AppColors.mediumGray),
                ),
              ],
            ),
          ),
          if (bluetooth.isConnected && bluetooth.batteryLevel > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withAlpha(48),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${bluetooth.batteryLevel}%',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.successGreen),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return _buildSection(
      'Notifications',
      Icons.notifications_outlined,
      [
        _buildSwitchTile(
          'Enable Notifications',
          'Receive health alerts and reminders',
          _notificationsEnabled,
          (value) => setState(() => _notificationsEnabled = value),
        ),
        const SizedBox(height: 12),
        _buildSwitchTile(
          'Critical Alerts',
          'Emergency health warnings',
          _criticalAlertsEnabled,
          (value) => setState(() => _criticalAlertsEnabled = value),
          enabled: _notificationsEnabled,
        ),
        const SizedBox(height: 12),
        _buildSwitchTile(
          'Warning Alerts',
          'Health warnings and reminders',
          _warningAlertsEnabled,
          (value) => setState(() => _warningAlertsEnabled = value),
          enabled: _notificationsEnabled,
        ),
      ],
    );
  }

  Widget _buildDataSection() {
    return _buildSection(
      'Data & Sync',
      Icons.cloud_outlined,
      [
        _buildSwitchTile(
          'Auto Sync',
          'Automatically sync data to cloud',
          _autoSync,
          (value) => setState(() => _autoSync = value),
        ),
        const SizedBox(height: 16),
        GradientButton(
          text: 'Sync Now',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Data synced successfully'),
                backgroundColor: AppColors.successGreen,
              ),
            );
          },
          icon: Icons.sync,
          isOutlined: true,
        ),
        const SizedBox(height: 12),
        GradientButton(
          text: 'Export Data',
          onPressed: () {},
          icon: Icons.download,
          isOutlined: true,
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return _buildSection(
          'Account',
          Icons.person_outline,
          [
            _buildListTile(
              'Change Password',
              Icons.lock_outline,
              () {},
            ),
            const SizedBox(height: 12),
            _buildListTile(
              'Privacy Policy',
              Icons.privacy_tip_outlined,
              () {},
            ),
            const SizedBox(height: 12),
            _buildListTile(
              'Terms of Service',
              Icons.description_outlined,
              () {},
            ),
            const SizedBox(height: 24),
            GradientButton(
              text: 'Logout',
              onPressed: () async {
                await authProvider.logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
              icon: Icons.logout,
              gradientColors: [AppColors.emergencyRed, AppColors.warningOrange],
            ),
            const SizedBox(height: 12),
            GradientButton(
              text: 'Delete Account',
              onPressed: () => _showDeleteConfirmation(authProvider),
              icon: Icons.delete_forever,
              isOutlined: true,
            ),
          ],
        );
      },
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

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged, {
    bool enabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.tertiaryDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: enabled ? Colors.white : AppColors.mediumGray,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(color: AppColors.mediumGray),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeColor: AppColors.pinkPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.tertiaryDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.pinkPrimary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: AppTextStyles.bodyMedium),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.mediumGray),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryDark,
        title: Text('Delete Account', style: AppTextStyles.header3),
        content: Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTextStyles.bodyMedium),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await authProvider.deleteAccount('');
              if (success && mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            child: Text(
              'Delete',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.emergencyRed),
            ),
          ),
        ],
      ),
    );
  }
}
