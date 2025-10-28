import 'dart:isolate';
import 'dart:ui';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/alarm.dart';
import 'notification_service.dart';

class AlarmManagerService {
  /// Inicializa el AlarmManager (debe llamarse en main.dart)
  static Future<void> initialize() async {
    await AndroidAlarmManager.initialize();
    print('✅ AlarmManager inicializado correctamente');
  }

  /// Programa una alarma con AlarmManager
  static Future<void> scheduleAlarm(Alarm alarm) async {
    final now = tz.TZDateTime.now(tz.local);
    final target = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      alarm.time.hour,
      alarm.time.minute,
    );

    final nextTime = target.isBefore(now)
        ? target.add(const Duration(days: 1))
        : target;

    print('🕐 Programando alarma con AlarmManager para: $nextTime');

    await AndroidAlarmManager.oneShotAt(
      nextTime,
      alarm.id.hashCode,
      alarmCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      params: {
        'id': alarm.id,
        'name': alarm.name,
        'compartment': alarm.compartment.toString(),
      },
    );
  }

  /// Cancela una alarma por ID
  static Future<void> cancelAlarm(dynamic alarmId) async {
  final int id = alarmId is String ? alarmId.hashCode : alarmId;
  print('🗑️ Cancelando alarma con ID $id');
  await AndroidAlarmManager.cancel(id);
}



  /// Callback que se ejecuta en segundo plano cuando suena la alarma
  static Future<void> alarmCallback(int id, Map<String, dynamic> params) async {
    final name = params['name'];
    final compartment = params['compartment'];

    print('🔔 [CALLBACK] Alarma disparada: $name (ID: $id, Compartimento: $compartment)');
    
    // Muy importante: Inicializar el NotificationService dentro del callback
    await NotificationService.initialize();

    // Mostrar notificación personalizada
    await NotificationService.testNotification();
  }
}