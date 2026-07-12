import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:national_academy/core/constants/app_colors.dart';
import 'package:national_academy/features/batches/presentation/controllers/batch_detail_controller.dart';
import 'package:national_academy/features/batches/data/models/timetable_lecture_model.dart';

class TimetableTabView extends ConsumerStatefulWidget {
  final String batchId;

  const TimetableTabView({
    super.key,
    required this.batchId,
  });

  @override
  ConsumerState<TimetableTabView> createState() => _TimetableTabViewState();
}

class _TimetableTabViewState extends ConsumerState<TimetableTabView> with SingleTickerProviderStateMixin {
  late TabController _dayTabController;
  final List<String> _days = const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  void initState() {
    super.initState();
    _dayTabController = TabController(length: _days.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final detailState = ref.watch(batchDetailControllerProvider(widget.batchId));
    final controller = ref.read(batchDetailControllerProvider(widget.batchId).notifier);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          backgroundColor: Colors.transparent,
          title: TabBar(
            controller: _dayTabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            tabs: _days.map((day) => Tab(text: day.substring(0, 3))).toList(),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: theme.colorScheme.primary,
        onPressed: () => _showAddLectureDialog(context, controller, detailState),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: TabBarView(
        controller: _dayTabController,
        children: _days.map((day) {
          final lectures = detailState.lectures.where((l) => l.dayOfWeek.toLowerCase() == day.toLowerCase()).toList();

          if (lectures.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_rounded, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('No lectures scheduled for this day.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lectures.length,
            itemBuilder: (context, index) {
              final lecture = lectures[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Time indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          lecture.startTime.substring(0, 5),
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Lecture details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lecture.subjectName,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Teacher: ${lecture.teacherName} • Room: ${lecture.room}',
                              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                        onPressed: () => _deleteLecture(controller, lecture.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  void _showAddLectureDialog(
    BuildContext context,
    BatchDetailController controller,
    BatchDetailState detailState,
  ) {
    final subController = TextEditingController();
    final roomController = TextEditingController(text: 'Room 101');
    String selectedDay = _days[_dayTabController.index];
    String? selectedTeacherName = detailState.teachers.isNotEmpty ? detailState.teachers.first['full_name'] as String : null;
    TimeOfDay? start;
    TimeOfDay? end;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Scheduled Lecture'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedTeacherName,
                  decoration: const InputDecoration(labelText: 'Faculty'),
                  items: detailState.teachers.map((t) {
                    final name = t['full_name'] as String;
                    return DropdownMenuItem(value: name, child: Text(name));
                  }).toList(),
                  onChanged: (val) => setState(() => selectedTeacherName = val),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: subController,
                  decoration: const InputDecoration(labelText: 'Subject (e.g. Physics)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: roomController,
                  decoration: const InputDecoration(labelText: 'Room'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedDay,
                  decoration: const InputDecoration(labelText: 'Day'),
                  items: _days.map((d) {
                    return DropdownMenuItem(value: d, child: Text(d));
                  }).toList(),
                  onChanged: (val) => setState(() => selectedDay = val!),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        child: Text(start == null ? 'Start Time' : start!.format(context)),
                        onPressed: () async {
                          final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                          if (t != null) setState(() => start = t);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        child: Text(end == null ? 'End Time' : end!.format(context)),
                        onPressed: () async {
                          final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                          if (t != null) setState(() => end = t);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(ctx),
            ),
            ElevatedButton(
              child: const Text('Add'),
              onPressed: () async {
                if (subController.text.trim().isEmpty || start == null || end == null || selectedTeacherName == null) {
                  return;
                }
                Navigator.pop(ctx);
                try {
                  final startHour = start!.hour.toString().padLeft(2, '0');
                  final startMin = start!.minute.toString().padLeft(2, '0');
                  final endHour = end!.hour.toString().padLeft(2, '0');
                  final endMin = end!.minute.toString().padLeft(2, '0');

                  await controller.addLecture(
                    subjectName: subController.text.trim(),
                    teacherName: selectedTeacherName!,
                    room: roomController.text.trim(),
                    dayOfWeek: selectedDay,
                    startTime: '$startHour:$startMin:00',
                    endTime: '$endHour:$endMin:00',
                  );
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
      ),
    );
  }

  Future<void> _deleteLecture(BatchDetailController controller, String lectureId) async {
    try {
      await controller.deleteLecture(lectureId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting lecture: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _dayTabController.dispose();
    super.dispose();
  }
}
