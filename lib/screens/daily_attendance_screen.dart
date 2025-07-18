import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:comfortable_attendance/services/storage_service.dart';
import 'package:comfortable_attendance/services/attendance_service.dart';
import 'package:comfortable_attendance/models/worker.dart';
import 'package:comfortable_attendance/models/attendance.dart';
import 'package:comfortable_attendance/widgets/attendance_badge.dart';

class DailyAttendanceScreen extends StatefulWidget {
  final StorageService storageService;
  final AttendanceService attendanceService;

  const DailyAttendanceScreen({
    super.key,
    required this.storageService,
    required this.attendanceService,
  });

  @override
  State<DailyAttendanceScreen> createState() => _DailyAttendanceScreenState();
}

class _DailyAttendanceScreenState extends State<DailyAttendanceScreen> {
  List<Worker> workers = [];
  Map<String, AttendanceStatus> attendanceMap = {};
  DateTime selectedDate = DateTime.now();
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    
    workers = await widget.storageService.getWorkers();
    final existingAttendance = await widget.storageService.getAttendanceForDate(selectedDate);
    
    // Initialize attendance map
    attendanceMap.clear();
    for (Worker worker in workers) {
      final existingRecord = existingAttendance.where((a) => a.workerId == worker.id).firstOrNull;
      attendanceMap[worker.id] = existingRecord?.status ?? AttendanceStatus.present;
    }
    
    setState(() => isLoading = false);
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    
    if (date != null) {
      setState(() => selectedDate = date);
      _loadData();
    }
  }

  Future<void> _saveAttendance() async {
    if (workers.isEmpty) return;

    setState(() => isSaving = true);

    try {
      await widget.attendanceService.markDailyAttendance(selectedDate, attendanceMap);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الحضور بنجاح')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء الحفظ')),
      );
    } finally {
      setState(() => isSaving = false);
    }
  }

  void _markAllAs(AttendanceStatus status) {
    setState(() {
      for (String workerId in attendanceMap.keys) {
        attendanceMap[workerId] = status;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('EEEE، d MMMM yyyy', 'ar');
    final isToday = selectedDate.year == DateTime.now().year &&
        selectedDate.month == DateTime.now().month &&
        selectedDate.day == DateTime.now().day;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل الحضور اليومي'),
        actions: [
          if (isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: workers.isEmpty ? null : _saveAttendance,
            ),
        ],
      ),
      body: Column(
        children: [
          // Date Selection Card
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateFormatter.format(selectedDate),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isToday) ...[
                            const SizedBox(height: 4),
                            Text(
                              'اليوم',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Quick Actions
          if (workers.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'تحديد الكل:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildQuickActionButton(
                            'حاضر',
                            Icons.check_circle,
                            Colors.green,
                            () => _markAllAs(AttendanceStatus.present),
                          ),
                          const SizedBox(width: 8),
                          _buildQuickActionButton(
                            'غائب',
                            Icons.cancel,
                            Colors.red,
                            () => _markAllAs(AttendanceStatus.absent),
                          ),
                          const SizedBox(width: 8),
                          _buildQuickActionButton(
                            'متأخر',
                            Icons.schedule,
                            Colors.orange,
                            () => _markAllAs(AttendanceStatus.late),
                          ),
                          const SizedBox(width: 8),
                          _buildQuickActionButton(
                            'معذور',
                            Icons.info,
                            Colors.blue,
                            () => _markAllAs(AttendanceStatus.excused),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Workers List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : workers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_add,
                              size: 64,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'لا يوجد عمال بعد',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'اضغط على إدارة العمال لإضافة عمال جدد',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: workers.length,
                        itemBuilder: (context, index) {
                          final worker = workers[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                    child: Icon(
                                      Icons.person,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          worker.name,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          worker.position,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildAttendanceSelector(worker.id),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: color),
      label: Text(text, style: TextStyle(color: color)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildAttendanceSelector(String workerId) {
    final currentStatus = attendanceMap[workerId] ?? AttendanceStatus.present;
    
    return PopupMenuButton<AttendanceStatus>(
      initialValue: currentStatus,
      child: AttendanceBadge(status: currentStatus),
      onSelected: (status) {
        setState(() {
          attendanceMap[workerId] = status;
        });
      },
      itemBuilder: (context) => AttendanceStatus.values.map((status) {
        return PopupMenuItem(
          value: status,
          child: Row(
            children: [
              AttendanceBadge(status: status, isCompact: true),
              const SizedBox(width: 8),
              Text(status.arabicName),
            ],
          ),
        );
      }).toList(),
    );
  }
}