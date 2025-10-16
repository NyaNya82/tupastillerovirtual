import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../models/alarm.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// 🔹 Inicializa el sistema de notificaciones
  static Future<void> initialize() async {
    // ⚠️ CRÍTICO: Inicializar timezone database PRIMERO
    tz.initializeTimeZones();
    // Configurar zona horaria local (Argentina)
    tz.setLocalLocation(tz.getLocation('America/Argentina/Buenos_Aires'));
    
    print('🌍 Timezone configurada: ${tz.local.name}');

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    // Inicializa el plugin con callback para taps
    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // 🔸 Solicitar permisos ANTES de crear canales
    await _requestPermissions();

    // 🔸 Crear canal de notificación de alarmas
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'alarm_channel',
      'Alarmas',
      description: 'Canal para notificaciones de alarmas',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      sound: RawResourceAndroidNotificationSound('alarm'), // alarm.wav/mp3 en android/app/src/main/res/raw/
    );

    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(channel);

    print('✅ Notificaciones inicializadas correctamente');
  }

  /// 🔐 Solicitar todos los permisos necesarios
  static Future<void> _requestPermissions() async {
    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // 1. Permiso de notificaciones (Android 13+)
    final notificationStatus = await Permission.notification.request();
    print('📱 Permiso notificaciones: $notificationStatus');

    if (notificationStatus.isDenied) {
      print('⚠️ Permiso de notificaciones denegado');
    }

    // 2. Permiso de alarmas exactas (Android 12+)
    try {
      final exactAlarmGranted = 
          await androidPlugin?.requestExactAlarmsPermission();
      print('⏰ Permiso alarmas exactas: $exactAlarmGranted');
      
      if (exactAlarmGranted == false) {
        print('⚠️ Las alarmas exactas no están permitidas. Pueden no sonar a tiempo.');
      }
    } catch (e) {
      print('⚠️ Error al solicitar permiso de alarmas exactas: $e');
    }

    // 3. Permiso para programar alarmas mientras duerme
    await androidPlugin?.requestNotificationsPermission();
  }

  /// 🔔 Callback cuando se toca una notificación
  static void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Notificación tocada: ${response.payload}');
    // Aquí puedes navegar a una pantalla específica si lo necesitas
  }

  /// ⏰ Programar una alarma
  static Future<void> scheduleNotification(Alarm alarm) async {
    print('=== PROGRAMANDO ALARMA ===');
    print('ID: ${alarm.id}');
    print('Nombre: ${alarm.name}');
    print('Hora: ${alarm.time}');
    print('Repetir: ${alarm.repeat}');
    print('Compartimento: ${alarm.compartment}');
    print('Hora local actual: ${tz.TZDateTime.now(tz.local)}');

    if (!alarm.enabled) {
      print('❌ Alarma deshabilitada, cancelando notificaciones.');
      await cancelNotification(alarm.id.hashCode);
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Alarmas',
      channelDescription: 'Notificaciones de alarmas',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('alarm'),
      playSound: true,
      enableVibration: true,
      enableLights: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      // Configuración adicional para que se muestre sobre lockscreen
      autoCancel: false,
      ongoing: false,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    final now = tz.TZDateTime.now(tz.local);
    
    // Crear la fecha programada en la zona horaria local
    final scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      alarm.time.hour,
      alarm.time.minute,
      0,
    );

    print('📅 Fecha programada inicial: $scheduledDate');
    print('⏰ Hora actual: $now');

    if (alarm.repeat.isEmpty) {
      // Alarma única
      final nextDate = scheduledDate.isAfter(now)
          ? scheduledDate
          : scheduledDate.add(const Duration(days: 1));

      print('📆 Próxima alarma única: $nextDate');

      await _notifications.zonedSchedule(
        alarm.id.hashCode,
        alarm.name,
        'Compartimento ${alarm.compartment}',
        nextDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      print('✅ Alarma única programada para: $nextDate');
      print('⏱️ En ${nextDate.difference(now).inMinutes} minutos');
    } else {
      // Alarmas repetitivas
      for (final day in alarm.repeat) {
        final weekday = _getDayIndex(day);
        final nextDate = _nextInstanceOfWeekday(weekday, alarm.time);

        print('📆 Próxima alarma $day: $nextDate (en ${nextDate.difference(now).inHours}h)');

        await _notifications.zonedSchedule(
          '${alarm.id}_$day'.hashCode,
          alarm.name,
          'Compartimento ${alarm.compartment}',
          nextDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );

        print('✅ Alarma programada para $day ($weekday): $nextDate');
      }
    }

    print('=== FIN PROGRAMACIÓN ===\n');
  }

  /// 🔊 Test de notificación inmediata
  static Future<void> testNotification() async {
    print('🧪 Enviando notificación de prueba...');
    
    const androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Alarmas',
      channelDescription: 'Prueba de sonido y notificación',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('alarm'),
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      999,
      'Test Alarm',
      'Si ves y escuchas esto, las notificaciones funcionan 🎶',
      notificationDetails,
    );

    print('✅ Notificación de prueba enviada correctamente.');
  }

  /// ❌ Cancelar una alarma
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    
    // Cancelar también las versiones con días de la semana
    final days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    for (final day in days) {
      await _notifications.cancel('${id}_$day'.hashCode);
    }
    
    print('🗑️ Alarma cancelada con ID: $id (y todas sus repeticiones)');
  }

  /// 🗑️ Cancelar todas las alarmas
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print('🗑️ Todas las alarmas canceladas');
  }

  /// 📋 Obtener alarmas pendientes (para debug)
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// 🔁 Obtener índice del día (para repetición)
  static int _getDayIndex(String day) {
    const map = {
      'mon': DateTime.monday,
      'tue': DateTime.tuesday,
      'wed': DateTime.wednesday,
      'thu': DateTime.thursday,
      'fri': DateTime.friday,
      'sat': DateTime.saturday,
      'sun': DateTime.sunday,
    };
    return map[day] ?? DateTime.monday;
  }

  /// 📆 Obtener próxima ocurrencia del día
  static tz.TZDateTime _nextInstanceOfWeekday(int weekday, DateTime time) {
    final now = tz.TZDateTime.now(tz.local);
    
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
      0,
    );

    // Avanzar hasta el día de la semana correcto
    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Si ya pasó hoy, programar para la próxima semana
    if (scheduledDate.isBefore(now) || scheduledDate.isAtSameMomentAs(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    return scheduledDate;
  }
}