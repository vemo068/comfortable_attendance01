enum AttendanceStatus {
  present('حاضر'),
  absent('غائب'),
  late('متأخر'),
  excused('معذور');

  const AttendanceStatus(this.arabicName);
  final String arabicName;
}

class Attendance {
  final String id;
  final String workerId;
  final DateTime date;
  final AttendanceStatus status;
  final String notes;
  final DateTime timestamp;

  Attendance({
    required this.id,
    required this.workerId,
    required this.date,
    required this.status,
    required this.notes,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'workerId': workerId,
    'date': date.toIso8601String(),
    'status': status.index,
    'notes': notes,
    'timestamp': timestamp.toIso8601String(),
  };

  factory Attendance.fromJson(Map<String, dynamic> json) => Attendance(
    id: json['id'],
    workerId: json['workerId'],
    date: DateTime.parse(json['date']),
    status: AttendanceStatus.values[json['status']],
    notes: json['notes'],
    timestamp: DateTime.parse(json['timestamp']),
  );

  Attendance copyWith({
    String? id,
    String? workerId,
    DateTime? date,
    AttendanceStatus? status,
    String? notes,
    DateTime? timestamp,
  }) => Attendance(
    id: id ?? this.id,
    workerId: workerId ?? this.workerId,
    date: date ?? this.date,
    status: status ?? this.status,
    notes: notes ?? this.notes,
    timestamp: timestamp ?? this.timestamp,
  );
}