import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/alarm.dart';

// Callback que se ejecuta cuando suena la alarma (FUNCIÓN TOP-LEVEL)
@pragma('vm:entry-point')
void alarmCallback(int id, Map<String, dynamic> params) async {
  print('Alarma sonando - ID: $id');

  final notifications = FlutterLocalNotificationsPlugin();

  // Inicializar notificaciones para el isolate de background
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initializationSettings = InitializationSettings(android: androidSettings);
  await notifications.initialize(initializationSettings);

  // Crear canal (es seguro llamarlo múltiples veces)
  const channel = AndroidNotificationChannel(
    'alarm_channel',
    'Alarmas',
    description: 'Notificaciones de alarmas',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('alarm'),
  );
  await notifications
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  final notificationDetails = AndroidNotificationDetails(
    'alarm_channel',
    'Alarmas',
    channelDescription: 'Notificaciones de alarmas',
    importance: Importance.max,
    priority: Priority.high,
    sound: const RawResourceAndroidNotificationSound('alarm'),
    playSound: true,
    enableVibration: true,
    fullScreenIntent: true,
    category: AndroidNotificationCategory.alarm,
  );

  await notifications.show(
    id,
    params['name'] as String,
    'Compartimento ${params['compartment']}',
    NotificationDetails(android: notificationDetails),
  );
}

class AlarmManagerService {
  // Ya no se necesita una instancia de notificaciones aquí para el callback
  // static final FlutterLocalNotificationsPlugin _notifications =
  //     FlutterLocalNotificationsPlugin();

  // Inicializar el servicio
  static Future<void> initialize() async {
    await AndroidAlarmManager.initialize();

    // La inicialización de notificaciones y canal se hará en el callback
    // y en el servicio de notificaciones principal.
  }

  // Programar alarma
  static Future<void> scheduleAlarm(Alarm alarm) async {
    if (!alarm.enabled) {
      print('Alarma deshabilitada: ${alarm.name}');
      return;
    }

    print('=== PROGRAMANDO ALARMA CON ALARM MANAGER ===');
    print('Nombre: ${alarm.name}');
    print('Hora: ${alarm.time}');
    print('Repetir: ${alarm.repeat}');

    final now = DateTime.now();
    DateTime scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      alarm.time.hour,
      alarm.time.minute,
    );

    // Si ya pasó hoy, programar para mañana
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    final params = {
      'name': alarm.name,
      'compartment': alarm.compartment,
      'alarmId': alarm.id,
    };

    if (alarm.repeat.isEmpty) {
      // Alarma única
      print('Programando alarma única para: $scheduledTime');

      await AndroidAlarmManager.oneShotAt(
        scheduledTime,
        alarm.id.hashCode,
        alarmCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        params: params,
      );

      print('Alarma única programada exitosamente');
    } else {
      // Alarma periódica (diaria a la misma hora)
      print('Programando alarma periódica cada 24 horas desde: $scheduledTime');

      // Primero cancela cualquier alarma existente
      await AndroidAlarmManager.cancel(alarm.id.hashCode);

      // Programa la alarma periódica
      await AndroidAlarmManager.periodic(
        const Duration(days: 1),
        alarm.id.hashCode,
        alarmCallback,
        startAt: scheduledTime,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        params: params,
      );

      print('Alarma periódica programada exitosamente');
    }

    print('=== FIN PROGRAMACIÓN ===');
  }

  // Cancelar alarma
  static Future<void> cancelAlarm(String alarmId) async {
    print('Cancelando alarma: $alarmId');
    await AndroidAlarmManager.cancel(alarmId.hashCode);
  }

  // Cancelar todas las alarmas
  static Future<void> cancelAllAlarms() async {
    print('Cancelando todas las alarmas');
    // Nota: android_alarm_manager_plus no tiene método para cancelar todas
    // Necesitarías mantener track de los IDs y cancelar uno por uno
  }
}