import 'package:flutter/material.dart';
import '../../core/theme/text_styles.dart';

class DebugScenarioBanner extends StatelessWidget {
  final String scenario;
  
  const DebugScenarioBanner({
    Key? key,
    required this.scenario,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Only show in debug mode
    if (!const bool.fromEnvironment('dart.vm.product')) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _getScenarioColor().withAlpha(224),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getScenarioIcon(),
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Simulating: ${_getScenarioDisplayName()}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
  
  Color _getScenarioColor() {
    switch (scenario) {
      case 'emergency':
        return Colors.red.shade900;
      case 'very_high_hr':
      case 'very_low_spo2':
      case 'high_fever':
        return Colors.red.shade700;
      case 'high_hr':
      case 'low_spo2':
      case 'fever':
      case 'tachycardia':
        return Colors.orange.shade700;
      case 'bradycardia':
        return Colors.amber.shade700;
      case 'normal':
      default:
        return Colors.green.shade700;
    }
  }
  
  IconData _getScenarioIcon() {
    switch (scenario) {
      case 'emergency':
        return Icons.warning_amber_rounded;
      case 'very_high_hr':
      case 'high_hr':
      case 'tachycardia':
        return Icons.favorite;
      case 'very_low_spo2':
      case 'low_spo2':
        return Icons.air;
      case 'high_fever':
      case 'fever':
        return Icons.thermostat;
      case 'bradycardia':
        return Icons.heart_broken;
      case 'normal':
      default:
        return Icons.check_circle;
    }
  }
  
  String _getScenarioDisplayName() {
    switch (scenario) {
      case 'emergency':
        return 'EMERGENCY (Multiple Critical Values)';
      case 'very_high_hr':
        return 'Very High Heart Rate (175-190 bpm)';
      case 'high_hr':
        return 'High Heart Rate (155-170 bpm)';
      case 'very_low_spo2':
        return 'Critical Low SpO2 (85-88%)';
      case 'low_spo2':
        return 'Low SpO2 (90-92%)';
      case 'high_fever':
        return 'High Fever (38.6-39.4°C)';
      case 'fever':
        return 'Mild Fever (37.8-38.5°C)';
      case 'bradycardia':
        return 'Low Heart Rate (45-50 bpm)';
      case 'tachycardia':
        return 'Resting Tachycardia (115-130 bpm)';
      case 'normal':
      default:
        return 'Normal Vitals';
    }
  }
}
