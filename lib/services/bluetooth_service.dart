import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothService {
  static final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  static BluetoothConnection? _connection;
  static BluetoothDevice? _device;

  /// Inicializa desde el primer plano (permite solicitar activación)
  static Future<void> initializeFromForeground() async {
    bool? isEnabled = await _bluetooth.isEnabled;
    if (isEnabled == false) {
      await _bluetooth.requestEnable();
    }
  }

  /// Inicializa desde un isolate en background (no debe solicitar activación)
  static Future<void> initializeFromBackground() async {
    bool? isEnabled = await _bluetooth.isEnabled;
    if (isEnabled == false) {
      throw PlatformException(
        code: 'bluetooth_unavailable',
        message: 'Bluetooth is not enabled for background task.',
      );
    }
  }

  /// Escanea y conecta automáticamente a un HC-05 emparejado
  static Future<bool> connectToPillDispenser() async {
    try {
      print('🔍 Buscando dispositivos emparejados...');
      List<BluetoothDevice> devices = await _bluetooth.getBondedDevices();

      _device = devices.firstWhere(
        (d) => d.name?.contains('HC-05') ?? false,
        orElse: () => throw Exception('No se encontró el HC-05 emparejado'),
      );

      print('✅ Dispositivo encontrado: ${_device!.name}');

      _connection = await BluetoothConnection.toAddress(_device!.address)
          .timeout(const Duration(seconds: 10));

      print('🔗 Conectado a ${_device!.name}');
      return true;

    } on TimeoutException {
      print('🚨 Timeout: No se pudo conectar en 10 segundos.');
      return false;
    } catch (e) {
      print('🚨 Error conectando al HC-05: $e');
      return false;
    }
  }

  /// Envía un comando de texto al HC-05 con reintentos
  static Future<void> sendCommand(String command) async {
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        if (_connection == null || !_connection!.isConnected) {
          print('⚠️ Sin conexión (Intento $attempt/$maxRetries). Reconectando...');
          await connectToPillDispenser();
        }

        if (_connection != null && _connection!.isConnected) {
          _connection!.output.add(utf8.encode(command + "\n"));
          await _connection!.output.allSent.timeout(const Duration(seconds: 5));
          print('📤 Enviado: $command');
          return; // Comando enviado con éxito
        }
      } on TimeoutException {
        print('🚨 Timeout en intento $attempt/$maxRetries: El envío tardó más de 5 segundos.');
        await disconnect(); // Forzar desconexión para un reintento limpio
      } catch (e) {
        print('🚨 Error en intento $attempt/$maxRetries: $e');
        await disconnect(); // Cerrar conexión para reintentar
      }

      if (attempt < maxRetries) {
        await Future.delayed(retryDelay);
      }
    }

    print('❌ No se pudo enviar el comando después de $maxRetries intentos.');
    throw Exception('Failed to send command after $maxRetries retries');
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
