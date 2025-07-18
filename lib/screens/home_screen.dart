import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:comfortable_attendance/services/storage_service.dart';
import 'package:comfortable_attendance/services/attendance_service.dart';
import 'package:comfortable_attendance/screens/workers_screen.dart';
import 'package:comfortable_attendance/screens/daily_attendance_screen.dart';
import 'package:comfortable_attendance/screens/monthly_reports_screen.dart';
import 'package:comfortable_attendance/screens/attendance_history_screen.dart';
import 'package:comfortable_attendance/models/worker.dart';
import 'package:comfortable_attendance/models/attendance.dart';

class HomeScreen extends StatefulWidget {
  final StorageService storageService;
  final AttendanceService attendanceService;

  const HomeScreen({
    super.key,
    required this.storageService,
    required this.attendanceService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Worker> workers = [];
  List<Attendance> todayAttendance = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    workers = await widget.storageService.getWorkers();
    todayAttendance = await widget.storageService.getAttendanceForDate(DateTime.now());
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final dateFormatter = DateFormat('EEEE، d MMMM yyyy', 'ar');

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'الحضور المريح',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colorScheme.primaryContainer,
                        colorScheme.primaryContainer.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 40),
                          Text(
                            dateFormatter.format(today),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildListDelegate([
                    _buildQuickStatCard(
                      context,
                      'إجمالي العمال',
                      workers.length.toString(),
                      Icons.people,
                      colorScheme.primary,
                    ),
                    _buildQuickStatCard(
                      context,
                      'حضور اليوم',
                      todayAttendance.where((a) => a.status == AttendanceStatus.present).length.toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                    _buildQuickStatCard(
                      context,
                      'غياب اليوم',
                      todayAttendance.where((a) => a.status == AttendanceStatus.absent).length.toString(),
                      Icons.cancel,
                      Colors.red,
                    ),
                    _buildQuickStatCard(
                      context,
                      'متأخر اليوم',
                      todayAttendance.where((a) => a.status == AttendanceStatus.late).length.toString(),
                      Icons.schedule,
                      Colors.orange,
                    ),
                  ]),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      'الإجراءات السريعة',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildActionCard(
                      context,
                      'إدارة العمال',
                      'إضافة وتعديل وحذف بيانات العمال',
                      Icons.people_alt,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WorkersScreen(
                            storageService: widget.storageService,
                          ),
                        ),
                      ).then((_) => _loadData()),
                    ),
                    _buildActionCard(
                      context,
                      'تسجيل الحضور اليومي',
                      'تسجيل حضور العمال لليوم الحالي',
                      Icons.assignment_turned_in,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DailyAttendanceScreen(
                            storageService: widget.storageService,
                            attendanceService: widget.attendanceService,
                          ),
                        ),
                      ).then((_) => _loadData()),
                    ),
                    _buildActionCard(
                      context,
                      'التقارير الشهرية',
                      'عرض تقارير الحضور الشهرية للعمال',
                      Icons.assessment,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MonthlyReportsScreen(
                            attendanceService: widget.attendanceService,
                          ),
                        ),
                      ),
                    ),
                    _buildActionCard(
                      context,
                      'سجل الحضور',
                      'البحث في سجل الحضور التاريخي',
                      Icons.history,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AttendanceHistoryScreen(
                            storageService: widget.storageService,
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}