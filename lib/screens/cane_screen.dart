// cane_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:ui'; // مهم لاستخدام ImageFilter

// Navigation Imports
import 'main_chat_screen.dart';
import 'glasses_screen.dart';
import 'bracelet_screen.dart';
import 'gesture_config_screen.dart';
import 'earpods_screen.dart';

// ⚠️ الألوان بناءً على طلبك
const Color neonColor = Color(0xFFFFB267); // لون المفتاح البرتقالي
const Color darkSurface = Color(0xFF242020); // لون سطح البطاقة الداكن
const Color darkBackground = Color(0xFF141318); // لون الخلفية الداكن

// ✅ لون النص العام: #CCCCCC
const Color generalTextColor = Color(0xFFCCCCCC);
// ✅ لون البطارية وعنوان "Smart Cane": #FFFFFF (أبيض نقي)
const Color batteryPercentageColor = Color(0xFFFFFFFF);

// *** ويدجت مخصص للمفتاح البرتقالي ***
class CustomOrangeSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const CustomOrangeSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 50.0,
        height: 28.0,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.0),
          color: value ? neonColor : darkSurface,
          border: Border.all(
            color: value ? neonColor : generalTextColor.withOpacity(0.3),
            width: 1.5,
          ),
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
                    color: Colors.black, // أسود
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


class CaneScreen extends StatefulWidget {
  const CaneScreen({super.key});

  @override
  State<CaneScreen> createState() => _CaneScreenState();
}

class _CaneScreenState extends State<CaneScreen> {
  // الحالة التي تتحكم في زر التشغيل/الإيقاف
  bool _isDeviceOn = true;
  bool _isAwaitingInput = false;
  String _lastSpokenPrompt = '';

  late BleController _bleController;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _bleController = Provider.of<BleController>(context, listen: false);
      _bleController.speak('You are now in the Smart Cane screen. Showing battery level and device status. Double tap to return. Long press to give a voice command.');
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
      navigateTo(const GlassesScreen(), 'Glasses');
      return;
    } else if (normalizedCommand.contains('cane') || normalizedCommand.contains('عصا')) {
      bleController.speak('You are already on the Cane screen.');
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
      _goToSettings();
      return;
    } else if (normalizedCommand.contains('emergency') || normalizedCommand.contains('طوارئ') || normalizedCommand.contains('911')) {
      bleController.speak('Initiating emergency call.');
      _triggerEmergencyCall(bleController);
      return;
    }

    bleController.speak('I did not recognize a navigation command. Processing your query now.');
  }

  void _toggleDevice(bool newValue) {
    setState(() {
      _isDeviceOn = newValue;
    });
    final status = newValue ? 'On' : 'Off';
    _bleController.speak('Device is now $status.');
  }

  void _handleDoubleTap(BleController bleController) {
    bleController.speak('Returning to the Home Screen.');
    Navigator.of(context).pop();
  }


  @override
  Widget build(BuildContext context) {
    // *** تعريف نمط الخط الجديد لـ "Estimated time remaining" ***
    const TextStyle estimatedTimeStyle = TextStyle(
      color: generalTextColor, // #CCCCCC
      fontSize: 14,
      fontWeight: FontWeight.w700, // ✅ تم زيادة الوزن إلى Bold
      fontFamily: 'Manrope',
      letterSpacing: 14 * 0.01,
    );

    return Consumer<BleController>(
      builder: (context, bleController, child) {
        // **Chat Overlay UI**
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
                  style: const TextStyle(
                    color: generalTextColor, // #CCCCCC
                    fontSize: 18,
                    fontWeight: FontWeight.w700, // ✅ تم زيادة الوزن إلى Bold
                  ),
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
                // 1. Background Image (صورة العصا) - تغطي كامل الشاشة
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/cane.jpg'),
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      ),
                    ),
                  ),
                ),

                // 2. تدرج خفيف (Soft Gradient Overlay) لتوحيد اللون قليلاً
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.6),
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),
                ),

                // 3. Navigation Header
                Positioned(
                  top: 50,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.arrow_back_ios, color: generalTextColor, size: 24), // #CCCCCC
                      ),
                      const Text(
                        'Smart Cane',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700, // ✅ تم زيادة الوزن إلى Bold
                            fontFamily: 'Manrope',
                            color: batteryPercentageColor), // ✅ تم التغيير إلى الأبيض النقي
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_none,
                            color: generalTextColor, size: 24), // #CCCCCC
                        onPressed: () { /* Handle notification tap */ },
                      ),
                    ],
                  ),
                ),

                // 4. البطارية وحالة التشغيل - تم تطبيق تأثير Glassmorphism وخصائص الخط
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.15,
                  right: 20.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                        width: MediaQuery.of(context).size.width * 0.61,
                        decoration: BoxDecoration(
                          color: darkSurface.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: generalTextColor.withOpacity(0.15), // #CCCCCC بـ Opacity 15%
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '36%',
                              style: TextStyle(
                                color: batteryPercentageColor, // ✅ أبيض نقي
                                fontSize: 38,
                                fontWeight: FontWeight.w800, // وزن أثقل (ExtraBold)
                                fontFamily: 'Manrope',
                              ),
                            ),
                            const SizedBox(height: 5),
                            // *** Estimated time remaining ***
                            const Text(
                              'Estimated time remaining: 3h 20m',
                              style: estimatedTimeStyle, // مطبق عليه سمك Bold و #CCCCCC
                            ),
                            const SizedBox(height: 25),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _isDeviceOn ? 'On' : 'Off',
                                  style: const TextStyle(
                                    color: generalTextColor, // #CCCCCC
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700, // ✅ تم زيادة الوزن إلى Bold
                                    fontFamily: 'Manrope',
                                  ),
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