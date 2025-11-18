import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';

class VitalCard extends StatefulWidget {
  final String icon;
  final String value;
  final String label;
  final String? unit;
  final String? trend;
  final Color? iconColor;
  final VoidCallback? onTap;
  final bool isLive;

  const VitalCard({
    Key? key,
    required this.icon,
    required this.value,
    required this.label,
    this.unit,
    this.trend,
    this.iconColor,
    this.onTap,
    this.isLive = false,
  }) : super(key: key);

  @override
  State<VitalCard> createState() => _VitalCardState();
}

class _VitalCardState extends State<VitalCard> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(VitalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLive && oldWidget.value != widget.value) {
      _shimmerController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.cardGradient,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.isLive && _shimmerController.isAnimating
                    ? (widget.iconColor ?? AppColors.pinkPrimary).withOpacity(0.5 + _shimmerController.value * 0.5)
                    : AppColors.white.withOpacity(0.05),
                width: widget.isLive && _shimmerController.isAnimating ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.isLive && _shimmerController.isAnimating
                      ? (widget.iconColor ?? AppColors.pinkPrimary).withOpacity(0.3 * _shimmerController.value)
                      : AppColors.pinkPrimary.withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          );
        },
        child: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (widget.iconColor ?? AppColors.pinkPrimary).withOpacity(0.2),
                        (widget.iconColor ?? AppColors.purplePrimary).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                if (widget.trend != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.trend!.startsWith('+')
                          ? AppColors.successGreen.withOpacity(0.2)
                          : AppColors.emergencyRed.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          widget.trend!.startsWith('+')
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 12,
                          color: widget.trend!.startsWith('+')
                              ? AppColors.successGreen
                              : AppColors.emergencyRed,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          widget.trend!,
                          style: AppTextStyles.caption.copyWith(
                            color: widget.trend!.startsWith('+')
                                ? AppColors.successGreen
                                : AppColors.emergencyRed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  widget.value,
                  style: AppTextStyles.vitalValueMedium,
                ),
                if (widget.unit != null) ...[
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      widget.unit!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.mediumGray,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.label.toUpperCase(),
              style: AppTextStyles.vitalLabel,
            ),
          ],
        ),
      ),
      ),
    );
  }
}
