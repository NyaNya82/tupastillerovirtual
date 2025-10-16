// Servicio opcional para analytics
class AnalyticsService {
  static void logAlarmCreated() {
    print('Analytics: Alarm created');
    // Implementar Firebase Analytics si es necesario
  }
  
  static void logAlarmDeleted() {
    print('Analytics: Alarm deleted');
  }
  
  static void logAlarmToggled(bool enabled) {
    print('Analytics: Alarm toggled to $enabled');
  }
  
  static void logUserSignIn() {
    print('Analytics: User signed in');
  }
  
  static void logUserSignOut() {
    print('Analytics: User signed out');
  }
}