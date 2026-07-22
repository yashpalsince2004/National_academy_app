import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppPullToRefresh extends StatefulWidget {
  const AppPullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.topPadding = 0,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final double topPadding;

  @override
  State<AppPullToRefresh> createState() => _AppPullToRefreshState();
}

class _AppPullToRefreshState extends State<AppPullToRefresh>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;
  double _dragOffset = 0.0;
  bool _isRefreshing = false;
  static const double _refreshTriggerOffset = 70.0;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
      _dragOffset = _refreshTriggerOffset;
    });
    _spinController.repeat();

    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        _spinController.stop();
        setState(() {
          _isRefreshing = false;
          _dragOffset = 0.0;
        });
      }
    }
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (_isRefreshing) return false;

    if (notification is ScrollUpdateNotification) {
      if (notification.metrics.extentBefore == 0 &&
          notification.scrollDelta != null &&
          notification.scrollDelta! < 0) {
        setState(() {
          _dragOffset = (_dragOffset - notification.scrollDelta!).clamp(0.0, 110.0);
        });
      } else if (notification.metrics.extentBefore > 0 && _dragOffset > 0) {
        setState(() {
          _dragOffset = 0.0;
        });
      }
    } else if (notification is OverscrollNotification) {
      if (notification.overscroll < 0) {
        setState(() {
          _dragOffset = (_dragOffset - notification.overscroll * 0.5).clamp(0.0, 110.0);
        });
      }
    } else if (notification is ScrollEndNotification) {
      if (_dragOffset >= _refreshTriggerOffset && !_isRefreshing) {
        _handleRefresh();
      } else if (!_isRefreshing) {
        setState(() {
          _dragOffset = 0.0;
        });
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = (_dragOffset / _refreshTriggerOffset).clamp(0.0, 1.0);
    final indicatorVisible = _dragOffset > 4.0 || _isRefreshing;

    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main Scrollable Content
          widget.child,

          // Icon-Only Animated Glowing Pull-to-Refresh Circle
          if (indicatorVisible)
            Positioned(
              top: widget.topPadding + (14.0 * progress) + (_isRefreshing ? 14.0 : 0.0),
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 150),
                  scale: indicatorVisible ? math.min(1.0, 0.4 + (progress * 0.6)) : 0.0,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceTile1.withValues(alpha: 0.95)
                          : Colors.white.withValues(alpha: 0.95),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.30),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.20),
                          blurRadius: 18,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: AnimatedBuilder(
                      animation: _spinController,
                      builder: (context, child) {
                        final angle = _isRefreshing
                            ? _spinController.value * 2 * math.pi
                            : progress * 2 * math.pi;
                        return Transform.rotate(
                          angle: angle,
                          child: Icon(
                            Icons.sync_rounded,
                            size: 22,
                            color: progress >= 1.0 || _isRefreshing
                                ? AppColors.primary
                                : AppColors.primary.withValues(alpha: 0.7),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
