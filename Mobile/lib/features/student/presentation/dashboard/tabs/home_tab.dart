import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:national_academy/core/constants/app_colors.dart';
import 'package:national_academy/core/services/supabase_providers.dart';
import 'package:national_academy/core/widgets/app_pull_to_refresh.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mock data – replace with real providers when available
// ─────────────────────────────────────────────────────────────────────────────
const _studentName = 'Yash';
const _batchName = 'Alpha JEE Pro';
const _batchClass = '12th • JEE';

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
          // ── Scrollable Content (Direct Surface Layout with Pull-to-Refresh) ──
          Positioned.fill(
            child: AppPullToRefresh(
              topPadding: paddingTop + 100.0,
              onRefresh: () async {
                ref.invalidate(studentUpcomingTestProvider);
                ref.invalidate(studentExamsListProvider);
                ref.invalidate(studentUpcomingLectureProvider);
                ref.invalidate(studentUpcomingLecturesProvider);
                ref.invalidate(studentLiveLectureProvider);
                ref.invalidate(studentLectureAlertProvider);
                ref.invalidate(studentBatchAssignedProvider);
                ref.invalidate(studentBatchIdsProvider);
                ref.invalidate(studentIdProvider);
                await Future.delayed(const Duration(milliseconds: 700));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.only(
                  left: 20.0,
                  right: 20.0,
                  top: paddingTop + 104.0,
                  bottom: 120.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. LIVE / STARTING SOON ALERT (Clean inline bar if active)
                    _AlertSection(isDark: isDark),
                    const SizedBox(height: 24),

                    // 2. UPCOMING TEST (Direct display - no card box)
                    _UpcomingTestSection(isDark: isDark),
                    const SizedBox(height: 32),

                    // 3. UPCOMING LECTURES (Direct schedule list - no card boxes)
                    ref.watch(studentUpcomingLecturesProvider).when(
                      data: (lectures) => _UpcomingLecturesSection(
                        isDark: isDark,
                        lectures: lectures,
                      ),
                      loading: () => _UpcomingLecturesSection(
                        isDark: isDark,
                        lectures: const [],
                      ),
                      error: (_, __) => _UpcomingLecturesSection(
                        isDark: isDark,
                        lectures: const [],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 4. HOMEWORK / NOTICES (Direct list - no card boxes)
                    _NoticesSection(isDark: isDark),
                  ],
                ),
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
                    top: paddingTop + 12,
                    bottom: 16,
                    left: 20,
                    right: 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.scaffoldBackgroundColor.withValues(alpha: 0.96),
                        theme.scaffoldBackgroundColor.withValues(alpha: 0.75),
                        theme.scaffoldBackgroundColor.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.6, 1.0],
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
class _GreetingHeader extends ConsumerWidget {
  const _GreetingHeader({required this.isDark});
  final bool isDark;

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.ink;
    final mutedColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    final batchAsync = ref.watch(studentEnrolledBatchProvider);
    final profileNameAsync = ref.watch(studentProfileNameProvider);

    final name = profileNameAsync.asData?.value;
    final displayName = (name != null && name.trim().isNotEmpty) ? name : _studentName;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_greeting()} 👋',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: mutedColor,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                displayName,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: -0.6,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              batchAsync.when(
                data: (batch) {
                  if (batch == null || batch.name.isEmpty) {
                    return Text(
                      'No Active Batch Assigned',
                      style: TextStyle(
                        fontSize: 13,
                        color: mutedColor,
                        letterSpacing: -0.1,
                      ),
                    );
                  }
                  final subTitle = batch.formattedClassAndExam.isNotEmpty
                      ? '${batch.name} • ${batch.formattedClassAndExam}'
                      : batch.name;
                  return Text(
                    subTitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: mutedColor,
                      letterSpacing: -0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );
                },
                loading: () => Text(
                  'Loading batch info…',
                  style: TextStyle(
                    fontSize: 13,
                    color: mutedColor,
                    letterSpacing: -0.1,
                  ),
                ),
                error: (_, __) => Text(
                  '$_batchName • $_batchClass',
                  style: TextStyle(
                    fontSize: 13,
                    color: mutedColor,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Notification bell button
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
// 1. ALERT SECTION – Live / Starting Soon (Direct Banner)
// ─────────────────────────────────────────────────────────────────────────────
class _AlertSection extends ConsumerWidget {
  const _AlertSection({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(studentLectureAlertProvider).when(
      data: (lectureAlert) {
        if (lectureAlert != null) {
          return _LiveBanner(data: lectureAlert, isDark: isDark);
        }
        return const SizedBox.shrink(); // Hide empty alert box to keep feed clean
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _LiveBanner extends StatelessWidget {
  const _LiveBanner({required this.data, required this.isDark});
  final Map<String, String> data;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'live';
    final isStartingSoon = status == 'starting_soon';
    final accentColor = isStartingSoon ? const Color(0xFFF59E0B) : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Row(
            children: [
              if (!isStartingSoon) ...[
                const _PulseDot(),
                const SizedBox(width: 8),
              ],
              Text(
                isStartingSoon ? 'STARTING SOON' : 'LIVE NOW',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data['subject'] ?? 'Live Class',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (data['topic'] != null)
                  Text(
                    data['topic']!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              isStartingSoon ? 'Prepare' : 'Join',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
// 2. UPCOMING TEST SECTION (Fetches real test schedule for student's batch)
// ─────────────────────────────────────────────────────────────────────────────
class _UpcomingTestSection extends ConsumerWidget {
  const _UpcomingTestSection({required this.isDark});
  final bool isDark;

  static const Color _accent = Color(0xFF10B981);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testAsync = ref.watch(studentUpcomingTestProvider);

    final textColor = isDark ? Colors.white : AppColors.ink;
    final mutedColor = isDark ? Colors.white54 : AppColors.textSecondary;

    return testAsync.when(
      data: (testData) {
        final hasTest = testData != null;
        final isCancelled = testData?['isCancelled'] == 'true';
        final daysLeft = int.tryParse(testData?['daysLeft'] ?? '1') ?? 1;
        final headerColor = isCancelled ? AppColors.error : _accent;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header Eyebrow
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: headerColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isCancelled ? 'TEST CANCELLED' : 'UPCOMING TEST',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: headerColor,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (hasTest) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Details Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${testData['subject']} – ${testData['topic']}',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                            letterSpacing: -0.3,
                            decoration: isCancelled ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            _DirectMetaTag(
                              icon: Icons.access_time_rounded,
                              label: '${testData['time']} (${testData['duration']})',
                              isDark: isDark,
                            ),
                            _DirectMetaTag(
                              icon: Icons.emoji_events_outlined,
                              label: '${testData['marks']} Marks',
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  if (isCancelled)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'Test Cancelled',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    _CircularCountdownRing(
                      daysLeft: daysLeft,
                      totalDays: 7,
                      accentColor: _accent,
                      isDark: isDark,
                    ),
                ],
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.assignment_outlined, size: 18, color: mutedColor),
                    const SizedBox(width: 8),
                    Text(
                      'No upcoming test scheduled for your batch',
                      style: TextStyle(
                        fontSize: 13,
                        color: mutedColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            Divider(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08), height: 1),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Sleek Circular Timer widget displaying days remaining for test
class _CircularCountdownRing extends StatelessWidget {
  const _CircularCountdownRing({
    required this.daysLeft,
    required this.totalDays,
    required this.accentColor,
    required this.isDark,
  });

  final int daysLeft;
  final int totalDays;
  final Color accentColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final progress = totalDays > 0 ? (daysLeft / totalDays).clamp(0.05, 1.0) : 1.0;

    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: isDark ? 0.08 : 0.04),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 76,
            height: 76,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 5.0,
              strokeCap: StrokeCap.round,
              backgroundColor: accentColor.withValues(alpha: isDark ? 0.15 : 0.12),
              color: accentColor,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$daysLeft',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.ink,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                daysLeft == 1 ? 'DAY LEFT' : 'DAYS LEFT',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. UPCOMING LECTURES SECTION (Direct timeline layout - no card box)
// ─────────────────────────────────────────────────────────────────────────────
class _UpcomingLecturesSection extends StatelessWidget {
  const _UpcomingLecturesSection({
    required this.isDark,
    required this.lectures,
  });

  final bool isDark;
  final List<Map<String, String>> lectures;

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark ? Colors.white54 : AppColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Eyebrow
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'TODAY\'S LECTURES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: 1.0,
              ),
            ),
            const Spacer(),
            Text(
              '${lectures.length} Classes',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: mutedColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (lectures.isEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(Icons.event_available_rounded, size: 20, color: mutedColor),
                const SizedBox(width: 10),
                Text(
                  'No lectures scheduled for today',
                  style: TextStyle(fontSize: 14, color: mutedColor),
                ),
              ],
            ),
          ),
        ] else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: lectures.length,
            separatorBuilder: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(
                color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                height: 1,
              ),
            ),
            itemBuilder: (context, index) {
              final lecture = lectures[index];
              return _DirectLectureRow(
                lecture: lecture,
                isDark: isDark,
              );
            },
          ),
        ],

        const SizedBox(height: 16),
        Divider(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08), height: 1),
      ],
    );
  }
}

class _DirectLectureRow extends StatelessWidget {
  const _DirectLectureRow({required this.lecture, required this.isDark});
  final Map<String, String> lecture;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppColors.ink;
    final mutedColor = isDark ? Colors.white54 : AppColors.textSecondary;
    final isCancelled = lecture['isCancelled'] == 'true';
    final countdown = isCancelled ? 'CANCELLED' : lecture['countdownLabel'];
    final accentColor = isCancelled ? AppColors.error : AppColors.primary;

    final mainRow = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time Column
        SizedBox(
          width: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lecture['startTime'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              Text(
                lecture['endTime'] ?? '',
                style: TextStyle(
                  fontSize: 12,
                  color: mutedColor,
                ),
              ),
            ],
          ),
        ),

        // Vertical Accent Indicator
        Container(
          width: 3,
          height: 48,
          margin: const EdgeInsets.only(right: 14, top: 2),
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Details Column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lecture['subject'] ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        letterSpacing: -0.2,
                        decoration: isCancelled ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  if (countdown != null && !isCancelled)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        countdown,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                    ),
                ],
              ),
              if (lecture['topic'] != null && lecture['topic']!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  lecture['topic']!,
                  style: TextStyle(
                    fontSize: 13,
                    color: mutedColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: [
                  if (lecture['teacher'] != null)
                    _DirectMetaTag(
                      icon: Icons.person_outline_rounded,
                      label: lecture['teacher']!,
                      isDark: isDark,
                    ),
                  if (lecture['classroom'] != null)
                    _DirectMetaTag(
                      icon: Icons.meeting_room_outlined,
                      label: lecture['classroom']!,
                      isDark: isDark,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    if (!isCancelled) {
      return mainRow;
    }

    // Cancelled Lecture with 40% Yellow Warning Sticker Overlay
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Opacity(
          opacity: 0.55,
          child: mainRow,
        ),
        Positioned.fill(
          child: Align(
            alignment: Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.40, // Covers 40% of the lecture card space
              heightFactor: 0.85,
              child: Transform.rotate(
                angle: -0.03, // Organic sticker angle
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B), // Vibrant Amber Yellow Warning Sticker
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFD97706),
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x59F59E0B),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: Color(0xFF451A03),
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'CANCELLED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF451A03),
                            letterSpacing: 0.6,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. NOTICES SECTION (Direct list - no card box)
// ─────────────────────────────────────────────────────────────────────────────
class _NoticesSection extends StatelessWidget {
  const _NoticesSection({required this.isDark});
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
    final textColor = isDark ? Colors.white : AppColors.ink;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Eyebrow
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF8B5CF6),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'HOMEWORK & NOTICES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF8B5CF6),
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Notice items list (Direct display)
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _notices.length,
          separatorBuilder: (_, __) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(
              color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
              height: 1,
            ),
          ),
          itemBuilder: (context, i) {
            final notice = _notices[i];
            final accent = _colorForType(notice['type']!);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_iconForType(notice['type']!), size: 18, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notice['title']!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        notice['subtitle']!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED DIRECT UI HELPERS
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

/// Compact inline metadata tag (icon + label directly on screen)
class _DirectMetaTag extends StatelessWidget {
  const _DirectMetaTag({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: isDark ? Colors.white54 : AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white70 : AppColors.ink,
          ),
        ),
      ],
    );
  }
}
