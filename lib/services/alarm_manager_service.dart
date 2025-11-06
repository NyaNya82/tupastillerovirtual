import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/alarm.dart';
import 'bluetooth_service.dart';

class AlarmManagerService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Inicialización general
  static Future<void> initialize() async {
    await AndroidAlarmManager.initialize();

    // Inicializar notificaciones
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings =
        InitializationSettings(android: androidSettings);
    await _notifications.initialize(initializationSettings);

    // Crear canal de notificación
    const channel = AndroidNotificationChannel(
      'alarm_channel',
      'Alarmas',
      description: 'Notificaciones de alarmas',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alarm'),
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Intentar conexión Bluetooth (opcional)
    await BluetoothService.connectToPillDispenser();
  }

  /// 🔔 Callback: se ejecuta cuando suena la alarma
  @pragma('vm:entry-point')
  static Future<void> alarmCallback(int id, Map<String, dynamic> params) async {
    print('🔔 Alarma sonando - ID: $id');

    // Inicializar notificaciones dentro del isolate
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings =
        InitializationSettings(android: androidSettings);
    final notifications = FlutterLocalNotificationsPlugin();
    await notifications.initialize(initializationSettings);

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

    // Mostrar notificación local
    await notifications.show(
      id,
      params['name'] as String,
      'Compartimento ${params['compartment']}',
      NotificationDetails(android: notificationDetails),
    );

    // Enviar comando al dispensador físico
    final comp = params['compartment'];
    await BluetoothService.sendCommand('ALARM:$comp');
  }

  /// ⏰ Programar una alarma
  static Future<void> scheduleAlarm(Alarm alarm) async {
    if (!alarm.enabled) {
      print('❌ Alarma deshabilitada: ${alarm.name}');
      return;
    }

    final now = DateTime.now();
    DateTime scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      alarm.time.hour,
      alarm.time.minute,
    );

    // Si la hora ya pasó hoy, programar para mañana
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    final params = {
      'name': alarm.name,
      'compartment': alarm.compartment,
      'alarmId': alarm.id,
    };

    // Si no se repite (una sola vez)
    if (alarm.repeat.isEmpty) {
      await AndroidAlarmManager.oneShotAt(
        scheduledTime,
        alarm.id.hashCode,
        AlarmManagerService.alarmCallback, // 👈 se referencia correctamente
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        params: params,
      );
    } else {
      // Si es una alarma repetitiva
      await AndroidAlarmManager.periodic(
        const Duration(days: 1),
        alarm.id.hashCode,
        AlarmManagerService.alarmCallback, // 👈 igual acá
        startAt: scheduledTime,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        params: params,
      );
    }

    print('✅ Alarma programada para ${alarm.name} a las ${alarm.time}');
  }

  /// ❌ Cancelar una alarma específica
  static Future<void> cancelAlarm(String alarmId) async {
    print('🗑️ Cancelando alarma: $alarmId');
    await AndroidAlarmManager.cancel(alarmId.hashCode);
  }
}