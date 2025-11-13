import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

// State Notifier para el estado de Bluetooth
class BluetoothStateNotifier extends StateNotifier<BluetoothState> {
  BluetoothStateNotifier() : super(BluetoothState.UNKNOWN) {
    _init();
  }

  void _init() {
    FlutterBluetoothSerial.instance.state.then((state) {
      this.state = state;
    });

    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      this.state = state;
    });
  }
}

// Provider para acceder al estado de Bluetooth
final bluetoothStateProvider =
    StateNotifierProvider<BluetoothStateNotifier, BluetoothState>(
  (ref) => BluetoothStateNotifier(),
);
