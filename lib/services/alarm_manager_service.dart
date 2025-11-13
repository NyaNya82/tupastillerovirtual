import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/alarm.dart';
import 'bluetooth_service.dart'; // Asegúrate de que la ruta sea correcta

@pragma('vm:entry-point')
Future<void> alarmCallback(int id, Map<String, dynamic> params) async {
  print('🔔 Alarma sonando en background - ID: $id');

  // Esencial para que los plugins funcionen en background
  final RootIsolateToken? token = RootIsolateToken.instance;
  if (token != null) {
    BackgroundIsolateBinaryMessenger.ensureInitialized(token);
  }

  // Inicializar notificaciones
  final notifications = FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initializationSettings = InitializationSettings(android: androidSettings);
  await notifications.initialize(initializationSettings);

  // Mostrar notificación
  final notificationDetails = AndroidNotificationDetails(
    'alarm_channel',
    'Alarmas',
    channelDescription: 'Notificaciones de alarmas',
    importance: Importance.max,
    priority: Priority.high,
    sound: const RawResourceAndroidNotificationSound('alarm'),
    playSound: true,
    fullScreenIntent: true,
    category: AndroidNotificationCategory.alarm,
  );

  await notifications.show(
    id,
    params['name'] as String,
    'Compartimento ${params['compartment']}',
    NotificationDetails(android: notificationDetails),
    payload: 'ALARM:${params['compartment']}',
  );

  // Enviar comando Bluetooth
  try {
    print('📡 Inicializando Bluetooth en background...');
    await BluetoothService.initializeFromBackground();
    final command = 'ALARM:${params['compartment']}';
    print('🔧 Enviando comando: $command');
    await BluetoothService.sendCommand(command);
    print('✅ Comando Bluetooth enviado desde el background');
  } on PlatformException catch (e) {
    if (e.code == 'bluetooth_unavailable') {
      print('❌ Error: El Bluetooth no estaba activado para la tarea en background.');
      // Aquí se podría mostrar una notificación al usuario indicando el problema.
    } else {
      print('❌ Error de plataforma al enviar comando Bluetooth: ${e.message}');
    }
  } catch (e) {
    print('❌ Error inesperado al enviar comando Bluetooth: $e');
  }
}

class AlarmManagerService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Inicialización general
  static Future<void> initialize() async {
    await AndroidAlarmManager.initialize();

    // Inicializar notificaciones
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: androidSettings);
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
        alarmCallback,
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
        alarmCallback,
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