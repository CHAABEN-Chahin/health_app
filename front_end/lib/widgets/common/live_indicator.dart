import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';

class LiveIndicator extends StatefulWidget {
  final bool isLive;
  final String? deviceName;
  
  const LiveIndicator({
    Key? key,
    this.isLive = false,
    this.deviceName,
  }) : super(key: key);

  @override
  State<LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<LiveIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    if (widget.isLive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(LiveIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLive != oldWidget.isLive) {
      if (widget.isLive) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.mediumGray.withAlpha(48),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.mediumGray.withAlpha(76)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.mediumGray,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Offline',
              style: AppTextStyles.caption.copyWith(color: AppColors.mediumGray),
            ),
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.successGreen.withAlpha(48),
                AppColors.successGreen.withAlpha(24),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.successGreen.withOpacity(_animation.value),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.successGreen.withOpacity(_animation.value * 0.5),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.successGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.successGreen.withOpacity(_animation.value),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'LIVE',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.successGreen,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              if (widget.deviceName != null) ...[
                const SizedBox(width: 4),
                Text(
                  '• ${widget.deviceName}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.lightGray,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
