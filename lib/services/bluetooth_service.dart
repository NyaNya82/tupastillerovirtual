import 'dart:async';
import 'dart:convert';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothService {
  static final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  static BluetoothConnection? _connection;
  static BluetoothDevice? _device;

  static Future<void> initialize() async {
    // Asegura que Bluetooth esté activado
    bool? isEnabled = await _bluetooth.isEnabled;
    if (isEnabled == false) {
      await _bluetooth.requestEnable();
    }
  }

  /// Escanea y conecta automáticamente a un HC-05 emparejado
  static Future<bool> connectToPillDispenser() async {
    try {
      print('🔍 Buscando dispositivos emparejados...');
      List<BluetoothDevice> devices = await _bluetooth.getBondedDevices();

      for (var d in devices) {
        if (d.name?.contains('HC-05') ?? false) {
          print('✅ Dispositivo encontrado: ${d.name}');
          _device = d;

          // Conectar con timeout de 10 segundos
          _connection = await BluetoothConnection.toAddress(d.address)
              .timeout(const Duration(seconds: 10));
          print('🔗 Conectado a ${d.name}');
          return true;
        }
      }

      print('⚠️ No se encontró el HC-05 emparejado.');
      return false;
    } catch (e) {
      print('🚨 Error conectando al HC-05: $e');
      return false;
    }
  }

  /// Envía un comando de texto al HC-05
  static Future<void> sendCommand(String command) async {
    try {
      if (_connection == null || !_connection!.isConnected) {
        print('⚠️ Sin conexión activa. Intentando reconectar...');
        await connectToPillDispenser();
      }

      if (_connection != null && _connection!.isConnected) {
        _connection!.output.add(utf8.encode(command + "\n"));
        await _connection!.output.allSent.timeout(const Duration(seconds: 5));
        print('📤 Enviado: $command');
      } else {
        print('❌ No se pudo enviar, sin conexión.');
      }
    } catch (e) {
      print('🚨 Error enviando comando: $e');
    }
  }

  static Future<void> disconnect() async {
    try {
      await _connection?.close();
      _connection = null;
      print('🔌 Desconectado del HC-05');
    } catch (e) {
      print('⚠️ Error al desconectar: $e');
    }
  }
}
