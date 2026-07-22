import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../features/batches/presentation/controllers/batch_controller.dart';
import '../../../../features/batches/data/models/batch_model.dart';

class AttendanceRecordScreen extends ConsumerStatefulWidget {
  final String defaultBatch;
  const AttendanceRecordScreen({super.key, required this.defaultBatch});

  @override
  ConsumerState<AttendanceRecordScreen> createState() => _AttendanceRecordScreenState();
}

class _AttendanceRecordScreenState extends ConsumerState<AttendanceRecordScreen> {
  late String? _selectedBatch;
  String _selectedSubject = 'All Subjects';
  String _searchQuery = '';

  // Mock Attendance records with subject support
  final Map<String, List<Map<String, dynamic>>> _attendanceData = {
    'Veera': [
      {'name': 'Diya Sharma', 'roll': 'V01', 'present': 28, 'total': 30, 'rate': 0.933, 'subject': 'Physics'},
      {'name': 'Aarav Mehta', 'roll': 'V02', 'present': 29, 'total': 30, 'rate': 0.966, 'subject': 'Physics'},
      {'name': 'Rohan Gupta', 'roll': 'V03', 'present': 22, 'total': 30, 'rate': 0.733, 'subject': 'Physics'},
      {'name': 'Diya Sharma', 'roll': 'V01', 'present': 25, 'total': 28, 'rate': 0.892, 'subject': 'Chemistry'},
      {'name': 'Aarav Mehta', 'roll': 'V02', 'present': 26, 'total': 28, 'rate': 0.928, 'subject': 'Chemistry'},
      {'name': 'Rohan Gupta', 'roll': 'V03', 'present': 18, 'total': 28, 'rate': 0.642, 'subject': 'Chemistry'},
      {'name': 'Diya Sharma', 'roll': 'V01', 'present': 32, 'total': 32, 'rate': 1.0, 'subject': 'Maths'},
      {'name': 'Aarav Mehta', 'roll': 'V02', 'present': 30, 'total': 32, 'rate': 0.937, 'subject': 'Maths'},
      {'name': 'Rohan Gupta', 'roll': 'V03', 'present': 24, 'total': 32, 'rate': 0.75, 'subject': 'Maths'},
    ],
    'Batch XII-A': [
      {'name': 'Diya Sharma', 'roll': '12A01', 'present': 26, 'total': 26, 'rate': 1.0, 'subject': 'Physics'},
      {'name': 'Aarav Mehta', 'roll': '12A02', 'present': 24, 'total': 26, 'rate': 0.923, 'subject': 'Physics'},
      {'name': 'Ananya Roy', 'roll': '12A03', 'present': 25, 'total': 26, 'rate': 0.961, 'subject': 'Physics'},
      {'name': 'Rohan Gupta', 'roll': '12A04', 'present': 20, 'total': 26, 'rate': 0.769, 'subject': 'Physics'},
      {'name': 'Sanya Malhotra', 'roll': '12A05', 'present': 23, 'total': 26, 'rate': 0.884, 'subject': 'Physics'},
      {'name': 'Kabir Singh', 'roll': '12A06', 'present': 18, 'total': 26, 'rate': 0.692, 'subject': 'Physics'},
    ],
    'Batch XII-B': [
      {'name': 'Ishaan Verma', 'roll': '12B01', 'present': 22, 'total': 24, 'rate': 0.916, 'subject': 'Chemistry'},
      {'name': 'Meera Joshi', 'roll': '12B02', 'present': 24, 'total': 24, 'rate': 1.0, 'subject': 'Chemistry'},
      {'name': 'Aditya Rao', 'roll': '12B03', 'present': 19, 'total': 24, 'rate': 0.791, 'subject': 'Chemistry'},
      {'name': 'Rhea Kapoor', 'roll': '12B04', 'present': 23, 'total': 24, 'rate': 0.958, 'subject': 'Chemistry'},
    ],
    'Batch XI-A': [
      {'name': 'Arjun Sen', 'roll': '11A01', 'present': 18, 'total': 20, 'rate': 0.90, 'subject': 'Maths'},
      {'name': 'Sneha Reddy', 'roll': '11A02', 'present': 20, 'total': 20, 'rate': 1.0, 'subject': 'Maths'},
      {'name': 'Varun Dhawan', 'roll': '11A03', 'present': 15, 'total': 20, 'rate': 0.75, 'subject': 'Maths'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _selectedBatch = widget.defaultBatch;
  }

  double _getOverallRate(List<Map<String, dynamic>> records) {
    if (records.isEmpty) return 0.0;
    int totalPresent = 0;
    int totalClasses = 0;
    for (var r in records) {
      totalPresent += r['present'] as int;
      totalClasses += r['total'] as int;
    }
    return totalPresent / totalClasses;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Fetch batches from controller
    final batchesState = ref.watch(batchControllerProvider);
    final batches = batchesState.valueOrNull ?? [];
    final batchNames = batches.map((b) => b.name).toList();

    // Ensure _selectedBatch is valid (if batches aren't empty)
    if (batchNames.isNotEmpty && (_selectedBatch == null || !batchNames.contains(_selectedBatch))) {
      _selectedBatch = batchNames.contains(widget.defaultBatch)
          ? widget.defaultBatch
          : batchNames.first;
    }

    final currentBatchObj = batches.firstWhere(
      (b) => b.name == _selectedBatch,
      orElse: () => BatchModel(
        id: '',
        courseId: '',
        name: '',
        capacity: 0,
        examType: '',
        classLevel: '',
        medium: '',
        lectureDays: const [],
        status: '',
      ),
    );
    final subjectsList = ['All Subjects', 'Physics', 'Chemistry', 'Maths', 'Biology'];
    if (currentBatchObj.examType.toUpperCase() == 'JEE') {
      subjectsList.remove('Biology');
    }
    if (!subjectsList.contains(_selectedSubject)) {
      _selectedSubject = subjectsList.first;
    }

    final rawRecords = _attendanceData[_selectedBatch] ?? [];

    // Apply subject filter & dynamic aggregation
    final List<Map<String, dynamic>> subjectFilteredRecords;
    if (_selectedSubject == 'All Subjects') {
      final Map<String, Map<String, dynamic>> grouped = {};
      for (var r in rawRecords) {
        final name = r['name'] as String;
        if (!grouped.containsKey(name)) {
          grouped[name] = {
            'name': name,
            'roll': r['roll'],
            'present': 0,
            'total': 0,
          };
        }
        grouped[name]!['present'] = (grouped[name]!['present'] as int) + (r['present'] as int);
        grouped[name]!['total'] = (grouped[name]!['total'] as int) + (r['total'] as int);
      }
      subjectFilteredRecords = grouped.values.map((item) {
        final present = item['present'] as int;
        final total = item['total'] as int;
        return {
          'name': item['name'],
          'roll': item['roll'],
          'present': present,
          'total': total,
          'rate': total > 0 ? present / total : 0.0,
        };
      }).toList();
    } else {
      subjectFilteredRecords = rawRecords.where((r) {
        final sub = r['subject'] as String?;
        return sub == null || sub.toLowerCase() == _selectedSubject.toLowerCase();
      }).toList();
    }

    final filteredRecords = subjectFilteredRecords.where((r) {
      return r['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r['roll'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final overallRate = _getOverallRate(filteredRecords);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121214) : const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Attendance Record',
          style: TextStyle(
            fontFamily: '.SF Pro Display',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.ink,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: PopupMenuButton<String>(
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.menu_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              iconSize: 40,
              padding: EdgeInsets.zero,
              tooltip: 'Navigation Menu',
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: (value) {
                final currentBatch = _selectedBatch ?? widget.defaultBatch;
                if (value == 'Home') {
                  context.go('/admin/dashboard');
                } else if (value == 'Previous Lectures') {
                  context.pushReplacement('/admin/previous-lectures?batch=$currentBatch');
                } else if (value == 'Previous Tests') {
                  context.pushReplacement('/admin/previous-tests?batch=$currentBatch');
                } else if (value == 'Attendance Record') {
                  // Already here
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'Home',
                  child: Row(
                    children: [
                      Icon(Icons.home_rounded, color: AppColors.ink, size: 18),
                      SizedBox(width: 8),
                      Text('Home'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'Previous Lectures',
                  child: Row(
                    children: [
                      Icon(Icons.video_library_rounded, color: AppColors.ink, size: 18),
                      SizedBox(width: 8),
                      Text('Previous Lectures'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'Previous Tests',
                  child: Row(
                    children: [
                      Icon(Icons.assignment_rounded, color: AppColors.ink, size: 18),
                      SizedBox(width: 8),
                      Text('Previous Tests'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'Attendance Record',
                  child: Row(
                    children: [
                      Icon(Icons.people_alt_rounded, color: AppColors.primary, size: 18),
                      SizedBox(width: 8),
                      Text('Attendance Record', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header Stats & Filter Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Batch Dropdown Selector
                      Expanded(
                        child: AppDropdown<String>(
                          value: _selectedBatch ?? (batchNames.isNotEmpty ? batchNames.first : ''),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          items: batchNames.map((b) => AppDropdownItem<String>(
                            value: b,
                            label: b,
                          )).toList(),
                          onChanged: (val) => setState(() => _selectedBatch = val),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Subject Dropdown Selector
                      Expanded(
                        child: AppDropdown<String>(
                          value: _selectedSubject,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          items: subjectsList
                              .map((s) => AppDropdownItem<String>(
                            value: s,
                            label: s,
                          )).toList(),
                          onChanged: (val) => setState(() {
                            _selectedSubject = val ?? subjectsList.first;
                          }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Overall Statistics Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.24),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedSubject == 'All Subjects'
                                  ? 'Overall Attendance (All Subjects)'
                                  : 'Overall Attendance ($_selectedSubject)',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${(overallRate * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.done_all_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Student Search Input
                  TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: TextStyle(color: isDark ? Colors.white : AppColors.ink),
                    decoration: InputDecoration(
                      hintText: 'Search by student name or roll...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: isDark ? BorderSide.none : const BorderSide(color: Color(0xFFE5E5EA)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: isDark ? BorderSide.none : const BorderSide(color: Color(0xFFE5E5EA)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Student list
            Expanded(
              child: filteredRecords.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_month_rounded, size: 64, color: Colors.grey.withOpacity(0.4)),
                          const SizedBox(height: 16),
                          Text(
                            'No student records found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white54 : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      physics: const BouncingScrollPhysics(),
                      itemCount: filteredRecords.length,
                      itemBuilder: (context, index) {
                        final record = filteredRecords[index];
                        final rate = record['rate'] as double;

                        // Choose status color depending on percentage threshold
                        Color statusColor = const Color(0xFF34C759); // Green (>85%)
                        if (rate < 0.80) {
                          statusColor = const Color(0xFFFF3B30); // Red (<80%)
                        } else if (rate < 0.90) {
                          statusColor = const Color(0xFFFFCC00); // Yellow (80-90%)
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE5E5EA),
                              width: 1,
                            ),
                          ),
                          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF5F5F7),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  record['roll'].substring(record['roll'].length - 2),
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : AppColors.ink,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              record['name'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark ? Colors.white : AppColors.ink,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Roll No: ${record['roll']} • Attended: ${record['present']} / ${record['total']}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${(rate * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: statusColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
