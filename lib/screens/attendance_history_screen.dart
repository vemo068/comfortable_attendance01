import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:comfortable_attendance/services/storage_service.dart';
import 'package:comfortable_attendance/models/worker.dart';
import 'package:comfortable_attendance/models/attendance.dart';
import 'package:comfortable_attendance/widgets/attendance_badge.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  final StorageService storageService;

  const AttendanceHistoryScreen({
    super.key,
    required this.storageService,
  });

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  List<Attendance> attendanceHistory = [];
  List<Attendance> filteredHistory = [];
  List<Worker> workers = [];
  Map<String, Worker> workerMap = {};
  
  String searchQuery = '';
  String? selectedWorkerId;
  DateTime? startDate;
  DateTime? endDate;
  AttendanceStatus? selectedStatus;
  
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    
    attendanceHistory = await widget.storageService.getAttendance();
    workers = await widget.storageService.getWorkers();
    
    // Create worker map for quick lookup
    workerMap = {for (var worker in workers) worker.id: worker};
    
    // Sort by date descending
    attendanceHistory.sort((a, b) => b.date.compareTo(a.date));
    
    _applyFilters();
    setState(() => isLoading = false);
  }

  void _applyFilters() {
    filteredHistory = attendanceHistory.where((attendance) {
      // Worker filter
      if (selectedWorkerId != null && attendance.workerId != selectedWorkerId) {
        return false;
      }
      
      // Date range filter
      if (startDate != null && attendance.date.isBefore(startDate!)) {
        return false;
      }
      if (endDate != null && attendance.date.isAfter(endDate!)) {
        return false;
      }
      
      // Status filter
      if (selectedStatus != null && attendance.status != selectedStatus) {
        return false;
      }
      
      // Search query filter
      if (searchQuery.isNotEmpty) {
        final worker = workerMap[attendance.workerId];
        if (worker != null) {
          if (!worker.name.toLowerCase().contains(searchQuery.toLowerCase()) &&
              !worker.employeeId.toLowerCase().contains(searchQuery.toLowerCase())) {
            return false;
          }
        }
      }
      
      return true;
    }).toList();
  }

  void _clearFilters() {
    setState(() {
      selectedWorkerId = null;
      startDate = null;
      endDate = null;
      selectedStatus = null;
      searchQuery = '';
      _applyFilters();
    });
  }

  Future<void> _selectDateRange() async {
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
    );
    
    if (dateRange != null) {
      setState(() {
        startDate = dateRange.start;
        endDate = dateRange.end;
        _applyFilters();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('d MMM yyyy', 'ar');
    final activeFiltersCount = [
      selectedWorkerId != null,
      startDate != null,
      selectedStatus != null,
      searchQuery.isNotEmpty,
    ].where((filter) => filter).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل الحضور'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFiltersBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Summary
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'البحث بالاسم أو رقم الموظف...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.background,
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                      _applyFilters();
                    });
                  },
                ),
                if (activeFiltersCount > 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'فلاتر مطبقة: $activeFiltersCount',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _clearFilters,
                        child: const Text('إزالة الفلاتر'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // Results Summary
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'النتائج: ${filteredHistory.length} من ${attendanceHistory.length}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),

          // Attendance History List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredHistory.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 64,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              attendanceHistory.isEmpty ? 'لا يوجد سجل حضور بعد' : 'لا توجد نتائج',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              attendanceHistory.isEmpty
                                  ? 'ابدأ بتسجيل الحضور اليومي للعمال'
                                  : 'جرب تعديل الفلاتر أو البحث',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: filteredHistory.length,
                        itemBuilder: (context, index) {
                          final attendance = filteredHistory[index];
                          final worker = workerMap[attendance.workerId];
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                child: Icon(
                                  Icons.person,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                              title: Text(
                                worker?.name ?? 'عامل محذوف',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    worker?.position ?? '',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    dateFormatter.format(attendance.date),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AttendanceBadge(status: attendance.status),
                                  if (worker != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      worker.employeeId,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ],
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

  void _showFiltersBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'فلتر النتائج',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Worker Filter
            DropdownButtonFormField<String>(
              value: selectedWorkerId,
              decoration: InputDecoration(
                labelText: 'العامل',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('جميع العمال')),
                ...workers.map((worker) => DropdownMenuItem(
                  value: worker.id,
                  child: Text(worker.name),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  selectedWorkerId = value;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Status Filter
            DropdownButtonFormField<AttendanceStatus>(
              value: selectedStatus,
              decoration: InputDecoration(
                labelText: 'حالة الحضور',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('جميع الحالات')),
                ...AttendanceStatus.values.map((status) => DropdownMenuItem(
                  value: status,
                  child: Text(status.arabicName),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  selectedStatus = value;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Date Range Filter
            OutlinedButton(
              onPressed: _selectDateRange,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.date_range),
                  const SizedBox(width: 8),
                  Text(
                    startDate != null && endDate != null
                        ? 'من ${DateFormat('d MMM yyyy', 'ar').format(startDate!)} إلى ${DateFormat('d MMM yyyy', 'ar').format(endDate!)}'
                        : 'اختر فترة زمنية',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _clearFilters();
                      Navigator.pop(context);
                    },
                    child: const Text('إزالة الفلاتر'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _applyFilters();
                      Navigator.pop(context);
                    },
                    child: const Text('تطبيق'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}