import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'providers/auth_provider.dart';
import 'services/alarm_manager_service.dart';
import 'services/bluetooth_service.dart';
import 'services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/notification_action_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp();

  // Inicializar timezone
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('America/Argentina/Buenos_Aires'));

  // Pedir permisos Bluetooth en runtime
  await [
    Permission.bluetooth,
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.location,
  ].request();

  // Inicializar el Alarm Manager (para manejar procesos en background)
  await AlarmManagerService.initialize();

  // Asegurarse de que el Bluetooth esté activado al iniciar la app
  try {
    await BluetoothService.initializeFromForeground();
    print('✅ Bluetooth inicializado en primer plano.');
  } catch (e) {
    print('⚠️ Error al inicializar Bluetooth en primer plano: $e');
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await NotificationService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Flutter Alarm App',
      navigatorKey: navigatorKey, // 👈 importante
      routes: {
        '/notification-action': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as String?;
          return NotificationActionHandler(payload: args);
        },
      },
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007AFF),
          brightness: Brightness.light,
        ),
        fontFamily: 'Inter',
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.25,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.1,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.25,
          ),
        ),
      ),
      home: authState.when(
        data: (user) => user != null ? const HomeScreen() : const LoginScreen(),
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Scaffold(
          body: Center(
            child: Text('Error: $error'),
          ),
        ),
      ),
    );
  }
}
