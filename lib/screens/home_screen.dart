// home_screen.dart (التعديل النهائي والمصحح)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_controller.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'ble_scan_screen.dart';
import 'glasses_screen.dart';
import 'bracelet_screen.dart';
import 'cane_screen.dart';
import 'settings_screen.dart';

// Custom Colors (Matching the requested dark/neon theme)
const Color neonColor = Color(0xFFFFB267); // Orange
const Color darkSurface = Color(0xFF243020); // Darker Greenish Black (for BottomBar/Boxes)
const Color darkBackground = Color(0xFF141318); // Darkest Black/Navy (Main BG Color)
const Color onBackground = Colors.white;

// Placeholder for missing screens (لضمان تشغيل الكود)
class CaneScreen extends StatelessWidget {
  const CaneScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Smart Cane')), body: const Center(child: Text('Cane Details Screen', style: TextStyle(color: Colors.white))));
  }
}
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Settings')), body: const Center(child: Text('Settings Screen', style: TextStyle(color: Colors.white))));
  }
}


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late BleController _bleController;

  String _geminiResponse = 'Hello! I am your smart assistant.';
  String _lastSpokenPrompt = '';
  bool _isAwaitingInput = false;

  int _tapCount = 0;
  Timer? _tapResetTimer;
  final Duration _tapTimeout = const Duration(milliseconds: 600);

  // Revised list of devices for cleaner card building (no assets needed here)
  final List<Map<String, dynamic>> _devices = [
    {
      'name': 'Glasses',
      'icon': Icons.visibility,
      'screen': const GlassesScreen(),
      'color': const Color(0xFF4C7CFF), // Blue
    },
    {
      'name': 'Bracelet',
      'icon': Icons.watch,
      'screen': const BraceletScreen(),
      'color': const Color(0xFFFF6347), // Red-Orange
    },
    {
      'name': 'Cane',
      'icon': Icons.personal_injury,
      'screen': const CaneScreen(),
      'color': const Color(0xFF3CB371), // Green
    },
    {
      'name': 'Earbuds',
      'icon': Icons.headset,
      'screen': const CaneScreen(), // Placeholder screen
      'color': const Color(0xFFADD8E6), // Light Blue
    },
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _bleController = Provider.of<BleController>(context, listen: false);
      // يجب أن يتم تهيئة الـ Speech هنا إذا لم يتم ذلك في مكان آخر
      // _bleController.initSpeech();
      _bleController.speak('Welcome home. Long-press to ask me anything.');
    });
  }

  @override
  void dispose() {
    _bleController.stopListening(shouldSpeakStop: false);
    _tapResetTimer?.cancel();
    super.dispose();
  }

  // (Push-to-Talk)
  void _onLongPressStart(BleController bleController) {
    if (bleController.isListening) {
      bleController.speak('جاري الاستماع بالفعل. ارفع أصبعك لإنهاء التسجيل.');
      return;
    }
    // bleController.speak('بدأ التسجيل. تحدث الآن.'); // يمكن إزالتها لتجنب التكرار مع الـ FAB

    setState(() {
      _isAwaitingInput = true;
      _lastSpokenPrompt = '';
      _geminiResponse = 'Processing your query...';
    });

    bleController.startListening(
      onResult: (spokenText) async {
        if (mounted) {
          setState(() {
            _lastSpokenPrompt = spokenText;
            _isAwaitingInput = true;
          });
          if (spokenText.isNotEmpty) {
            await _processGeminiQuery(spokenText);
          } else {
            _geminiResponse = 'Sorry, I couldn\'t recognize your speech. Please try again.';
            bleController.speak('عفواً، لم أستطع التعرف على حديثك. يرجى المحاولة مرة أخرى.');
            if(mounted) {
              setState(() {
                _isAwaitingInput = false;
              });
            }
          }
        }
      },
    );
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (_bleController.isListening) {
      _bleController.stopListening(shouldSpeakStop: false);
      // _bleController.speak('تم إيقاف التسجيل. جاري معالجة السؤال.');
    }
  }

  void _handleScreenTap(BleController bleController) {
    _tapCount++;
    _tapResetTimer?.cancel();
    _tapResetTimer = Timer(_tapTimeout, () {
      _processTapCount(bleController);
    });
  }

  void _processTapCount(BleController bleController) {
    final int count = _tapCount;
    _tapCount = 0;

    if (count == 1) {
      if (bleController.isListening) {
        bleController.stopListening(shouldSpeakStop: true);
        setState(() {
          _isAwaitingInput = false;
        });
        bleController.speak('تم إيقاف الاستماع بنقرة واحدة.');
      } else {
        bleController.speak('للتسجيل الصوتي، يرجى الضغط مطولاً على زر الميكروفون. للنقر المزدوج للدخول لشاشة أي جهاز. للنقر الثلاثي لتفعيل مكالمة الطوارئ.');
      }
    } else if (count == 2) {
      bleController.speak('الرجاء النقر نقرتين على بطاقة الجهاز الذي تريد الدخول إليه.');
    } else if (count == 3) {
      _triggerEmergencyCall(bleController);
    }
  }

  void _triggerEmergencyCall(BleController bleController) async {
    bleController.stopListening(shouldSpeakStop: false);
    bleController.speak('');

    // استخدام 911 كرقم افتراضي إذا لم يكن هناك رقم محدد
    final number = bleController.userProfile?.emergencyPhoneNumber ?? '911';

    if (number.isNotEmpty) {
      bleController.speak('تفعيل مكالمة الطوارئ بثلاث نقرات. يتم الاتصال الآن برقم: $number');
      final url = Uri.parse('tel:$number');

      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        bleController.speak('عذراً، لا يمكن إجراء مكالمة هاتفية.');
      }
    } else {
      bleController.speak('عذراً، لم يتم تحديد رقم الطوارئ في ملفك الشخصي. يرجى إضافته في شاشة الإعدادات.');
    }
  }

  Future<void> _processGeminiQuery(String query) async {
    setState(() {
      _geminiResponse = 'Searching for "${query}"...';
    });

    // هنا يتم استدعاء منطق المساعد الصوتي، يمكن استبداله بمنطقك الفعلي
    // await _bleController.getGeminiResponse(query);

    if (mounted) {

      const simulatedResponse = 'OK. Your query has been processed successfully. I am an AI model, and I can help you with general medical information or task reminders.';
      _bleController.speak('تمت معالجة سؤالك. هذا هو الرد: أنا نموذج ذكاء اصطناعي، ويمكنني مساعدتك في معلومات طبية عامة أو تذكيرك بالمهام.');

      setState(() {
        _geminiResponse = simulatedResponse;
        _isAwaitingInput = false;
      });
    }
  }

  void _navigateToDevice(BuildContext context, String deviceName, Widget screen) {
    _bleController.speak('جارٍ الانتقال إلى شاشة ${deviceName} بالتفاصيل.');
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _goToSettings() {
    _bleController.speak('جاري التوجه إلى شاشة الإعدادات.');
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
  }

  // **********************************************
  // ** UI Builders (المعدّلة) **
  // **********************************************

  // ✨ التعديل: بناء بطاقة الجهاز (بدون صور داخلية)
  Widget _buildDeviceCard(BuildContext context, Map<String, dynamic> device) {
    final name = device['name'] as String;
    final icon = device['icon'] as IconData;
    final screen = device['screen'] as Widget;
    final color = device['color'] as Color;

    return InkWell(
      onTap: () => _navigateToDevice(context, name, screen),
      child: Container(
        decoration: BoxDecoration(
          color: darkSurface.withOpacity(0.9), // خلفية داكنة للبوكس
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 50,
              color: color,
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: const TextStyle(
                color: onBackground,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Box for Gemini Response (kept simple)
  Widget _buildGeminiResponseBox(String response) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
      decoration: BoxDecoration(
        color: darkSurface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: neonColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assistant Response:',
            style: TextStyle(
              color: neonColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _geminiResponse,
            style: const TextStyle(
              color: onBackground,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // ✨ التعديل: تفعيل الخلفية المدمجة
    const backgroundDecoration = BoxDecoration(
      color: darkBackground,
      image: DecorationImage(
        image: AssetImage('assets/images/background.jpg'), // المسار المتفق عليه
        fit: BoxFit.cover,
        opacity: 0.3, // تقليل الشفافية لجعل النص واضحاً
      ),
    );

    return Consumer<BleController>(
      builder: (context, bleController, child) {
        return GestureDetector(
          onTap: () => _handleScreenTap(bleController),
          onLongPressStart: (_) => _onLongPressStart(bleController),
          onLongPressEnd: _onLongPressEnd,
          child: Container(
            decoration: backgroundDecoration,
            child: Scaffold(
              backgroundColor: Colors.transparent, // لجعل الخلفية تظهر
              appBar: AppBar(
                  title: const Text('Home Dashboard', style: TextStyle(fontWeight: FontWeight.bold, color: neonColor)),
                  backgroundColor: darkBackground.withOpacity(0.8),
                  elevation: 0,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.emergency, color: Colors.redAccent),
                      onPressed: () => _triggerEmergencyCall(bleController),
                      tooltip: 'Emergency Call',
                    )
                  ]
              ),

              // Floating Action Button (في المنتصف)
              floatingActionButton: FloatingActionButton(
                backgroundColor: neonColor,
                onPressed: () => _bleController.speak('اضغط مطولاً للتسجيل الصوتي. اضغط مرتين للبحث عن البلوتوث.'),
                child: Icon(
                  bleController.isListening ? Icons.mic_off : Icons.mic,
                  color: darkBackground,
                  size: 35,
                ),
              ),
              floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

              // ✨ التعديل: BottomAppBar (btn var) وتنزيل كلمة "Home"
              bottomNavigationBar: BottomAppBar(
                elevation: 10,
                notchMargin: 6.0,
                shape: const CircularNotchedRectangle(),
                color: darkSurface.withOpacity(0.9),
                child: Container(
                  height: 65.0, // ارتفاع كافٍ لضمان النزول
                  padding: const EdgeInsets.only(top: 10.0, bottom: 0.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end, // ✨ النقطة الأهم: دفع العناصر لأسفل الـ Container
                    children: <Widget>[
                      // Home Button (Active State)
                      InkWell(
                        onTap: () => _bleController.speak('أنت بالفعل في الشاشة الرئيسية.'),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.home, size: 30, color: neonColor),
                            Text('Home', style: TextStyle(fontSize: 12, color: neonColor)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 40), // مسافة للـ FAB
                      // Settings Button
                      InkWell(
                        onTap: _goToSettings,
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.settings, size: 30, color: onBackground),
                            Text('Settings', style: TextStyle(fontSize: 12, color: onBackground)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              body: Stack(
                children: [
                  SingleChildScrollView(
                    // ✨ التعديل: زيادة المسافة العلوية لدفع البوكسات للأسفل
                    padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // Box for Gemini Response
                        _buildGeminiResponseBox(_geminiResponse),

                        const SizedBox(height: 30),

                        const Padding(
                          padding: EdgeInsets.only(left: 0.0),
                          child: Text(
                            'Connected Devices',
                            style: TextStyle(
                              color: onBackground,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Device Grid (البوكسات)
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _devices.length,
                          padding: EdgeInsets.zero,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.0,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                          ),
                          itemBuilder: (context, index) {
                            return _buildDeviceCard(context, _devices[index]);
                          },
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),

                  // شاشة التحميل/الاستماع
                  if (_isAwaitingInput || bleController.isListening)
                    Container(
                      color: Colors.black.withOpacity(0.7),
                      constraints: const BoxConstraints.expand(),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: neonColor),
                            const SizedBox(height: 20),
                            Text(
                              bleController.isListening
                                  ? 'جاري الاستماع إليك... ارفع أصبعك لإنهاء التسجيل'
                                  : 'جاري معالجة استفسارك...',
                              style: const TextStyle(color: Colors.white, fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}