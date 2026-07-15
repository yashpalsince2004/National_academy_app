import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:national_academy/core/constants/app_colors.dart';
import 'package:national_academy/core/services/supabase_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mock data – replace with real providers when available
// ─────────────────────────────────────────────────────────────────────────────
const _studentName = 'Yash';
const _batchName = 'Alpha JEE Pro';
const _batchClass = '12th • JEE';




const Map<String, String>? _upcomingTest = {
  'subject': 'Physics',
  'topic': 'Electrostatics – Unit Test',
  'date': 'Tomorrow',
  'time': '10:00 AM',
  'duration': '3 hrs',
  'marks': '100',
};

const List<Map<String, String>> _notices = [
  {
    'title': 'Sunday Extra Class – Physics',
    'subtitle': 'July 14 • 09:00 AM • Room A-101',
    'type': 'class',
  },
  {
    'title': 'Homework: DPP #14 Submission',
    'subtitle': 'Due: July 15 • Chemistry',
    'type': 'homework',
  },
  {
    'title': 'JEE Mock Test Schedule Updated',
    'subtitle': 'July 10 • Exam Cell Notice',
    'type': 'notice',
  },
];

// ─────────────────────────────────────────────────────────────────────────────
class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to realtime timetable updates
    ref.watch(timetableSubscriptionProvider);



    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final paddingTop = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.transparent,

      body: Stack(
        children: [
          // ── Scrollable Content ─────────────────────────────────────────────
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: paddingTop + 90.0,
                bottom: 120.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. ALERT – Live / Active lecture (highest priority)
                  _AlertCard(isDark: isDark),
                  const SizedBox(height: 16),

                  // 2. UPCOMING TEST
                  _UpcomingTestCard(isDark: isDark),
                  const SizedBox(height: 16),

                  // 3. UPCOMING LECTURE
                  ref.watch(studentUpcomingLecturesProvider).when(
                    data: (lectures) {
                      if (lectures.isEmpty) {
                        return _UpcomingLectureCard(
                          isDark: isDark,
                          upcomingLecture: null,
                        );
                      }
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: lectures.map((lecture) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _UpcomingLectureCard(
                              isDark: isDark,
                              upcomingLecture: lecture,
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => _UpcomingLectureCard(
                      isDark: isDark,
                      upcomingLecture: null,
                    ),
                    error: (err, _) => _UpcomingLectureCard(
                      isDark: isDark,
                      upcomingLecture: null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. HOMEWORK / NOTICES
                  _NoticesCard(isDark: isDark),
                ],
              ),
            ),
          ),

          // ── Pinned Blur Header ─────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: EdgeInsets.only(
                    top: paddingTop + 14,
                    bottom: 18,
                    left: 20,
                    right: 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.scaffoldBackgroundColor.withValues(alpha: 0.96),
                        theme.scaffoldBackgroundColor.withValues(alpha: 0.72),
                        theme.scaffoldBackgroundColor.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                  child: _GreetingHeader(isDark: isDark),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GREETING HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.isDark});
  final bool isDark;

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.ink;
    final mutedColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_greeting()}, $_studentName 👋',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$_batchName • $_batchClass',
                style: TextStyle(
                  fontSize: 13,
                  color: mutedColor,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
        // Notification bell
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.canvasParchment,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.notifications_none_rounded,
                  color: textColor, size: 22),
            ),
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ALERT CARD – Live lecture / test ongoing
// ─────────────────────────────────────────────────────────────────────────────
class _AlertCard extends ConsumerWidget {
  const _AlertCard({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(studentLectureAlertProvider).when(
      data: (lectureAlert) {
        if (lectureAlert != null) {
          return _LiveLectureAlert(data: lectureAlert, isDark: isDark);
        }
        return _EmptyAlertCard(isDark: isDark);
      },
      loading: () => _EmptyAlertCard(isDark: isDark),
      error: (err, _) => _EmptyAlertCard(isDark: isDark),
    );
  }
}

class _LiveLectureAlert extends StatelessWidget {
  const _LiveLectureAlert({required this.data, required this.isDark});
  final Map<String, String> data;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'live';
    final isStartingSoon = status == 'starting_soon';
    final accentColor = isStartingSoon ? const Color(0xFFF59E0B) : AppColors.error;
    final backgroundColor = isDark 
        ? (isStartingSoon ? const Color(0xFF2C221A) : const Color(0xFF2C1A1A)) 
        : (isStartingSoon ? const Color(0xFFFFFBEB) : const Color(0xFFFFF1F1));

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.30 : 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge row
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Row(
                  children: [
                    if (!isStartingSoon) ...[
                      const _PulseDot(),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      isStartingSoon ? 'STARTING SOON' : 'LIVE NOW',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isStartingSoon ? AppColors.primary : AppColors.error,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  isStartingSoon ? 'Prepare' : 'Join Now',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Subject + topic
          Text(
            data['subject'] ?? '',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.ink,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data['topic'] ?? '',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          // Info chips
          Row(
            children: [
              _SmInfoChip(
                icon: Icons.person_outline_rounded,
                label: data['teacher'] ?? '',
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _SmInfoChip(
                icon: Icons.meeting_room_outlined,
                label: data['classroom'] ?? '',
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _SmInfoChip(
            icon: Icons.access_time_rounded,
            label: '${data['startTime']} – ${data['endTime']}',
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _EmptyAlertCard extends StatelessWidget {
  const _EmptyAlertCard({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceTile1 : AppColors.canvas,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.hairline, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.notifications_active_outlined,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No Live Lecture Right Now',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.ink,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'You\'re all caught up! Next class details below.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? Colors.white38
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UPCOMING TEST CARD
// ─────────────────────────────────────────────────────────────────────────────
class _UpcomingTestCard extends StatelessWidget {
  const _UpcomingTestCard({required this.isDark});
  final bool isDark;

  static const Color _accent = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    final hasTest = _upcomingTest != null;
    final data = _upcomingTest;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceTile1 : AppColors.canvas,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.hairline, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.assignment_rounded,
                    color: _accent, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upcoming Test',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white38
                            : AppColors.textSecondary,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Text(
                      hasTest
                          ? '${data!['subject']} – ${data['topic']}'
                          : 'No test scheduled',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.ink,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (hasTest)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    data!['date'] ?? '',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _accent,
                    ),
                  ),
                ),
            ],
          ),
          if (hasTest) ...[
            const SizedBox(height: 14),
            Divider(
                color: isDark ? Colors.white10 : const Color(0xFFF0F0F0),
                height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SmInfoChip(
                      icon: Icons.access_time_rounded,
                      label: '${data!['time']} • ${data['duration']}',
                      isDark: isDark),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SmInfoChip(
                      icon: Icons.emoji_events_outlined,
                      label: '${data['marks']} Marks',
                      isDark: isDark),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UPCOMING LECTURE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _UpcomingLectureCard extends StatelessWidget {
  const _UpcomingLectureCard({
    required this.isDark,
    required this.upcomingLecture,
  });
  final bool isDark;
  final Map<String, String>? upcomingLecture;

  @override
  Widget build(BuildContext context) {
    final hasLecture = upcomingLecture != null;
    final data = upcomingLecture;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceTile1 : AppColors.canvas,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.hairline, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_today_rounded,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upcoming Lecture',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white38
                            : AppColors.textSecondary,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Text(
                      hasLecture
                          ? '${data!['subject']}'
                          : 'No upcoming lecture',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.ink,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasLecture && data!['countdownLabel'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    data['countdownLabel']!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          if (hasLecture) ...[
            const SizedBox(height: 10),
            // Topic pill
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : AppColors.canvasParchment,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.menu_book_rounded,
                      size: 13,
                      color: isDark
                          ? Colors.white38
                          : AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      data!['topic'] ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : AppColors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Divider(
                color: isDark ? Colors.white10 : const Color(0xFFF0F0F0),
                height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SmInfoChip(
                      icon: Icons.person_outline_rounded,
                      label: data['teacher'] ?? '',
                      isDark: isDark),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SmInfoChip(
                      icon: Icons.meeting_room_outlined,
                      label: data['classroom'] ?? '',
                      isDark: isDark),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _SmInfoChip(
                    icon: Icons.calendar_today_outlined,
                    label: data['date'] ?? '',
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SmInfoChip(
                    icon: Icons.access_time_rounded,
                    label: '${data['startTime']} – ${data['endTime']}',
                    isDark: isDark,
                  ),
                ),
              ],
            ),

          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NOTICES / HOMEWORK CARD
// ─────────────────────────────────────────────────────────────────────────────
class _NoticesCard extends StatelessWidget {
  const _NoticesCard({required this.isDark});
  final bool isDark;

  IconData _iconForType(String type) {
    switch (type) {
      case 'homework':
        return Icons.edit_note_rounded;
      case 'class':
        return Icons.school_rounded;
      default:
        return Icons.campaign_outlined;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'homework':
        return const Color(0xFFF59E0B);
      case 'class':
        return AppColors.primary;
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceTile1 : AppColors.canvas,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.hairline, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.campaign_outlined,
                    color: Color(0xFF8B5CF6), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Homework & Notices',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.ink,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Notice items
          ..._notices.asMap().entries.map((entry) {
            final i = entry.key;
            final notice = entry.value;
            final accent = _colorForType(notice['type']!);
            return Column(
              children: [
                if (i > 0)
                  Divider(
                      color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : const Color(0xFFF0F0F0),
                      height: 20),
                _NoticeItem(
                  icon: _iconForType(notice['type']!),
                  accentColor: accent,
                  title: notice['title']!,
                  subtitle: notice['subtitle']!,
                  isDark: isDark,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _NoticeItem extends StatelessWidget {
  const _NoticeItem({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: accentColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.ink,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color:
                      isDark ? Colors.white38 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED SMALL WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

/// Animated pulsing red dot for LIVE badge
class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.error,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Compact info chip: icon + text in a pill
class _SmInfoChip extends StatelessWidget {
  const _SmInfoChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppColors.canvasParchment,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 13,
              color: isDark ? Colors.white38 : AppColors.textSecondary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : AppColors.ink,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
