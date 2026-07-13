import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:national_academy/core/widgets/app_dropdown.dart';

class LecturesTab extends StatefulWidget {
  const LecturesTab({super.key});

  @override
  State<LecturesTab> createState() => _LecturesTabState();
}

class _LecturesTabState extends State<LecturesTab> {
  final List<Map<String, dynamic>> timetable = [
    {'time': '09:00 AM', 'subject': 'Physics', 'batch': 'Batch XII-A', 'teacher': 'Mr. Sharma', 'room': 'Room 101'},
    {'time': '11:00 AM', 'subject': 'Chemistry', 'batch': 'Batch XII-B', 'teacher': 'Mrs. Gupta', 'room': 'Room 102'},
    {'time': '02:00 PM', 'subject': 'Maths', 'batch': 'Batch XI-A', 'teacher': 'Mr. Verma', 'room': 'Lab B'},
    {'time': '04:00 PM', 'subject': 'Biology', 'batch': 'Batch XI-B', 'teacher': 'Dr. Sen', 'room': 'Room 104'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lecture Schedules',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: -0.5),
              ),
              IconButton(
                icon: const Icon(Icons.add_box_rounded),
                color: theme.colorScheme.primary,
                onPressed: () => _showScheduleDialog(context),
              )
            ],
          ),
          const SizedBox(height: 16),

          // Daily Timeline
          Text(
            'Today\'s Sessions',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: timetable.length,
            itemBuilder: (context, index) {
              final lecture = timetable[index];
              return _buildLectureCard(context, lecture);
            },
          ),
          const SizedBox(height: 24),

          // Timetable portion tracker
          Text(
            'Curriculum Portion & Status',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          _buildPortionStatusCard(context),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLectureCard(BuildContext context, Map<String, dynamic> lecture) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Column(
              children: [
                Text(
                  lecture['time'].split(' ')[0],
                  style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                ),
                Text(
                  lecture['time'].split(' ')[1],
                  style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Container(
              width: 1.5,
              height: 48,
              color: Colors.grey.shade300,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${lecture['subject']} - ${lecture['batch']}',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        lecture['teacher'] as String,
                        style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        lecture['room'] as String,
                        style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.more_vert_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildPortionStatusCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildPortionItem(context, 'Physics XII-A', 'Current Unit: Electrostatics', 0.8),
            const Divider(height: 24),
            _buildPortionItem(context, 'Chemistry XII-B', 'Current Unit: Organic Chemistry', 0.5),
            const Divider(height: 24),
            _buildPortionItem(context, 'Maths XI-A', 'Current Unit: Trigonometry', 0.9),
          ],
        ),
      ),
    );
  }

  Widget _buildPortionItem(BuildContext context, String title, String subtitle, double value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 36,
          height: 36,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: value,
                strokeWidth: 4,
                backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                color: theme.colorScheme.primary,
              ),
              Text(
                '${(value * 100).toInt()}%',
                style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showScheduleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        String batch = 'Batch XII-A';
        String subject = 'Physics';
        String? teacher = 'Mr. Sharma';
        String time = '9:00 AM';

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Schedule New Lecture'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppDropdown<String>(
                label: 'Batch',
                headerText: 'Select Batch',
                value: batch,
                items: [
                  AppDropdownItem(value: 'Batch XII-A', label: 'Batch XII-A'),
                  AppDropdownItem(value: 'Batch XII-B', label: 'Batch XII-B'),
                ],
                onChanged: (val) => batch = val,
              ),
              const SizedBox(height: 10),
              AppDropdown<String>(
                label: 'Subject',
                headerText: 'Select Subject',
                value: subject,
                items: [
                  AppDropdownItem(value: 'Physics', label: 'Physics'),
                  AppDropdownItem(value: 'Chemistry', label: 'Chemistry'),
                ],
                onChanged: (val) => subject = val,
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(labelText: 'Teacher Name'),
                onChanged: (val) => teacher = val,
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(labelText: 'Start Time (e.g. 10:00 AM)'),
                onChanged: (val) => time = val,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  timetable.add({
                    'time': time,
                    'subject': subject,
                    'batch': batch,
                    'teacher': teacher,
                    'room': 'TBD',
                  });
                });
                Navigator.pop(context);
              },
              child: const Text('Schedule'),
            ),
          ],
        );
      },
    );
  }
}
