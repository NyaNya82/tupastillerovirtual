import 'package:uuid/uuid.dart';

class Alarm {
  final String id;
  final String name;
  final DateTime time;
  final bool enabled;
  final int compartment;
  final List<String> repeat;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Alarm({
    required this.id,
    required this.name,
    required this.time,
    required this.enabled,
    required this.compartment,
    required this.repeat,
    required this.createdAt,
    required this.updatedAt,
  });

  // Crear nueva alarma
  factory Alarm.create({
    required String name,
    required DateTime time,
    required int compartment,
    List<String> repeat = const [],
  }) {
    final now = DateTime.now();
    return Alarm(
      id: const Uuid().v4(),
      name: name,
      time: time,
      enabled: true,
      compartment: compartment,
      repeat: repeat,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Desde Firestore
  factory Alarm.fromMap(Map<String, dynamic> map) {
    return Alarm(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      time: DateTime.parse(map['time']),
      enabled: map['enabled'] ?? true,
      compartment: map['compartment'] ?? 1,
      repeat: List<String>.from(map['repeat'] ?? []),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  // Hacia Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'time': time.toIso8601String(),
      'enabled': enabled,
      'compartment': compartment,
      'repeat': repeat,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  // Copiar con cambios
  Alarm copyWith({
    String? name,
    DateTime? time,
    bool? enabled,
    int? compartment,
    List<String>? repeat,
  }) {
    return Alarm(
      id: id,
      name: name ?? this.name,
      time: time ?? this.time,
      enabled: enabled ?? this.enabled,
      compartment: compartment ?? this.compartment,
      repeat: repeat ?? this.repeat,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Formatear hora
  String get formattedTime {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Días de la semana formateados
  String get formattedRepeat {
    if (repeat.isEmpty) return 'Una vez';
    
    const dayNames = {
      'mon': 'L',
      'tue': 'M',
      'wed': 'X',
      'thu': 'J',
      'fri': 'V',
      'sat': 'S',
      'sun': 'D',
    };
    
    return repeat.map((day) => dayNames[day] ?? day).join(', ');
  }
}