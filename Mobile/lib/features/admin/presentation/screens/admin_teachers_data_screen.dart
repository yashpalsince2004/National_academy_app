import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:national_academy/core/constants/app_colors.dart';
import 'package:national_academy/core/services/supabase_providers.dart';
import 'package:national_academy/core/widgets/app_dropdown.dart';

class TeacherDirectoryModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String subject;

  TeacherDirectoryModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.subject,
  });

  factory TeacherDirectoryModel.fromMap(Map<String, dynamic> map) {
    return TeacherDirectoryModel(
      id: map['id'] as String? ?? '',
      name: map['full_name'] as String? ?? 'Unnamed',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? 'N/A',
      subject: map['subject'] as String? ?? 'Physics', // Fallback subject
    );
  }
}

class AdminTeachersDataScreen extends ConsumerStatefulWidget {
  const AdminTeachersDataScreen({super.key});

  @override
  ConsumerState<AdminTeachersDataScreen> createState() => _AdminTeachersDataScreenState();
}

class _AdminTeachersDataScreenState extends ConsumerState<AdminTeachersDataScreen> {
  final _searchController = TextEditingController();
  List<TeacherDirectoryModel> _allTeachers = [];
  bool _isLoading = true;
  bool _isRefreshingList = false;
  String _errorMessage = '';

  String _searchQuery = '';
  String _selectedSubject = 'All';

  final List<String> _subjectOptions = ['All', 'Physics', 'Chemistry', 'Mathematics', 'Biology', 'English', 'Other'];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData({bool isSilent = false}) async {
    setState(() {
      if (isSilent) {
        _isRefreshingList = true;
      } else {
        _isLoading = true;
      }
      _errorMessage = '';
    });

    try {
      final client = ref.read(supabaseClientProvider);
      
      // Fetch teachers from profiles table
      final teachersRes = await client.from('profiles').select().eq('role', 'teacher');
      final List teachersList = teachersRes as List? ?? [];

      if (mounted) {
        setState(() {
          _allTeachers = teachersList.map((e) {
            // Check if there is mock subject data, or default
            return TeacherDirectoryModel.fromMap(e);
          }).toList();
          _isLoading = false;
          _isRefreshingList = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load teachers: ${e.toString()}';
          _isLoading = false;
          _isRefreshingList = false;
        });
      }
    }
  }

  List<TeacherDirectoryModel> get _filteredTeachers {
    return _allTeachers.where((teacher) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch = teacher.name.toLowerCase().contains(query) ||
          teacher.email.toLowerCase().contains(query) ||
          teacher.phone.toLowerCase().contains(query);

      final teacherSubs = teacher.subject
          .split(',')
          .map((s) => s.trim().toLowerCase())
          .toList();
      final matchesSubject = _selectedSubject == 'All' ||
          teacherSubs.contains(_selectedSubject.toLowerCase());

      return matchesSearch && matchesSubject;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Directory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _fetchData(isSilent: true),
            tooltip: 'Refresh list',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter section
          _buildFilterSection(isDark),

          // Teachers List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => _fetchData(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredTeachers.isEmpty
                        ? Center(
                            child: Text(
                              'No teachers found matching criteria',
                              style: TextStyle(
                                color: isDark ? Colors.white60 : AppColors.textSecondary,
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _fetchData(isSilent: true),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _filteredTeachers.length,
                              itemBuilder: (context, index) {
                                final teacher = _filteredTeachers[index];
                                return _buildTeacherCard(teacher, isDark);
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/admin/register-teacher');
          _fetchData(isSilent: true);
        },
        tooltip: 'Add Teacher',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceTile1 : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white10 : AppColors.hairline,
          ),
        ),
      ),
      child: Column(
        children: [
          // Search box
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name, email, or mobile...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
          const SizedBox(height: 12),

          // Dropdown filters
          Row(
            children: [
              Expanded(
                child: AppDropdown<String>(
                  value: _selectedSubject,
                  headerText: 'Subject',
                  items: _subjectOptions.map((sub) {
                    return AppDropdownItem<String>(value: sub, label: sub);
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedSubject = val);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherCard(TeacherDirectoryModel teacher, bool isDark) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white10 : AppColors.hairline,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
                  child: Text(
                    teacher.name.isNotEmpty ? teacher.name[0].toUpperCase() : 'T',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teacher.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: teacher.subject
                            .split(',')
                            .map((s) => s.trim())
                            .where((s) => s.isNotEmpty)
                            .map((sub) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    sub,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded),
                  onPressed: () => _showOptionsSheet(context, teacher),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(
              color: isDark ? Colors.white10 : const Color(0xFFF0F0F0),
              height: 1,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.email_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    teacher.email,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
                const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  teacher.phone,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsSheet(BuildContext context, TeacherDirectoryModel teacher) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Teacher Profile'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditTeacherSheet(context, teacher);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: const Text('Remove Teacher', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showDeleteConfirm(context, teacher);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditTeacherSheet(BuildContext context, TeacherDirectoryModel teacher) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final nameController = TextEditingController(text: teacher.name);
    final phoneController = TextEditingController(
        text: teacher.phone == 'N/A' ? '' : teacher.phone);
    bool isSaving = false;

    final selectedSubjects = teacher.subject
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Teacher Profile',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select Subjects',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      'Physics',
                      'Chemistry',
                      'Mathematics',
                      'Biology',
                      'Other'
                    ].map((sub) {
                      final isSelected = selectedSubjects.contains(sub);
                      return FilterChip(
                        label: Text(sub),
                        selected: isSelected,
                        selectedColor:
                            theme.colorScheme.primary.withOpacity(0.15),
                        checkmarkColor: theme.colorScheme.primary,
                        onSelected: (selected) {
                          setSheetState(() {
                            if (selected) {
                              selectedSubjects.add(sub);
                            } else {
                              selectedSubjects.remove(sub);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              setSheetState(() => isSaving = true);
                              try {
                                final client = ref.read(supabaseClientProvider);
                                await client.from('profiles').update({
                                  'full_name': nameController.text.trim(),
                                  'phone': phoneController.text.trim(),
                                  'subject': selectedSubjects.isEmpty
                                      ? 'Other'
                                      : selectedSubjects.join(', '),
                                }).eq('id', teacher.id);

                                if (mounted) {
                                  Navigator.pop(sheetContext);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Profile updated successfully!')),
                                  );
                                  _fetchData(isSilent: true);
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Error updating profile: $e')),
                                  );
                                }
                              } finally {
                                setSheetState(() => isSaving = false);
                              }
                            },
                      child: isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirm(BuildContext context, TeacherDirectoryModel teacher) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Remove Teacher'),
          content: Text('Are you sure you want to delete ${teacher.name}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  final client = ref.read(supabaseClientProvider);
                  // Since profiles cascade deletes auth users, we can just delete from auth.users using Edge Function or directly if permitted.
                  // For safety, we can delete the profile row (which cascade deletes assignments/timetable)
                  await client.from('profiles').delete().eq('id', teacher.id);
                  _fetchData(isSilent: true);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Teacher removed successfully!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete: $e')),
                    );
                  }
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
