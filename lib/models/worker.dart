class Worker {
  final String id;
  final String name;
  final String employeeId;
  final String department;
  final String position;
  final String phoneNumber;
  final DateTime createdAt;

  Worker({
    required this.id,
    required this.name,
    required this.employeeId,
    required this.department,
    required this.position,
    required this.phoneNumber,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'employeeId': employeeId,
    'department': department,
    'position': position,
    'phoneNumber': phoneNumber,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Worker.fromJson(Map<String, dynamic> json) => Worker(
    id: json['id'],
    name: json['name'],
    employeeId: json['employeeId'],
    department: json['department'],
    position: json['position'],
    phoneNumber: json['phoneNumber'],
    createdAt: DateTime.parse(json['createdAt']),
  );

  Worker copyWith({
    String? id,
    String? name,
    String? employeeId,
    String? department,
    String? position,
    String? phoneNumber,
    DateTime? createdAt,
  }) => Worker(
    id: id ?? this.id,
    name: name ?? this.name,
    employeeId: employeeId ?? this.employeeId,
    department: department ?? this.department,
    position: position ?? this.position,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    createdAt: createdAt ?? this.createdAt,
  );
}