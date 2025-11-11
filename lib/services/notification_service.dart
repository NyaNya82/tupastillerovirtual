import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart'; // para enviar comando al HC-05

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// 🔹 Inicializa el sistema de notificaciones
  static Future<void> initialize() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Argentina/Buenos_Aires'));
    print('🌍 Timezone configurada: ${tz.local.name}');

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) async {
        final payload = response.payload;
        print('🔔 Notificación tocada: $payload');

        if (payload != null && payload.startsWith('ALARM:')) {
          final compartmentId = int.tryParse(payload.split(':')[1]) ?? -1;

          if (compartmentId >= 0) {
            // Espera breve para que la app se estabilice
            await Future.delayed(const Duration(seconds: 2));
            print('📡 Enviando comando Bluetooth: ALARM:$compartmentId');

            try {
              await BluetoothService.sendCommand('ALARM:$compartmentId')
                  .timeout(const Duration(seconds: 15));
              print('✅ Comando enviado correctamente al HC-05');
            } on TimeoutException {
              print('❌ Timeout: No se pudo enviar el comando en 15 segundos');
            } catch (e) {
              print('❌ Error al enviar comando Bluetooth: $e');
            }
          } else {
            print('⚠️ Payload inválido: $payload');
          }
        }
      },
    );

    await _requestPermissions();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'alarm_channel',
      'Alarmas',
      description: 'Canal para notificaciones de alarmas',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      sound: RawResourceAndroidNotificationSound('alarm'),
    );

    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(channel);

    print('✅ Notificaciones inicializadas correctamente');
  }

  /// 🔐 Solicitar permisos
  static Future<void> _requestPermissions() async {
    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    final notificationStatus = await Permission.notification.request();
    print('📱 Permiso notificaciones: $notificationStatus');

    try {
      final exactAlarmGranted =
          await androidPlugin?.requestExactAlarmsPermission();
      print('⏰ Permiso alarmas exactas: $exactAlarmGranted');
    } catch (e) {
      print('⚠️ Error al solicitar permiso de alarmas exactas: $e');
    }

    await androidPlugin?.requestNotificationsPermission();
  }

  /// ⏰ Programar una alarma
  static Future<void> scheduleNotification({
    required int id,
    required String name,
    required DateTime time,
    required int compartment,
    required bool repeat,
  }) async {
    print('=== PROGRAMANDO ALARMA ===');
    print('ID: $id');
    print('Nombre: $name');
    print('Hora: $time');
    print('Repetir: $repeat');
    print('Compartimento: $compartment');
    print('Hora local actual: ${tz.TZDateTime.now(tz.local)}');

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
      autoCancel: false,
      ongoing: false,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
      0,
    );

    final nextDate = scheduledDate.isAfter(now)
        ? scheduledDate
        : scheduledDate.add(const Duration(days: 1));

    await _notifications.zonedSchedule(
      id,
      name,
      'Compartimento $compartment',
      nextDate,
      notificationDetails,
      payload: 'ALARM:$compartment', // 👈 payload agregado
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents:
          repeat ? DateTimeComponents.time : null, // Repetitiva o única
    );

    print('✅ Alarma programada para: $nextDate');
  }

  /// 🔊 Test de notificación
  static Future<void> testNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Alarmas',
      channelDescription: 'Prueba de sonido',
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
      'Prueba de notificación y sonido 🎶',
      notificationDetails,
      payload: 'ALARM:0', // también con payload para probar Bluetooth
    );

    print('✅ Notificación de prueba enviada correctamente.');
  }

  /// ❌ Cancelar una alarma
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    print('🗑️ Alarma cancelada con ID: $id');
  }

  /// 🗑️ Cancelar todas las alarmas
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print('🗑️ Todas las alarmas canceladas');
  }

  /// 📋 Obtener notificaciones pendientes
  static Future<List<PendingNotificationRequest>>
      getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}