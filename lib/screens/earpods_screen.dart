// earpods_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

// Navigation Imports
import 'cane_screen.dart';
import 'glasses_screen.dart';
import 'bracelet_screen.dart';
import 'gesture_config_screen.dart';
// Note: main_chat_screen is implicitly navigated to via Navigator.pop()

// Custom Colors (Using the consistent color scheme)
const Color neonColor = Color(0xFFFFB267);
const Color darkSurface = Color(0xFF242020);
const Color darkBackground = Color(0xFF141318);
const Color onBackground = Colors.white;
const Color cardColor = Color(0xFF282424);

// إضافة متغير قائمة الأزرار (btn) كما طُلب
final List<String> btn = const [
  'Cane',
  'Glasses',
  'Bracelet',
  'Earpods',
];

// *** Custom Orange Switch Widget ***
class CustomOrangeSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  // ✅ تم تصحيح دالة الإنشـاء إلى الصيغة الأكثر توافقًا (Key? key)
  const CustomOrangeSwitch({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key); // استدعاء super(key: key) يحل مشكلة الـ 'value' getter

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 50.0,
        height: 28.0,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.0),
          // مطابقة لون التراك (Track Color)
          color: value ? neonColor : Colors.black.withOpacity(0.5),
        ),
        child: Stack(
          children: <Widget>[
            // زر التبديل (Thumb)
            AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: Container(
                  width: 20.0,
                  height: 20.0,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    // مطابقة لون الزر (Thumb Color)
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// *** نهاية ويدجت المفتاح المخصص ***

// **Earpods Screen Class**
class EarpodsScreen extends StatefulWidget {
  const EarpodsScreen({super.key});

  @override
  State<EarpodsScreen> createState() => _EarpodsScreenState();
}

class _EarpodsScreenState extends State<EarpodsScreen> {
  final String _batteryLevel = '85%';
  final String _timeRemaining = '5h 45m';
  bool _isDeviceOn = true;

  bool _isAwaitingInput = false;
  String _lastSpokenPrompt = '';

  late BleController _bleController;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _bleController = Provider.of<BleController>(context, listen: false);
      _bleController.speak('You are now in the Assistant Earpods screen. Showing battery status and connectivity. Double tap to return. Long press to give a voice command.');
    });
  }

  // Voice Handlers
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

  // Command Handler with Global Navigation
  void _handleCommand(BleController bleController, String command) async {
    final normalizedCommand = command.toLowerCase().trim();

    void navigateTo(Widget screen, String name) {
      bleController.speak('Navigating to $name screen.');
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => screen));
    }

    // Navigation Logic:
    if (normalizedCommand.contains('earpods') || normalizedCommand.contains('سماعات')) {
      bleController.speak('You are already on the Earpods screen.');
      return;
    } else if (normalizedCommand.contains('cane') || normalizedCommand.contains('عصا')) {
      navigateTo(const CaneScreen(), 'Cane');
      return;
    } else if (normalizedCommand.contains('glasses') || normalizedCommand.contains('نظاره')) {
      navigateTo(const GlassesScreen(), 'Glasses');
      return;
    } else if (normalizedCommand.contains('bracelet') || normalizedCommand.contains('سوار')) {
      navigateTo(const BraceletScreen(), 'Bracelet');
      return;
    } else if (normalizedCommand.contains('home') || normalizedCommand.contains('رئيسية') || normalizedCommand.contains('main')) {
      bleController.speak('Returning to Home screen.');
      Navigator.of(context).pop();
      return;
    }

    // Special Commands:
    else if (normalizedCommand.contains('settings') || normalizedCommand.contains('اعدادات')) {
      bleController.speak('Navigating to Settings screen.');
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const GestureConfigScreen()),
      );
      return;
    } else if (normalizedCommand.contains('emergency') || normalizedCommand.contains('طوارئ') || normalizedCommand.contains('911')) {
      bleController.speak('Initiating emergency call.');
      const url = 'tel:911';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        bleController.speak('Sorry, emergency call cannot be placed.');
      }
      return;
    }

    // Fallback:
    bleController.speak('I did not recognize a navigation command. Processing your query now.');
  }

  // دالة تبديل حالة تشغيل الجهاز
  void _toggleDevice(bool newValue) {
    setState(() {
      _isDeviceOn = newValue;
    });
    final status = newValue ? 'On' : 'Off';
    _bleController.speak('Earpods are now $status.');
  }

  void _handleDoubleTap(BleController bleController) {
    bleController.speak('Returning to the Home Screen.');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BleController>(
      builder: (context, bleController, child) {
        // Chat Overlay UI
        final chatOverlay = Container(
          color: Colors.black.withOpacity(0.8),
          constraints: const BoxConstraints.expand(),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
        );

        return GestureDetector(
          onLongPressStart: (_) => _onLongPressStart(bleController),
          onLongPressEnd: _onLongPressEnd,
          onDoubleTap: () => _handleDoubleTap(bleController),
          child: Scaffold(
            backgroundColor: darkBackground,
            body: Stack(
              children: [
                // 1. Background Image
                Container(
                  constraints: const BoxConstraints.expand(),
                  decoration: BoxDecoration(
                    color: darkBackground,
                    image: DecorationImage(
                      image: const AssetImage('assets/images/earpods.jpg'),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.2), BlendMode.darken),
                    ),
                  ),
                ),

                // 2. Navigation Header
                Positioned(
                  top: 50,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // السهم (رجوع)
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(
                          Icons.arrow_back_ios, // ✅ تم التصحيح هنا
                          color: onBackground,
                          size: 28,
                        ),
                      ),
                      // كلمة Earpods
                      const Text(
                        'Earpods',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: onBackground),
                      ),
                      // جرس الإشعارات
                      IconButton(
                        icon: const Icon(Icons.notifications_none,
                            color: onBackground, size: 28),
                        onPressed: () { /* Handle notification tap */ },
                      ),
                    ],
                  ),
                ),

                // 3. Main Content
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 120),

                    // منطقة السماعات في المنتصف (Expanded to fill the remaining space)
                    Expanded(
                      // Removed flex property
                      child: Center(
                        child: Container(),
                      ),
                    ),

                    // بطاقة البطارية والمفتاح (Matching Bracelet Card Design)
                    Container(
                      // تم تعديل Padding ليطابق بطاقة Bracelet
                      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                      padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20.0),
                      decoration: BoxDecoration(
                        // تم تعديل اللون والشفافية ليطابق بطاقة Bracelet
                        color: cardColor.withOpacity(0.4),
                        // تم تعديل نصف القطر ليطابق بطاقة Bracelet
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min, // Ensures card takes minimum height
                        children: [
                          // نسبة البطارية
                          Text(
                            _batteryLevel,
                            textAlign: TextAlign.left,
                            style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: onBackground),
                          ),
                          const SizedBox(height: 5),
                          // الوقت المتبقي
                          Text(
                            'Estimated time remaining : $_timeRemaining',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                                fontSize: 14, color: onBackground.withOpacity(0.7)),
                          ),
                          const SizedBox(height: 30),
                          // مفتاح التشغيل
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'On',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: onBackground),
                              ),
                              CustomOrangeSwitch(
                                value: _isDeviceOn,
                                onChanged: _toggleDevice,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // تم تقليل المسافة السفلية لرفع البوكس
                    const SizedBox(height: 5),
                  ],
                ),

                // Show Voice Overlay
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