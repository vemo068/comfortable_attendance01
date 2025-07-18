import 'package:comfortable_attendance/models/worker.dart';
import 'package:comfortable_attendance/models/attendance.dart';
import 'package:comfortable_attendance/models/monthly_report.dart';
import 'package:comfortable_attendance/services/storage_service.dart';

class AttendanceService {
  final StorageService _storageService;

  AttendanceService(this._storageService);

  Future<List<MonthlyReport>> generateMonthlyReports(int month, int year) async {
    final workers = await _storageService.getWorkers();
    final attendanceList = await _storageService.getAttendanceForMonth(month, year);
    
    List<MonthlyReport> reports = [];
    
    for (Worker worker in workers) {
      final workerAttendance = attendanceList.where((a) => a.workerId == worker.id).toList();
      
      final totalDays = _getWorkingDaysInMonth(month, year);
      final presentDays = workerAttendance.where((a) => a.status == AttendanceStatus.present).length;
      final absentDays = workerAttendance.where((a) => a.status == AttendanceStatus.absent).length;
      final lateDays = workerAttendance.where((a) => a.status == AttendanceStatus.late).length;
      final excusedDays = workerAttendance.where((a) => a.status == AttendanceStatus.excused).length;
      
      final attendancePercentage = totalDays > 0 ? (presentDays + lateDays) / totalDays * 100 : 0.0;
      
      reports.add(MonthlyReport(
        workerId: worker.id,
        workerName: worker.name,
        month: month,
        year: year,
        totalDays: totalDays,
        presentDays: presentDays,
        absentDays: absentDays,
        lateDays: lateDays,
        excusedDays: excusedDays,
        attendancePercentage: attendancePercentage,
      ));
    }
    
    return reports;
  }

  Future<MonthlyReport?> getWorkerMonthlyReport(String workerId, int month, int year) async {
    final worker = await _getWorkerById(workerId);
    if (worker == null) return null;
    
    final attendanceList = await _storageService.getAttendanceForMonth(month, year);
    final workerAttendance = attendanceList.where((a) => a.workerId == workerId).toList();
    
    final totalDays = _getWorkingDaysInMonth(month, year);
    final presentDays = workerAttendance.where((a) => a.status == AttendanceStatus.present).length;
    final absentDays = workerAttendance.where((a) => a.status == AttendanceStatus.absent).length;
    final lateDays = workerAttendance.where((a) => a.status == AttendanceStatus.late).length;
    final excusedDays = workerAttendance.where((a) => a.status == AttendanceStatus.excused).length;
    
    final attendancePercentage = totalDays > 0 ? (presentDays + lateDays) / totalDays * 100 : 0.0;
    
    return MonthlyReport(
      workerId: workerId,
      workerName: worker.name,
      month: month,
      year: year,
      totalDays: totalDays,
      presentDays: presentDays,
      absentDays: absentDays,
      lateDays: lateDays,
      excusedDays: excusedDays,
      attendancePercentage: attendancePercentage,
    );
  }

  Future<bool> hasAttendanceForDate(DateTime date) async {
    final attendanceList = await _storageService.getAttendanceForDate(date);
    return attendanceList.isNotEmpty;
  }

  Future<void> markDailyAttendance(DateTime date, Map<String, AttendanceStatus> attendanceMap) async {
    final workers = await _storageService.getWorkers();
    final existingAttendance = await _storageService.getAttendanceForDate(date);
    
    for (Worker worker in workers) {
      final status = attendanceMap[worker.id] ?? AttendanceStatus.absent;
      
      final existingRecord = existingAttendance.where((a) => a.workerId == worker.id).firstOrNull;
      
      if (existingRecord != null) {
        // Update existing record
        final updatedRecord = existingRecord.copyWith(
          status: status,
          timestamp: DateTime.now(),
        );
        await _storageService.updateAttendance(updatedRecord);
      } else {
        // Create new record
        final newRecord = Attendance(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          workerId: worker.id,
          date: date,
          status: status,
          notes: '',
          timestamp: DateTime.now(),
        );
        await _storageService.addAttendance(newRecord);
      }
    }
  }

  Future<Worker?> _getWorkerById(String workerId) async {
    final workers = await _storageService.getWorkers();
    return workers.where((w) => w.id == workerId).firstOrNull;
  }

  int _getWorkingDaysInMonth(int month, int year) {
    final firstDayOfMonth = DateTime(year, month, 1);
    final lastDayOfMonth = DateTime(year, month + 1, 0);
    
    int workingDays = 0;
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final date = DateTime(year, month, day);
      // Exclude Fridays (weekday 5) and Saturdays (weekday 6) for Islamic countries
      if (date.weekday != DateTime.friday && date.weekday != DateTime.saturday) {
        workingDays++;
      }
    }
    return workingDays;
  }
}