class AppConstants {
  // Firestore Collections
  static const String usersCollection = 'users';
  static const String alarmsCollection = 'alarms';
  
  // Notification
  static const String notificationChannelId = 'alarm_channel';
  static const String notificationChannelName = 'Alarmas';
  static const String notificationChannelDescription = 'Notificaciones de alarmas de medicamentos';
  
  // Limits
  static const int maxAlarms = 8;
  static const int maxNameLength = 50;
  
  // Days of week
  static const Map<String, String> dayNames = {
    'mon': 'Lunes',
    'tue': 'Martes', 
    'wed': 'Miércoles',
    'thu': 'Jueves',
    'fri': 'Viernes',
    'sat': 'Sábado',
    'sun': 'Domingo',
  };
  
  static const Map<String, String> dayShortNames = {
    'mon': 'L',
    'tue': 'M',
    'wed': 'X', 
    'thu': 'J',
    'fri': 'V',
    'sat': 'S',
    'sun': 'D',
  };
}