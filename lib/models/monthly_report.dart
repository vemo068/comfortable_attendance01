class MonthlyReport {
  final String workerId;
  final String workerName;
  final int month;
  final int year;
  final int totalDays;
  final int presentDays;
  final int absentDays;
  final int lateDays;
  final int excusedDays;
  final double attendancePercentage;

  MonthlyReport({
    required this.workerId,
    required this.workerName,
    required this.month,
    required this.year,
    required this.totalDays,
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
    required this.excusedDays,
    required this.attendancePercentage,
  });

  Map<String, dynamic> toJson() => {
    'workerId': workerId,
    'workerName': workerName,
    'month': month,
    'year': year,
    'totalDays': totalDays,
    'presentDays': presentDays,
    'absentDays': absentDays,
    'lateDays': lateDays,
    'excusedDays': excusedDays,
    'attendancePercentage': attendancePercentage,
  };

  factory MonthlyReport.fromJson(Map<String, dynamic> json) => MonthlyReport(
    workerId: json['workerId'],
    workerName: json['workerName'],
    month: json['month'],
    year: json['year'],
    totalDays: json['totalDays'],
    presentDays: json['presentDays'],
    absentDays: json['absentDays'],
    lateDays: json['lateDays'],
    excusedDays: json['excusedDays'],
    attendancePercentage: json['attendancePercentage'],
  );

  String get monthName {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return months[month - 1];
  }
}