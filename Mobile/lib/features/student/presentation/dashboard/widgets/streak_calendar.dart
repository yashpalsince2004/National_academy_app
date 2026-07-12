import 'package:flutter/material.dart';
import 'package:national_academy/core/constants/app_colors.dart';

class StreakCalendar extends StatefulWidget {
  final int streakCount;

  const StreakCalendar({
    super.key,
    required this.streakCount,
  });

  @override
  State<StreakCalendar> createState() => _StreakCalendarState();
}

class _StreakCalendarState extends State<StreakCalendar> {
  int _currentMonthIndex = 1; // 0 = June 2026, 1 = July 2026

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = isDark ? AppColors.surfaceTile1 : AppColors.canvas;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.ink;
    final mutedTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    final String currentMonthName = _currentMonthIndex == 0 ? 'June 2026' : 'July 2026';

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.hairline),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Calendar Header Row ───────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Streak Calendar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.local_fire_department_rounded, color: AppColors.primary, size: 22),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.streakCount} Days',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Month Shift Selector Row (iOS Chevron Style) ───────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                color: textColor,
                disabledColor: mutedTextColor.withValues(alpha: 0.3),
                onPressed: _currentMonthIndex > 0
                    ? () => setState(() => _currentMonthIndex = 0)
                    : null,
              ),
              Text(
                currentMonthName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: -0.2,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                color: textColor,
                disabledColor: mutedTextColor.withValues(alpha: 0.3),
                onPressed: _currentMonthIndex < 1
                    ? () => setState(() => _currentMonthIndex = 1)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Render Active Month Calendar ───────────────────────────────────
          if (_currentMonthIndex == 0)
            _buildMonthCalendar(
              textColor: textColor,
              mutedTextColor: mutedTextColor,
              startWeekday: 1, // June 1, 2026 starts on Monday
              daysInMonth: 30,
              absentDays: const {}, // June absent days
              streakRanges: const [
                _StreakRange(start: 16, end: 21),
              ],
              orangeDays: const {4, 7, 11, 25, 28},
            )
          else
            _buildMonthCalendar(
              textColor: textColor,
              mutedTextColor: mutedTextColor,
              startWeekday: 3, // July 1, 2026 starts on Wednesday
              daysInMonth: 31,
              absentDays: const {8}, // July 8 is the absent day
              streakRanges: const [
                _StreakRange(start: 9, end: 11),
              ],
              orangeDays: const {3, 12}, // Milestones
            ),
        ],
      ),
    );
  }

  Widget _buildMonthCalendar({
    required Color textColor,
    required Color mutedTextColor,
    required int startWeekday, // 0 = Sunday, 1 = Monday, etc.
    required int daysInMonth,
    required Set<int> absentDays,
    required List<_StreakRange> streakRanges,
    required Set<int> orangeDays,
  }) {
    final weekdays = ['Su', 'M', 'Tu', 'W', 'Th', 'F', 'Sa'];

    final List<int?> gridDays = [];
    for (int i = 0; i < startWeekday; i++) {
      gridDays.add(null);
    }
    for (int i = 1; i <= daysInMonth; i++) {
      gridDays.add(i);
    }
    while (gridDays.length % 7 != 0) {
      gridDays.add(null);
    }

    final int rowCount = gridDays.length ~/ 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Weekday Headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekdays.map((day) => Expanded(
            child: Center(
              child: Text(
                day,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: mutedTextColor,
                ),
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 8),

        // Calendar Rows
        Column(
          children: List.generate(rowCount, (rowIndex) {
            final start = rowIndex * 7;
            final end = start + 7;
            final weekDays = gridDays.sublist(start, end);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                children: List.generate(7, (colIndex) {
                  final day = weekDays[colIndex];
                  if (day == null) {
                    return const Expanded(child: SizedBox(height: 36));
                  }

                  // Determine background decoration style
                  bool inStreak = false;
                  bool isStart = false;
                  bool isEnd = false;

                  for (final range in streakRanges) {
                    if (day >= range.start && day <= range.end) {
                      inStreak = true;
                      isStart = (day == range.start) || (colIndex == 0);
                      isEnd = (day == range.end) || (colIndex == 6);
                      break;
                    }
                  }

                  final isAbsent = absentDays.contains(day);
                  final isOrange = orangeDays.contains(day);

                  Widget cellContent;
                  if (isAbsent) {
                    cellContent = Center(
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: AppColors.error, // Red for absent date
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$day',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  } else {
                    Color dayTextColor;
                    if (inStreak) {
                      dayTextColor = Colors.white;
                    } else if (isOrange) {
                      dayTextColor = Colors.orange.shade700;
                    } else {
                      dayTextColor = textColor.withValues(alpha: 0.85);
                    }

                    cellContent = Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: (inStreak || isOrange) ? FontWeight.bold : FontWeight.w500,
                          color: dayTextColor,
                        ),
                      ),
                    );
                  }

                  // Apply background container if inStreak (Blue for continuous streak)
                  return Expanded(
                    child: Container(
                      height: 32,
                      decoration: inStreak
                          ? BoxDecoration(
                              color: AppColors.primary, // Blue background for streak track
                              borderRadius: BorderRadius.horizontal(
                                left: isStart ? const Radius.circular(16) : Radius.zero,
                                right: isEnd ? const Radius.circular(16) : Radius.zero,
                              ),
                            )
                          : null,
                      child: cellContent,
                    ),
                  );
                }),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _StreakRange {
  final int start;
  final int end;

  const _StreakRange({required this.start, required this.end});
}
