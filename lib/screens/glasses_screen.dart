// glasses_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:ui';

// Navigation Imports (MUST be present in the project)
import 'main_chat_screen.dart';
import 'bracelet_screen.dart';
import 'cane_screen.dart';
import 'gesture_config_screen.dart';

// Custom Colors
const Color neonColor = Color(0xFFFFB267); // اللون البرتقالي
const Color darkSurface = Color(0xFF2D2929);
const Color cardColor = Color(0xFF282424);
const Color onBackground = Colors.white;

// **ألوان الخلفية الداكنة الجديدة بناءً على طلبك**
const Color newDarkBackground = Color(0xFF211D1D); // اللون المطلوب (#211D1D)
// لون مشتق لتأمين تدرج سلس
const Color gradientMidColor = Color(0xFF2A2626);


class GlassesScreen extends StatefulWidget {
  const GlassesScreen({super.key});

  @override
  State<GlassesScreen> createState() => _GlassesScreenState();
}

class _GlassesScreenState extends State<GlassesScreen> {
  bool _isConnected = true; // الحالة الأولية للمفتاح
  final String _batteryLevel = '36%';
  final String _timeRemaining = '3h 20m';

  bool _isAwaitingInput = false;
  String _lastSpokenPrompt = '';

  late BleController _bleController;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _bleController = Provider.of<BleController>(context, listen: false);
      _bleController.speak('You are now in the Smart Glasses screen. The battery level is $_batteryLevel with an estimated time remaining of $_timeRemaining. The device is currently ${_isConnected ? 'connected' : 'disconnected'}. Double tap to go back to the home screen. Long press to give a voice command.');
    });
  }

  void _onLongPressStart(BleController bleController) {
    if (_isAwaitingInput || bleController.isListening) return;
    setState(() {
      _isAwaitingInput = true;
    });
    bleController.speak('Recording started. Speak now.');
    bleController.startListening(
      onResult: (spokenText) {
        if (mounted) {
          setState(() {
            _isAwaitingInput = false;
            _lastSpokenPrompt = spokenText;
          });
          if (spokenText.isNotEmpty) {
            _handleCommand(bleController, spokenText);
          } else {
            bleController.speak('Could not recognize your speech. Long press and try again.');
          }
        }
      },
    );
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (_bleController.isListening) {
      _bleController.stopListening(shouldSpeakStop: false);
      _bleController.speak('Recording stopped. Processing command.');
    }
  }

  void _triggerEmergencyCall(BleController bleController) async {
    const url = 'tel:911';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      bleController.speak('Sorry, emergency call cannot be placed.');
    }
  }

  void _goToSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const GestureConfigScreen()),
    );
  }

  void _handleCommand(BleController bleController, String command) async {
    final normalizedCommand = command.toLowerCase().trim();

    void navigateTo(Widget screen, String name) {
      bleController.speak('Navigating to $name screen.');
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => screen));
    }

    if (normalizedCommand.contains('glasses') || normalizedCommand.contains('نظاره')) {
      bleController.speak('You are already on the Glasses screen.');
      return;
    } else if (normalizedCommand.contains('cane') || normalizedCommand.contains('عصا')) {
      navigateTo(const CaneScreen(), 'Cane');
      return;
    } else if (normalizedCommand.contains('bracelet') || normalizedCommand.contains('سوار')) {
      navigateTo(const BraceletScreen(), 'Bracelet');
      return;
    } else if (normalizedCommand.contains('home') || normalizedCommand.contains('رئيسية') || normalizedCommand.contains('main')) {
      bleController.speak('Returning to Home screen.');
      Navigator.of(context).pop();
      return;
    } else if (normalizedCommand.contains('settings') || normalizedCommand.contains('اعدادات')) {
      bleController.speak('Navigating to Settings screen.');
      _goToSettings();
      return;
    } else if (normalizedCommand.contains('emergency') || normalizedCommand.contains('طوارئ') || normalizedCommand.contains('911')) {
      bleController.speak('Initiating emergency call.');
      _triggerEmergencyCall(bleController);
      return;
    }
    bleController.speak('I did not recognize a navigation command. Processing your query now.');
  }

  void _toggleConnection(BleController bleController) {
    setState(() {
      _isConnected = !_isConnected;
    });
    final status = _isConnected ? 'Connected' : 'Disconnected';
    bleController.speak('The connection status for Glasses has been changed to: $status.');
  }

  void _handleDoubleTap(BleController bleController) {
    bleController.speak('Returning to the Home Screen.');
    Navigator.of(context).pop();
  }


  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Consumer<BleController>(
      builder: (context, bleController, child) {
        final chatOverlay = Container(
          color: Colors.black.withOpacity(0.7),
          constraints: const BoxConstraints.expand(),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: darkSurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: neonColor),
                  const SizedBox(height: 20),
                  Text(
                    bleController.isListening
                        ? 'Listening... (Lift finger to send)'
                        : 'Processing your query...',
                    style: const TextStyle(color: onBackground, fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
        );

        return GestureDetector(
          onLongPressStart: (_) => _onLongPressStart(bleController),
          onLongPressEnd: _onLongPressEnd,
          onDoubleTap: () => _handleDoubleTap(bleController),
          child: Scaffold(
            // **تعيين لون الخلفية الأساسي للبني الداكن الجديد**
            backgroundColor: newDarkBackground,
            body: Stack(
              children: [
                // 1. الصورة الخلفية للنظارات (في الجزء العلوي)
                Positioned(
                  top: -60, // تم رفع الصورة وتصغيرها
                  left: 0,
                  right: 0,
                  height: MediaQuery.of(context).size.height * 0.70,
                  child: Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/glasses.jpg'),
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      ),
                    ),
                  ),
                ),

                // 2. التدرج اللوني المموه (Gradient)
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.35,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        // **استخدام الألوان الداكنة الجديدة للتدرج**
                        colors: [
                          newDarkBackground.withOpacity(0.0), // شفاف تماماً
                          gradientMidColor.withOpacity(0.95), // اللون الداكن المتوسط المشتق
                          newDarkBackground, // اللون الداكن الجديد
                        ],
                        stops: const [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                ),

                // 3. Navigation Header (Smart Glasses فقط)
                Positioned(
                  top: 50,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.arrow_back_ios, color: onBackground, size: 24),
                      ),
                      const Text(
                        'Smart Glasses',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: onBackground),
                      ),
                      const Icon(Icons.notifications_none, color: onBackground, size: 24),
                    ],
                  ),
                ),

                // 4. كارد البطارية والتحكم (Box)
                Positioned(
                  top: 388.0 - (screenHeight - MediaQuery.of(context).size.height.floor()),
                  left: (MediaQuery.of(context).size.width - 272.0) / 2,
                  child: Container(
                    width: 272.0,
                    height: 267.0,
                    padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 30.0),
                    decoration: BoxDecoration(
                      color: cardColor.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(33.0),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // البطارية
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _batteryLevel,
                              textAlign: TextAlign.left,
                              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: onBackground),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Estimated time remaining: $_timeRemaining',
                              textAlign: TextAlign.left,
                              style: TextStyle(fontSize: 14, color: onBackground.withOpacity(0.8)),
                            ),
                            const SizedBox(height: 25),
                          ],
                        ),

                        // مفتاح الاتصال
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // عرض كلمة "On" أو "Off"
                                Text(
                                  _isConnected ? 'On' : 'Off',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    color: onBackground,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Switch(
                                  value: _isConnected,
                                  onChanged: (val) => _toggleConnection(bleController),

                                  // 🍊 الحالة ON: المسار برتقالي (التصحيح: استخدام activeTrackColor)
                                  activeTrackColor: neonColor,
                                  // الدائرة سوداء في حالة التشغيل (ON)
                                  activeThumbColor: Colors.black,

                                  // ⚫ الحالة OFF: المسار أسود شفاف
                                  inactiveTrackColor: Colors.black.withOpacity(0.5),
                                  // الدائرة سوداء في حالة الإيقاف (OFF)
                                  inactiveThumbColor: Colors.black,

                                  // حذف activeColor لأنه قد يتعارض مع activeTrackColor
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 5. Show Voice Overlay
                if (_isAwaitingInput || bleController.isListening)
                  chatOverlay,
              ],
            ),
          ),
        );
      },
    );
  }
}