

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'screens/registration_screen.dart';
import 'screens/ble_scan_screen.dart';
import 'screens/local_auth_screen.dart';
import 'services/ble_controller.dart';
import 'screens/main_chat_screen.dart';

class MedicalProfileScreen extends StatefulWidget {
  const MedicalProfileScreen({super.key});

  @override
  State<MedicalProfileScreen> createState() => _MedicalProfileScreenState();
}

class _MedicalProfileScreenState extends State<MedicalProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Placeholder for MedicalProfileScreen')),
    );
  }
}

class MainChatScreen extends StatelessWidget {
  const MainChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Main Application Screen')),
    );
  }
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BleController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lumos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF141318),
        primaryColor: Colors.cyan,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white),
          titleSmall: TextStyle(color: Colors.white),
          displayLarge: TextStyle(color: Colors.white),
          displayMedium: TextStyle(color: Colors.white),
          displaySmall: TextStyle(color: Colors.white),
          headlineMedium: TextStyle(color: Colors.white),
          headlineSmall: TextStyle(color: Colors.white),
          labelLarge: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: Colors.white),
          labelSmall: TextStyle(color: Colors.white),
        ),
        fontFamily: 'Roboto',
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Colors.cyanAccent,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyan,
            foregroundColor: Colors.black,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.cyan)
            .copyWith(
          secondary: Colors.cyanAccent,
          onBackground: Colors.white,
          surface: const Color(0xFF1F1F1F),
        ),
      ),

      home: const LocalAuthScreen(),

      routes: {
        '/registration': (context) => const MedicalProfileScreen(),
        '/scan': (context) => const BleScanScreen(),
        '/main': (context) => const MainChatScreen(),
      },
    );
  }
}