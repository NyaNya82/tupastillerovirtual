import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/alarm.dart';
import '../services/firebase_service.dart';
import '../services/alarm_manager_service.dart';  // CAMBIO: Nuevo import
import 'auth_provider.dart';

// Provider para el servicio de Firebase
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

// Provider para las alarmas del usuario actual
final alarmsProvider = StreamProvider<List<Alarm>>((ref) {
  final auth = ref.watch(authStateProvider);
  final firebaseService = ref.read(firebaseServiceProvider);
  
  return auth.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return firebaseService.getAlarmsStream(user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// Provider para gestionar las operaciones de alarmas
final alarmManagerProvider = Provider<AlarmManager>((ref) {
  final firebaseService = ref.read(firebaseServiceProvider);
  final authState = ref.watch(authStateProvider);
  
  return AlarmManager(
    firebaseService: firebaseService,
    userId: authState.value?.uid,
  );
});

class AlarmManager {
  final FirebaseService firebaseService;
  final String? userId;

  AlarmManager({
    required this.firebaseService,
    required this.userId,
  });

  // Crear nueva alarma
  Future<void> createAlarm(Alarm alarm) async {
    if (userId == null) throw Exception('Usuario no autenticado');
    
    await firebaseService.createAlarm(userId!, alarm);
    await AlarmManagerService.scheduleAlarm(alarm);  // CAMBIO: AlarmManagerService
  }

  // Actualizar alarma
  Future<void> updateAlarm(Alarm alarm) async {
    if (userId == null) throw Exception('Usuario no autenticado');
    
    await firebaseService.updateAlarm(userId!, alarm);
    
    // Cancelar alarma anterior
    await AlarmManagerService.cancelAlarm(alarm.id);  // CAMBIO: AlarmManagerService
    
    // Programar nueva si está habilitada
    if (alarm.enabled) {
      await AlarmManagerService.scheduleAlarm(alarm);  // CAMBIO: AlarmManagerService
    }
  }

  // Eliminar alarma
  Future<void> deleteAlarm(String alarmId) async {
    if (userId == null) throw Exception('Usuario no autenticado');
    
    await firebaseService.deleteAlarm(userId!, alarmId);
    await AlarmManagerService.cancelAlarm(alarmId);  // CAMBIO: AlarmManagerService
  }

  // Alternar habilitación de alarma
  Future<void> toggleAlarm(Alarm alarm) async {
    final updatedAlarm = alarm.copyWith(enabled: !alarm.enabled);
    await updateAlarm(updatedAlarm);
  }
}