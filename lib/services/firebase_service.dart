import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/alarm.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener referencia a la colección de alarmas del usuario
  CollectionReference _getAlarmsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('alarms');
  }

  // Stream de alarmas del usuario
  Stream<List<Alarm>> getAlarmsStream(String userId) {
    return _getAlarmsCollection(userId)
        .orderBy('time')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Alarm.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Crear alarma
  Future<void> createAlarm(String userId, Alarm alarm) async {
    await _getAlarmsCollection(userId).doc(alarm.id).set(alarm.toMap());
  }

  // Actualizar alarma
  Future<void> updateAlarm(String userId, Alarm alarm) async {
    await _getAlarmsCollection(userId).doc(alarm.id).update(alarm.toMap());
  }

  // Eliminar alarma
  Future<void> deleteAlarm(String userId, String alarmId) async {
    await _getAlarmsCollection(userId).doc(alarmId).delete();
  }

  // Obtener una alarma específica
  Future<Alarm?> getAlarm(String userId, String alarmId) async {
    final doc = await _getAlarmsCollection(userId).doc(alarmId).get();
    if (doc.exists) {
      return Alarm.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }
}