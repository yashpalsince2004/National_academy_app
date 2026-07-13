import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:national_academy/core/constants/app_colors.dart';
import 'package:national_academy/core/services/supabase_providers.dart';
import 'package:national_academy/core/widgets/app_dropdown.dart';


class StudentDirectoryModel {
  final String studentId;
  final String profileId;
  final String rollNo;
  final String status;
  final String dob;
  final String address;
  final String name;
  final String email;
  final String phone;
  final String classLevel;
  final List<String> targetExams;
  final List<String> batches;
  final List<String> batchIds;

  StudentDirectoryModel({
    required this.studentId,
    required this.profileId,
    required this.rollNo,
    required this.status,
    required this.dob,
    required this.address,
    required this.name,
    required this.email,
    required this.phone,
    required this.classLevel,
    required this.targetExams,
    required this.batches,
    required this.batchIds,
  });

  factory StudentDirectoryModel.fromMap(Map<String, dynamic> map) {
    final examsList = map['target_exams'] as List? ?? [];
    final targetExams = examsList.map((e) => e.toString()).toList();
    
    final batchesList = map['batches'] as List? ?? [];
    final batches = batchesList.map((e) => e.toString()).toList();
    
    final batchIdsList = map['batch_ids'] as List? ?? [];
    final batchIds = batchIdsList.map((e) => e.toString()).toList();

    return StudentDirectoryModel(
      studentId: map['student_id'] as String? ?? '',
      profileId: map['profile_id'] as String? ?? '',
      rollNo: map['roll_no'] as String? ?? 'N/A',
      status: map['status'] as String? ?? 'active',
      dob: map['dob'] as String? ?? '',
      address: map['address'] as String? ?? '',
      name: map['full_name'] as String? ?? 'Unnamed',
      email: map['contact_email'] as String? ?? '',
      phone: map['student_phone'] as String? ?? '',
      classLevel: map['class_level'] as String? ?? 'N/A',
      targetExams: targetExams,
      batches: batches,
      batchIds: batchIds,
    );
  }
}

class BatchFilterModel {
  final String id;
  final String name;

  BatchFilterModel({required this.id, required this.name});
}

class AdminStudentsDataScreen extends ConsumerStatefulWidget {
  const AdminStudentsDataScreen({super.key});

  @override
  ConsumerState<AdminStudentsDataScreen> createState() => _AdminStudentsDataScreenState();
}

class _AdminStudentsDataScreenState extends ConsumerState<AdminStudentsDataScreen> {
  final _searchController = TextEditingController();
  
  List<StudentDirectoryModel> _allStudents = [];
  List<BatchFilterModel> _batches = [];
  bool _isLoading = true;
  bool _isRefreshingList = false;
  String _errorMessage = '';

  // Filter values
  String _searchQuery = '';
  String _selectedBatchId = 'All';
  String _selectedClass = 'All';
  String _selectedExam = 'All';

  final List<String> _classOptions = ['All', '11th', '12th', 'Dropper'];
  final List<String> _examOptions = ['All', 'JEE', 'NEET', 'NDA', 'MHT-CET'];

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
      
      // Fetch students from the custom view
      final studentsRes = await client.from('student_directory').select();
      final List studentsList = studentsRes as List? ?? [];
      
      // Fetch batches for filter
      final batchesRes = await client.from('batches').select('id, name');
      final List batchesList = batchesRes as List? ?? [];

      if (mounted) {
        setState(() {
          _allStudents = studentsList.map((e) => StudentDirectoryModel.fromMap(e)).toList();
          _batches = batchesList.map((e) => BatchFilterModel(
            id: e['id'] as String? ?? '',
            name: e['name'] as String? ?? '',
          )).toList();
          _isLoading = false;
          _isRefreshingList = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load students: ${e.toString()}';
          _isLoading = false;
          _isRefreshingList = false;
        });
      }
    }
  }

  List<StudentDirectoryModel> get _filteredStudents {
    return _allStudents.where((student) {
      // Search matches
      final query = _searchQuery.toLowerCase().trim();
      final matchesSearch = query.isEmpty ||
          student.name.toLowerCase().contains(query) ||
          student.rollNo.toLowerCase().contains(query) ||
          student.email.toLowerCase().contains(query) ||
          student.phone.toLowerCase().contains(query);

      // Batch matches
      final matchesBatch = _selectedBatchId == 'All' ||
          student.batchIds.contains(_selectedBatchId);

      // Class matches
      final matchesClass = _selectedClass == 'All' ||
          student.classLevel.toLowerCase() == _selectedClass.toLowerCase();

      // Exam matches
      final matchesExam = _selectedExam == 'All' ||
          student.targetExams.any((e) => e.toLowerCase() == _selectedExam.toLowerCase());

      return matchesSearch && matchesBatch && matchesClass && matchesExam;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filteredList = _filteredStudents;

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
                          const SizedBox(height: 16),
                          Text(_errorMessage, textAlign: TextAlign.center),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _fetchData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      // Custom Header Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Row(
                          children: [
                            // Back Button (Circle)
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? const Color(0xFF333335) : AppColors.hairline,
                                ),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                                onPressed: () => context.pop(),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                            
                            // Title Text
                            Expanded(
                              child: Center(
                                child: Text(
                                  'Students',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            ),
                            
                            // Refresh Button (Circle)
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? const Color(0xFF333335) : AppColors.hairline,
                                ),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.refresh_rounded, size: 20),
                                onPressed: () => _fetchData(isSilent: true),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Search Bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceTile1 : Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: isDark ? const Color(0xFF333335) : AppColors.hairline,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              filled: false,
                              fillColor: Colors.transparent,
                              hintText: 'Search by name, roll no, or phone...',
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(left: 6.0),
                                child: Icon(Icons.search_rounded, color: AppColors.textLight),
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, color: AppColors.textLight),
                                      onPressed: () {
                                        setState(() {
                                          _searchController.clear();
                                          _searchQuery = '';
                                        });
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                              });
                            },
                          ),
                        ),
                      ),

                      // Filter Options Header Row (3 columns filling the width)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        child: Row(
                          children: [
                            // Batch Filter Dropdown
                            Expanded(
                              child: AppDropdown<String>(
                                value: _selectedBatchId,
                                isFullWidthButton: true,
                                borderRadius: BorderRadius.circular(30),
                                showDownArrow: false,
                                textAlign: TextAlign.center,
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
                                headerText: 'Batch',
                                items: [
                                  AppDropdownItem(value: 'All', label: 'Batches'),
                                  ..._batches.map((b) => AppDropdownItem(value: b.id, label: b.name)),
                                ],
                                onChanged: (val) {
                                  setState(() {
                                    _selectedBatchId = val;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Class Filter Dropdown
                            Expanded(
                              child: AppDropdown<String>(
                                value: _selectedClass,
                                isFullWidthButton: true,
                                borderRadius: BorderRadius.circular(30),
                                showDownArrow: false,
                                textAlign: TextAlign.center,
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
                                headerText: 'Class',
                                items: _classOptions.map((c) => AppDropdownItem(
                                  value: c, 
                                  label: c == 'All' ? 'Classes' : c,
                                )).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedClass = val;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Exam Filter Dropdown
                            Expanded(
                              child: AppDropdown<String>(
                                value: _selectedExam,
                                isFullWidthButton: true,
                                borderRadius: BorderRadius.circular(30),
                                showDownArrow: false,
                                textAlign: TextAlign.center,
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
                                headerText: 'Exam',
                                items: _examOptions.map((e) => AppDropdownItem(
                                  value: e, 
                                  label: e == 'All' ? 'Exams' : e,
                                )).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedExam = val;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      // Students List
                      Expanded(
                        child: _isRefreshingList
                            ? const Center(child: CircularProgressIndicator())
                            : filteredList.isEmpty
                                ? Center(
                              child: SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.people_outline_rounded,
                                        size: 72,
                                        color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No Students Found',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _allStudents.isEmpty
                                            ? 'Create a student profile to get started.'
                                            : 'No students match your active filters.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                        ),
                                      ),
                                      if (_allStudents.isEmpty) ...[
                                        const SizedBox(height: 24),
                                        ElevatedButton.icon(
                                          onPressed: () => context.pushNamed('register-student'),
                                          icon: const Icon(Icons.add_rounded),
                                          label: const Text('Add Student'),
                                        ),
                                      ]
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredList.length,
                              padding: const EdgeInsets.all(16.0),
                              itemBuilder: (context, index) {
                                final student = filteredList[index];
                                return _buildStudentCard(context, student, isDark);
                              },
                            ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, StudentDirectoryModel student, bool isDark) {
    final theme = Theme.of(context);
    final statusColor = student.status.toLowerCase() == 'active' 
        ? Colors.green 
        : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceTile1 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF333335) : AppColors.hairline,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            // View detailed profile modal or screen if needed
            _showStudentDetailsSheet(context, student, isDark);
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 26,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Text(
                    student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Name & Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              student.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              student.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Roll No: ${student.rollNo}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Target Exams, Class, & Batch Badges
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          // Class Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Class ${student.classLevel}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                              ),
                            ),
                          ),
                          
                          // Target Exams Badges
                          ...student.targetExams.map((exam) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              exam.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          )),

                          // Batch Badges
                          if (student.batches.isEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'No Batch',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            )
                          else
                            ...student.batches.map((batch) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                batch,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            )),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showStudentDetailsSheet(BuildContext context, StudentDirectoryModel student, bool isDark) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Header Profile Info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                        child: Text(
                          student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.name,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Roll No: ${student.rollNo}',
                              style: TextStyle(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  Text(
                    'Student Profile Details',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  _buildDetailTile(Icons.class_outlined, 'Class Level', student.classLevel),
                  _buildDetailTile(Icons.assignment_ind_outlined, 'Target Exams', student.targetExams.join(', ').toUpperCase()),
                  _buildDetailTile(Icons.badge_outlined, 'Enrolled Batches', student.batches.isEmpty ? 'None' : student.batches.join(', ')),
                  _buildDetailTile(Icons.cake_outlined, 'Date of Birth', student.dob.isEmpty ? 'N/A' : student.dob),
                  _buildDetailTile(Icons.email_outlined, 'Contact Email', student.email.isEmpty ? 'N/A' : student.email),
                  _buildDetailTile(Icons.phone_outlined, 'Student Mobile', student.phone.isEmpty ? 'N/A' : student.phone),
                  _buildDetailTile(Icons.location_on_outlined, 'Address', student.address.isEmpty ? 'N/A' : student.address),
                  
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Edit Student Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.pop(context); // Close details sheet
                        _showEditStudentSheet(context, student); // Open edit sheet
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit Student Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditStudentSheet(BuildContext context, StudentDirectoryModel student) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Form controllers
    final nameController = TextEditingController(text: student.name);
    final emailController = TextEditingController(text: student.email);
    final phoneController = TextEditingController(text: student.phone);
    final dobController = TextEditingController(text: student.dob);
    final addressController = TextEditingController(text: student.address);
    
    // State lists
    String selectedClass = student.classLevel;
    final List<String> selectedExams = List.from(student.targetExams);
    final List<String> selectedBatchIds = List.from(student.batchIds);
    
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: DraggableScrollableSheet(
                initialChildSize: 0.85,
                maxChildSize: 0.95,
                minChildSize: 0.5,
                expand: false,
                builder: (context, scrollController) {
                  return SingleChildScrollView(
                    controller: scrollController,
                    padding: EdgeInsets.only(
                      left: 24.0,
                      right: 24.0,
                      top: 24.0,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 48,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Edit Student Profile',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isSaving)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Form Fields
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: 'Contact Email',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Student Mobile',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: dobController,
                          decoration: InputDecoration(
                            labelText: 'Date of Birth (YYYY-MM-DD)',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.cake_outlined),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_today_outlined),
                              onPressed: () async {
                                final initialDate = DateTime.tryParse(dobController.text) ?? DateTime(2005);
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: initialDate,
                                  firstDate: DateTime(1990),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  dobController.text = picked.toString().split(' ').first;
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: addressController,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 20),

                        // Class Level Dropdown
                        Text(
                          'Class Level',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        AppDropdown<String>(
                          value: selectedClass == 'N/A' ? '12th' : selectedClass,
                          isFullWidthButton: true,
                          headerText: 'Class',
                          items: [
                            AppDropdownItem(value: '11th', label: '11th'),
                            AppDropdownItem(value: '12th', label: '12th'),
                            AppDropdownItem(value: 'Dropper', label: 'Dropper'),
                          ],
                          onChanged: (val) {
                            setSheetState(() {
                              selectedClass = val;
                            });
                          },
                        ),
                        const SizedBox(height: 20),

                        // Target Exams Checklist
                        Text(
                          'Target Exams',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ['JEE', 'NEET', 'NDA', 'MHT-CET'].map((exam) {
                            final isSelected = selectedExams.contains(exam.toLowerCase()) || 
                                               selectedExams.contains(exam.toUpperCase()) ||
                                               selectedExams.contains(exam);
                            return FilterChip(
                              label: Text(exam),
                              selected: isSelected,
                              onSelected: (selected) {
                                setSheetState(() {
                                  final matchKey = selectedExams.firstWhere(
                                    (e) => e.toLowerCase() == exam.toLowerCase(),
                                    orElse: () => '',
                                  );
                                  if (selected) {
                                    if (matchKey.isEmpty) {
                                      selectedExams.add(exam);
                                    }
                                  } else {
                                    if (matchKey.isNotEmpty) {
                                      selectedExams.remove(matchKey);
                                    }
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),

                        // Enrolled Batches Checklist
                        Text(
                          'Assign Batches',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        _batches.isEmpty
                            ? Text(
                                'No batches available in the academy.',
                                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textLight),
                              )
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _batches.map((batch) {
                                  final isSelected = selectedBatchIds.contains(batch.id);
                                  return FilterChip(
                                    label: Text(batch.name),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setSheetState(() {
                                        if (selected) {
                                          selectedBatchIds.add(batch.id);
                                        } else {
                                          selectedBatchIds.remove(batch.id);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                        const SizedBox(height: 32),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final name = nameController.text.trim();
                                    final email = emailController.text.trim();
                                    final phone = phoneController.text.trim();
                                    final dob = dobController.text.trim();
                                    final address = addressController.text.trim();

                                    if (name.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Name cannot be empty')),
                                      );
                                      return;
                                    }

                                    setSheetState(() {
                                      isSaving = true;
                                    });

                                    try {
                                      final client = ref.read(supabaseClientProvider);

                                      // 1. Update profiles table
                                      await client.from('profiles').update({
                                        'full_name': name,
                                        'phone': phone,
                                        'contact_email': email,
                                      }).eq('id', student.profileId);

                                      // 2. Update students table
                                      await client.from('students').update({
                                        'dob': dob.isEmpty ? null : dob,
                                        'address': address,
                                        'additional_info': {
                                          'academic_class': selectedClass,
                                          'target_exams': selectedExams,
                                          'class_level': selectedClass,
                                        }
                                      }).eq('id', student.studentId);

                                      // 3. Update batch enrollments
                                      // First delete all enrollments for this student
                                      await client
                                          .from('batch_enrollments')
                                          .delete()
                                          .eq('student_id', student.studentId);

                                      // Insert new enrollments
                                      for (final bId in selectedBatchIds) {
                                        await client.from('batch_enrollments').insert({
                                          'student_id': student.studentId,
                                          'batch_id': bId,
                                          'status': 'active',
                                        });
                                      }

                                      // Refresh listing silently
                                      await _fetchData(isSilent: true);

                                      if (mounted) {
                                        Navigator.pop(context); // Close edit bottom sheet
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Student profile updated successfully')),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        setSheetState(() {
                                          isSaving = false;
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Failed to update: ${e.toString()}')),
                                        );
                                      }
                                    }
                                  },
                            child: const Text(
                              'Save Changes',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AppColors.textLight),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
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
