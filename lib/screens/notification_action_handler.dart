// lib/screens/notification_action_handler.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';

class NotificationActionHandler extends StatefulWidget {
  final String? payload;
  const NotificationActionHandler({Key? key, this.payload}) : super(key: key);

  @override
  State<NotificationActionHandler> createState() =>
      _NotificationActionHandlerState();
}

class _NotificationActionHandlerState extends State<NotificationActionHandler> {
  @override
  void initState() {
    super.initState();
    _handlePayload();
  }

  Future<void> _handlePayload() async {
    try {
      // payload esperado: JSON con { "compartment": X, ... } o "X"
      final payload = widget.payload;
      int? compartment;
      if (payload == null) {
        compartment = null;
      } else {
        try {
          final decoded = json.decode(payload);
          if (decoded is Map && decoded['compartment'] != null) {
            compartment = int.tryParse(decoded['compartment'].toString());
          }
        } catch (_) {
          // payload no es JSON, intentar parse simple
          compartment = int.tryParse(payload);
        }
      }

      // Asegurarnos de conectar y enviar comando
      await BluetoothService.connectToPillDispenser(); // intenta conectar si no lo está
      if (compartment != null) {
        await BluetoothService.sendCommand('ALARM:$compartment');
      } else {
        // si no viene compartimento, mandar un comando genérico o loggear
        await BluetoothService.sendCommand('ALARM:0');
      }
    } catch (e) {
      // no romper la UI — solo log
      debugPrint('NotificationActionHandler error: $e');
    } finally {
      // Cerrar la pantalla tras un pequeño retraso para que el usuario ni note
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // pantalla mínima (puede verse un parpadeo muy breve)
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(child: SizedBox.shrink()),
    );
  }
}