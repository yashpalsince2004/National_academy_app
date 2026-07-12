import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:national_academy/core/constants/app_colors.dart';
import 'package:national_academy/core/services/supabase_providers.dart';


// ─────────────────────────────────────────────────────────────────────────────
// Student DPP Tab — shows DPPs published by admin for the student's batch
// ─────────────────────────────────────────────────────────────────────────────

class StudentDppTab extends ConsumerStatefulWidget {
  const StudentDppTab({super.key});

  @override
  ConsumerState<StudentDppTab> createState() => _StudentDppTabState();
}

class _StudentDppTabState extends ConsumerState<StudentDppTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final _filterLabels = ['All', 'Pending', 'Attempted'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filterLabels.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.ink;
    final mutedColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final cardColor = isDark ? AppColors.surfaceTile1 : AppColors.canvas;

    final feedAsync = ref.watch(studentDppFeedProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My DPPs',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Practice problems assigned to your batch',
                          style: TextStyle(fontSize: 13, color: mutedColor),
                        ),
                      ],
                    ),
                  ),
                  // Total count badge
                  feedAsync.maybeWhen(
                    data: (items) => _CountBadge(count: items.length),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Search Bar ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.hairline),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search by chapter or subject…',
                    hintStyle: TextStyle(color: mutedColor, fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded, color: mutedColor, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close_rounded, color: mutedColor, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ── Filter Tabs ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(30),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: mutedColor,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                padding: EdgeInsets.zero,
                tabs: _filterLabels.map((l) => Tab(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(l),
                  ),
                )).toList(),
              ),
            ),

            const SizedBox(height: 14),

            // ── Content ──────────────────────────────────────────────────────
            Expanded(
              child: feedAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _ErrorState(
                  message: 'Could not load DPPs.\n$e',
                  onRetry: () => ref.invalidate(studentDppFeedProvider),
                  mutedColor: mutedColor,
                ),
                data: (allItems) {
                  return TabBarView(
                    controller: _tabController,
                    children: _filterLabels.map((filter) {
                      final filtered = allItems.where((d) {
                        final matchFilter = filter == 'All' ||
                            (filter == 'Pending' && !d.isAttempted) ||
                            (filter == 'Attempted' && d.isAttempted);
                        final matchSearch = _searchQuery.isEmpty ||
                            d.chapterName.toLowerCase().contains(_searchQuery) ||
                            d.subjectName.toLowerCase().contains(_searchQuery) ||
                            d.title.toLowerCase().contains(_searchQuery);
                        return matchFilter && matchSearch;
                      }).toList();

                      return _DppList(
                        items: filtered,
                        filter: filter,
                        cardColor: cardColor,
                        textColor: textColor,
                        mutedColor: mutedColor,
                        onRetry: () => ref.invalidate(studentDppFeedProvider),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Count Badge
// ─────────────────────────────────────────────────────────────────────────────
class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, size: 15, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            '$count DPP${count == 1 ? '' : 's'}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error State
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final Color mutedColor;

  const _ErrorState({required this.message, required this.onRetry, required this.mutedColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 56, color: mutedColor.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: mutedColor),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DPP List
// ─────────────────────────────────────────────────────────────────────────────
class _DppList extends StatelessWidget {
  final List<StudentDppFeedItem> items;
  final String filter;
  final Color cardColor;
  final Color textColor;
  final Color mutedColor;
  final VoidCallback onRetry;

  const _DppList({
    required this.items,
    required this.filter,
    required this.cardColor,
    required this.textColor,
    required this.mutedColor,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, size: 56, color: mutedColor.withValues(alpha: 0.35)),
            const SizedBox(height: 12),
            Text(
              filter == 'All' ? 'No DPPs assigned yet' : 'No $filter DPPs',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: mutedColor),
            ),
            const SizedBox(height: 6),
            Text(
              'Your teacher will assign DPPs to your batch.',
              style: TextStyle(fontSize: 13, color: mutedColor.withValues(alpha: 0.6)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRetry(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _DppCard(
          item: items[index],
          cardColor: cardColor,
          textColor: textColor,
          mutedColor: mutedColor,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DPP Card
// ─────────────────────────────────────────────────────────────────────────────
class _DppCard extends StatelessWidget {
  final StudentDppFeedItem item;
  final Color cardColor;
  final Color textColor;
  final Color mutedColor;

  const _DppCard({
    required this.item,
    required this.cardColor,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    final diffColor = item.difficulty == 'High'
        ? AppColors.error
        : item.difficulty == 'Medium'
            ? Colors.orange
            : AppColors.success;

    final subjectColor = _subjectColor(item.subjectName);
    final now = DateTime.now();
    final isDue = item.dueAt != null && !item.isAttempted && item.dueAt!.isAfter(now);
    final isOverdue = item.dueAt != null && !item.isAttempted && item.dueAt!.isBefore(now);

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          if (item.isAttempted) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(item.title),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('You have already submitted this practice paper.'),
                    const SizedBox(height: 12),
                    Text('Questions: ${item.questionCount}'),
                    Text('Duration: ${item.timeMinutes} minutes'),
                    Text('Total Marks: ${item.totalMarks}'),
                    const Divider(height: 24),
                    Text(
                      'Your Result: ${item.scorePercent.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          } else {
            context.push('/student/dpp/attempt/${item.assignmentId}');
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isOverdue
                  ? AppColors.error.withValues(alpha: 0.30)
                  : AppColors.hairline,
            ),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Row 1: Subject + Exam + Difficulty ───────────────────────
              Row(
                children: [
                  _badge(item.subjectName, subjectColor),
                  const SizedBox(width: 8),
                  _badge(item.examType, AppColors.primary),
                  const Spacer(),
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: diffColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    item.difficulty,
                    style: TextStyle(fontSize: 12, color: diffColor, fontWeight: FontWeight.w600),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Title + Chapter ───────────────────────────────────────────
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  letterSpacing: -0.3,
                ),
              ),
              if (item.chapterName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Chapter: ${item.chapterName}',
                  style: TextStyle(fontSize: 13, color: mutedColor),
                ),
              ],

              const SizedBox(height: 14),

              // ── Progress bar (if attempted) ───────────────────────────────
              if (item.isAttempted) ...[
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: item.scorePercent / 100,
                          backgroundColor: AppColors.hairline,
                          color: item.scorePercent >= 70
                              ? AppColors.success
                              : item.scorePercent >= 40
                                  ? Colors.orange
                                  : AppColors.error,
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${item.scorePercent.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],

              // ── Meta + CTA ────────────────────────────────────────────────
              Row(
                children: [
                  _metaChip(Icons.help_outline_rounded, '${item.questionCount} Qs', mutedColor),
                  const SizedBox(width: 10),
                  _metaChip(Icons.timer_outlined, '${item.timeMinutes}m', mutedColor),
                  const SizedBox(width: 10),
                  _metaChip(Icons.star_outline_rounded, '${item.totalMarks} Marks', mutedColor),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: item.isAttempted
                          ? AppColors.success.withValues(alpha: 0.10)
                          : AppColors.primary,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      item.isAttempted ? 'Review' : 'Start',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: item.isAttempted ? AppColors.success : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              // ── Due date / Overdue warning ────────────────────────────────
              if (isDue || isOverdue) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      isOverdue ? Icons.warning_amber_rounded : Icons.access_time_rounded,
                      size: 13,
                      color: isOverdue ? AppColors.error : Colors.orange.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOverdue
                          ? 'Overdue: ${_formatDate(item.dueAt!)}'
                          : 'Due: ${_formatDate(item.dueAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isOverdue ? AppColors.error : Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
        ),
      );

  Widget _metaChip(IconData icon, String label, Color color) => Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
        ],
      );

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Color _subjectColor(String s) {
    switch (s.toLowerCase()) {
      case 'physics': return Colors.indigo;
      case 'chemistry': return Colors.teal;
      case 'biology': return Colors.green;
      case 'mathematics': return Colors.deepPurple;
      default: return AppColors.primary;
    }
  }
}
