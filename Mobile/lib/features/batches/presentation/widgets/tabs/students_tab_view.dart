import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:national_academy/features/batches/data/models/batch_student_model.dart';
import 'package:national_academy/features/batches/presentation/controllers/batch_detail_controller.dart';
import '../add_students_sheet.dart';

class StudentsTabView extends ConsumerStatefulWidget {
  final String batchId;
  final String classLevel;
  final String examType;

  const StudentsTabView({
    super.key,
    required this.batchId,
    required this.classLevel,
    required this.examType,
  });

  @override
  ConsumerState<StudentsTabView> createState() => _StudentsTabViewState();
}

class _StudentsTabViewState extends ConsumerState<StudentsTabView> {
  String _searchQuery = '';
  final Set<String> _selectedStudentIds = {};
  bool _isSelectionMode = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detailState = ref.watch(batchDetailControllerProvider(widget.batchId));
    final controller = ref.read(batchDetailControllerProvider(widget.batchId).notifier);

    final filtered = detailState.students.where((s) {
      return s.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.rollNo.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        // Actions Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Assigned Students (${detailState.students.length})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isSelectionMode) ...[
                    IconButton(
                      icon: const Icon(Icons.delete_sweep_rounded, color: Colors.red),
                      tooltip: 'Bulk Remove',
                      onPressed: _selectedStudentIds.isEmpty
                          ? null
                          : () => _confirmBulkRemove(context, controller),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        setState(() {
                          _isSelectionMode = false;
                          _selectedStudentIds.clear();
                        });
                      },
                    ),
                  ] else ...[
                    TextButton.icon(
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                      label: const Text('Add Students'),
                      onPressed: () => _openAddStudentsSheet(context),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: 'Search assigned students...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),

        // List
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final student = filtered[index];
                    final isSelected = _selectedStudentIds.contains(student.id);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
                          child: Text(student.fullName[0].toUpperCase()),
                        ),
                        title: Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${student.rollNo} • Attendance: ${student.attendancePercentage.toStringAsFixed(0)}%'),
                        trailing: _isSelectionMode
                            ? Checkbox(
                                value: isSelected,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedStudentIds.add(student.id);
                                    } else {
                                      _selectedStudentIds.remove(student.id);
                                    }
                                  });
                                },
                              )
                            : IconButton(
                                icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.redAccent),
                                onPressed: () => _confirmRemoveSingle(context, controller, student),
                              ),
                        onLongPress: () {
                          setState(() {
                            _isSelectionMode = true;
                            _selectedStudentIds.add(student.id);
                          });
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('No Students Assigned', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Assign students to get started with batch management.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add Students', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary),
            onPressed: () => _openAddStudentsSheet(context),
          ),
        ],
      ),
    );
  }

  void _openAddStudentsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddStudentsSheet(
        batchId: widget.batchId,
        classLevel: widget.classLevel,
        examType: widget.examType,
      ),
    );
  }

  void _confirmRemoveSingle(BuildContext context, BatchDetailController controller, BatchStudentModel student) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Student'),
        content: Text('Remove student "${student.fullName}" from this batch?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await controller.removeStudents([student.id]);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('"${student.fullName}" removed successfully.')),
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

  void _confirmBulkRemove(BuildContext context, BatchDetailController controller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Selected Students'),
        content: Text('Remove ${_selectedStudentIds.length} selected students from this batch?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove All', style: TextStyle(color: Colors.white)),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await controller.removeStudents(_selectedStudentIds.toList());
                setState(() {
                  _isSelectionMode = false;
                  _selectedStudentIds.clear();
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Students removed successfully.')),
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
