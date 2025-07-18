import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:comfortable_attendance/models/worker.dart';
import 'package:comfortable_attendance/models/attendance.dart';

class StorageService {
  static const String _workersKey = 'workers';
  static const String _attendanceKey = 'attendance';
  
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Worker operations
  Future<List<Worker>> getWorkers() async {
    final workersJson = _prefs?.getString(_workersKey);
    if (workersJson == null) return [];
    
    final List<dynamic> workersList = json.decode(workersJson);
    return workersList.map((json) => Worker.fromJson(json)).toList();
  }

  Future<void> saveWorkers(List<Worker> workers) async {
    final workersJson = json.encode(workers.map((w) => w.toJson()).toList());
    await _prefs?.setString(_workersKey, workersJson);
  }

  Future<void> addWorker(Worker worker) async {
    final workers = await getWorkers();
    workers.add(worker);
    await saveWorkers(workers);
  }

  Future<void> updateWorker(Worker worker) async {
    final workers = await getWorkers();
    final index = workers.indexWhere((w) => w.id == worker.id);
    if (index != -1) {
      workers[index] = worker;
      await saveWorkers(workers);
    }
  }

  Future<void> deleteWorker(String workerId) async {
    final workers = await getWorkers();
    workers.removeWhere((w) => w.id == workerId);
    await saveWorkers(workers);
    
    // Also delete related attendance records
    final attendanceList = await getAttendance();
    attendanceList.removeWhere((a) => a.workerId == workerId);
    await saveAttendance(attendanceList);
  }

  // Attendance operations
  Future<List<Attendance>> getAttendance() async {
    final attendanceJson = _prefs?.getString(_attendanceKey);
    if (attendanceJson == null) return [];
    
    final List<dynamic> attendanceList = json.decode(attendanceJson);
    return attendanceList.map((json) => Attendance.fromJson(json)).toList();
  }

  Future<void> saveAttendance(List<Attendance> attendanceList) async {
    final attendanceJson = json.encode(attendanceList.map((a) => a.toJson()).toList());
    await _prefs?.setString(_attendanceKey, attendanceJson);
  }

  Future<void> addAttendance(Attendance attendance) async {
    final attendanceList = await getAttendance();
    attendanceList.add(attendance);
    await saveAttendance(attendanceList);
  }

  Future<void> updateAttendance(Attendance attendance) async {
    final attendanceList = await getAttendance();
    final index = attendanceList.indexWhere((a) => a.id == attendance.id);
    if (index != -1) {
      attendanceList[index] = attendance;
      await saveAttendance(attendanceList);
    }
  }

  Future<List<Attendance>> getAttendanceForWorker(String workerId) async {
    final attendanceList = await getAttendance();
    return attendanceList.where((a) => a.workerId == workerId).toList();
  }

  Future<List<Attendance>> getAttendanceForDate(DateTime date) async {
    final attendanceList = await getAttendance();
    return attendanceList.where((a) => 
      a.date.year == date.year &&
      a.date.month == date.month &&
      a.date.day == date.day
    ).toList();
  }

  Future<List<Attendance>> getAttendanceForMonth(int month, int year) async {
    final attendanceList = await getAttendance();
    return attendanceList.where((a) => 
      a.date.month == month && a.date.year == year
    ).toList();
  }
}