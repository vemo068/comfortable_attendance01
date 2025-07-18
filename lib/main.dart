import 'package:flutter/material.dart';

import 'package:comfortable_attendance/theme.dart';
import 'package:comfortable_attendance/services/storage_service.dart';
import 'package:comfortable_attendance/services/attendance_service.dart';
import 'package:comfortable_attendance/screens/home_screen.dart';
import 'package:comfortable_attendance/models/worker.dart';
import 'package:comfortable_attendance/models/attendance.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Arabic date formatting
  await initializeDateFormatting('ar');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'الحضور المريح',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  final StorageService _storageService = StorageService();
  late AttendanceService _attendanceService;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _storageService.init();
    _attendanceService = AttendanceService(_storageService);
    
    // Add sample data if no workers exist
    final workers = await _storageService.getWorkers();
    if (workers.isEmpty) {
      await _addSampleData();
    }
    
    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _addSampleData() async {
    final sampleWorkers = [
      Worker(
        id: '1',
        name: 'أحمد محمد علي',
        employeeId: 'EMP001',
        department: 'التسويق',
        position: 'مدير تسويق',
        phoneNumber: '0501234567',
        createdAt: DateTime.now(),
      ),
      Worker(
        id: '2',
        name: 'فاطمة سعد الدين',
        employeeId: 'EMP002',
        department: 'الموارد البشرية',
        position: 'أخصائية موارد بشرية',
        phoneNumber: '0509876543',
        createdAt: DateTime.now(),
      ),
      Worker(
        id: '3',
        name: 'خالد عبد الله',
        employeeId: 'EMP003',
        department: 'تقنية المعلومات',
        position: 'مطور برامج',
        phoneNumber: '0505551234',
        createdAt: DateTime.now(),
      ),
      Worker(
        id: '4',
        name: 'نورا أحمد',
        employeeId: 'EMP004',
        department: 'المالية',
        position: 'محاسبة',
        phoneNumber: '0504449876',
        createdAt: DateTime.now(),
      ),
      Worker(
        id: '5',
        name: 'محمد سالم',
        employeeId: 'EMP005',
        department: 'المبيعات',
        position: 'مندوب مبيعات',
        phoneNumber: '0503337654',
        createdAt: DateTime.now(),
      ),
    ];

    for (final worker in sampleWorkers) {
      await _storageService.addWorker(worker);
    }

    // Add sample attendance for the last few days
    final now = DateTime.now();
    final attendanceStatuses = [
      AttendanceStatus.present,
      AttendanceStatus.late,
      AttendanceStatus.absent,
      AttendanceStatus.excused,
    ];

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final attendanceMap = <String, AttendanceStatus>{};
      
      for (final worker in sampleWorkers) {
        // Random attendance status with higher probability for present
        final random = (worker.id.hashCode + date.day) % 10;
        AttendanceStatus status;
        if (random < 7) {
          status = AttendanceStatus.present;
        } else if (random < 8) {
          status = AttendanceStatus.late;
        } else if (random < 9) {
          status = AttendanceStatus.excused;
        } else {
          status = AttendanceStatus.absent;
        }
        attendanceMap[worker.id] = status;
      }
      
      await _attendanceService.markDailyAttendance(date, attendanceMap);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'جارٍ تهيئة التطبيق...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    return HomeScreen(
      storageService: _storageService,
      attendanceService: _attendanceService,
    );
  }
}
