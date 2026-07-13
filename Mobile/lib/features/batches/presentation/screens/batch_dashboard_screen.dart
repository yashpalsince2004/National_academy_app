import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:national_academy/features/batches/presentation/controllers/batch_controller.dart';
import 'package:national_academy/features/batches/presentation/widgets/batch_card.dart';
import 'package:national_academy/features/batches/presentation/widgets/create_batch_dialog.dart';
import 'package:national_academy/features/batches/presentation/widgets/rename_batch_dialog.dart';
import 'package:national_academy/core/widgets/app_dropdown.dart';
import 'package:national_academy/features/batches/data/models/batch_model.dart';

class BatchDashboardScreen extends ConsumerStatefulWidget {
  const BatchDashboardScreen({super.key});

  @override
  ConsumerState<BatchDashboardScreen> createState() => _BatchDashboardScreenState();
}

class _BatchDashboardScreenState extends ConsumerState<BatchDashboardScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';
  String _selectedSort = 'Newest';

  final List<String> _filters = const [
    'All',
    'JEE',
    'NEET',
    'Foundation',
    'NDA',
    'Boards',
    'Completed'
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final batchesState = ref.watch(batchControllerProvider);

    final scaffoldBgColor = isDark ? const Color(0xFF151516) : const Color(0xFFF5F5F7);
    final cardBgColor = isDark ? const Color(0xFF222224) : Colors.white;
    final hairlineColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        title: Text(
          'Batch Management',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        elevation: 0,
        backgroundColor: scaffoldBgColor,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateBatchSheet(context),
        icon: const Icon(Icons.add, color: Colors.white, size: 20),
        label: const Text(
          'Create Batch',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        backgroundColor: const Color(0xFF0066CC), // Apple Action Blue
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF0066CC),
        onRefresh: () => ref.read(batchControllerProvider.notifier).loadBatches(),
        child: batchesState.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0066CC))),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text(
                    'Error: $err',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066CC),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                    ),
                    onPressed: () => ref.read(batchControllerProvider.notifier).loadBatches(),
                    child: const Text('Retry', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
          data: (batches) {
            // Apply filtering
            var filtered = batches.where((b) {
              final nameMatch = b.name.toLowerCase().contains(_searchQuery.toLowerCase());
              if (!nameMatch) return false;

              if (_selectedFilter == 'All') {
                return b.status != 'completed'; // default hides archived/completed from all
              }
              if (_selectedFilter == 'Completed') {
                return b.status == 'completed';
              }
              return b.examType.toLowerCase() == _selectedFilter.toLowerCase() && b.status != 'completed';
            }).toList();

            // Apply sorting
            if (_selectedSort == 'Newest') {
              filtered.sort((a, b) => (b.startDate ?? DateTime.now()).compareTo(a.startDate ?? DateTime.now()));
            } else if (_selectedSort == 'Oldest') {
              filtered.sort((a, b) => (a.startDate ?? DateTime.now()).compareTo(b.startDate ?? DateTime.now()));
            } else if (_selectedSort == 'Highest Students') {
              filtered.sort((a, b) => b.studentCount.compareTo(a.studentCount));
            } else if (_selectedSort == 'Alphabetical') {
              filtered.sort((a, b) => a.name.compareTo(b.name));
            }

            // Calculate stats
            final total = batches.length;
            final active = batches.where((b) => b.status == 'active').length;
            final totalStudents = batches.fold<int>(0, (sum, b) => sum + b.studentCount);

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              children: [
                // Subtitle
                Text(
                  'Manage all academy batches, student enrollments & classrooms.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF68686E),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 20),

                // Stats Grid
                _buildStatsGrid(
                  context,
                  total: total,
                  active: active,
                  students: totalStudents,
                  cardBgColor: cardBgColor,
                  hairlineColor: hairlineColor,
                ),
                const SizedBox(height: 28),

                // Search & Filter Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: hairlineColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Bar & Sort Row
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE8E8ED),
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: TextField(
                                style: const TextStyle(fontSize: 15),
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF8E8E93)),
                                  hintText: 'Search batch...',
                                  hintStyle: const TextStyle(color: Color(0xFF8E8E93)),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                onChanged: (val) => setState(() => _searchQuery = val),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          AppDropdown<String>(
                            value: _selectedSort,
                            isFullWidthButton: false,
                            headerText: 'Sort by',
                            items: [
                              AppDropdownItem(value: 'Newest', label: 'Newest'),
                              AppDropdownItem(value: 'Oldest', label: 'Oldest'),
                              AppDropdownItem(value: 'Highest Students', label: 'Highest Students'),
                              AppDropdownItem(value: 'Alphabetical', label: 'A-Z'),
                            ],
                            onChanged: (val) {
                              setState(() => _selectedSort = val);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Filter Chips
                      SizedBox(
                        height: 34,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _filters.length,
                          itemBuilder: (context, index) {
                            final filter = _filters[index];
                            final isSelected = _selectedFilter == filter;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedFilter = filter),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF0066CC)
                                        : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F7)),
                                    borderRadius: BorderRadius.circular(9999),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF0066CC)
                                          : hairlineColor,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      filter,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF1D1D1F)),
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Batches List
                if (filtered.isEmpty)
                  _buildEmptyState(context)
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final batch = filtered[index];
                      return BatchCard(
                        batch: batch,
                        onDelete: () => _confirmDelete(context, batch),
                        onEdit: () => _showEditNameSheet(context, batch),
                      );
                    },
                  ),
                const SizedBox(height: 80), // extra scrolling room for FAB
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsGrid(
    BuildContext context, {
    required int total,
    required int active,
    required int students,
    required Color cardBgColor,
    required Color hairlineColor,
  }) {
    return Column(
      children: [
        // Top Card: Total Batches (Full width)
        _buildStatCard(
          context,
          'Total Batches',
          '$total',
          const Color(0xFF0066CC),
          Icons.grid_view_rounded,
          cardBgColor,
          hairlineColor,
          isFullWidth: true,
        ),
        const SizedBox(height: 12),
        // Bottom Row: Active Batches & Assigned Students
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Active Batches',
                '$active',
                Colors.green,
                Icons.check_circle_outline_rounded,
                cardBgColor,
                hairlineColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                'Assigned Students',
                '$students',
                Colors.orange,
                Icons.people_outline_rounded,
                cardBgColor,
                hairlineColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
    Color cardBgColor,
    Color hairlineColor, {
    bool isFullWidth = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      height: isFullWidth ? 90 : 85,
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: hairlineColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF68686E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              fontSize: isFullWidth ? 26 : 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.layers_clear_outlined, size: 54, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No Batches Found',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add a new batch or try changing the search/filter criteria.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateBatchSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateBatchDialog(),
    );
  }

  void _showEditNameSheet(BuildContext context, BatchModel batch) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: RenameBatchDialog(batch: batch),
      ),
    );
  }

  void _confirmDelete(BuildContext context, BatchModel batch) {
    if (batch.studentCount > 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Deletion Prevented'),
          content: const Text('Cannot delete a batch while students are still assigned to it. Please remove all students first.'),
          actions: [
            TextButton(
              child: const Text('Okay'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Batch'),
        content: Text('Are you sure you want to permanently delete "${batch.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(batchControllerProvider.notifier).deleteBatch(batch.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Batch deleted successfully.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
