// main_chat_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_controller.dart';
import 'dart:async';
import 'settings_screen.dart'; // Setting Screen
import 'package:url_launcher/url_launcher.dart';
import 'ble_scan_screen.dart';
// Import device screens (يجب أن تكون هذه الملفات موجودة في مشروعك)
import 'glasses_screen.dart';
import 'bracelet_screen.dart';
import 'cane_screen.dart';
import 'package:flutter/services.dart';
import 'dart:math'; // ✅ تمت إضافة هذه الحزمة لـ math.pi
import 'user_profile_screen.dart'; // Setting Screen

// ✅ استيراد حزم الأيقونات الخارجية
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
// 🆕 استيراد شاشة السماعات الجديدة
import 'earpods_screen.dart';


// Custom Colors (Matching the Figma Design)
const Color neonColor = Color(0xFFFFB267); // Orange (Buttons and glow)
const Color darkSurface = Color(0xFF1C1C1C);
const Color darkBackground = Color(0xFF000000); // Pure Black background
const Color onBackground = Colors.white;

class MainChatScreen extends StatefulWidget {
  const MainChatScreen({super.key});

  @override
  State<MainChatScreen> createState() => _MainChatScreenState();
}

class _MainChatScreenState extends State<MainChatScreen> {
  // ⚠️ يرجى التأكد أن BleController معرفة كـ Provider في ملف main.dart
  late BleController _bleController;

  String _geminiResponse = '';
  String _lastSpokenPrompt = '';
  bool _isAwaitingInput = false; // Used for general processing/loading
  bool isListening = false; // Used to track active listening

  // Device list (Matching the Figma design with specific icons)
  final List<Map<String, dynamic>> _devices = [
    {
      'name': 'Glasses',
      'subtitle': 'Smart Glasses',
      // أيقونة النظارة
      'icon': MdiIcons.glasses,
      // ⚠️ تم إزالة const لتجنب أخطاء
      'screen':  GlassesScreen(),
    },
    {
      'name': 'Cane',
      'subtitle': 'Smart Cane',
      // 🚨 أيقونة الخط المائل (الأكثر استقراراً)
      'icon': MdiIcons.slashForward,
      'screen': const CaneScreen(),
    },
    {
      'name': 'Bracelet',
      'subtitle': 'Assistive Band',
      // أيقونة السوار (الساعة الدائرية)
      'icon': MdiIcons.watch,
      // ⚠️ تم إزالة const لتجنب أخطاء
      'screen':  BraceletScreen(),
    },
    {
      'name': 'Earbuds',
      'subtitle': 'Lumos Audio',
      // أيقونة سماعات الأذن
      'icon': FluentIcons.surface_earbuds_20_regular,
      // 🆕 تم التحديث لربط الشاشة الجديدة
      'screen': const EarpodsScreen(),
    },
  ];

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () {
      // ⚠️ استخدام Provider.of بالشكل الصحيح
      _bleController = Provider.of<BleController>(context, listen: false);
      _bleController.speak('Welcome to the Home Screen. Long-press to speak a command.');
    });
  }

  // **********************************************
  // ** Handlers and Navigations **
  // **********************************************

  void _onLongPressStart(BleController bleController) {
    if (_isAwaitingInput || bleController.isListening) return;

    setState(() { _isAwaitingInput = true; });
    bleController.speak('Recording started. Speak now.');

    bleController.startListening(
      onResult: (spokenText) async {
        if (mounted) {
          setState(() { _lastSpokenPrompt = spokenText; });
          if (spokenText.isNotEmpty) {
            _processVoiceCommand(spokenText, bleController);
          } else {
            bleController.speak('Could not recognize your speech. Long press and try again.');
            if(mounted) setState(() { _isAwaitingInput = false; });
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

  Future<void> _processVoiceCommand(String query, BleController bleController) async {
    await Future.delayed(const Duration(seconds: 1));
    if(mounted) setState(() { _isAwaitingInput = false; });
  }

  void _navigateToDevice(Map<String, dynamic> device, BleController bleController) {
    if (device['screen'] != null) {
      bleController.speak('Navigating to ${device['name']} screen.');
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => device['screen']),
      );
    } else {
      bleController.speak('${device['name']} screen is not available yet.');
    }
  }

  void _goToSettings() {
    _bleController.speak('Navigating to Settings screen.');
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  void _navigateToAddDevice() {
    _bleController.speak('Navigating to Add Device screen.');
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const BleScanScreen()),
    );
  }

  // **********************************************
  // ** UI Builders (المطابقة النهائية للتصميم) **
  // **********************************************

  // ✨ بناء بطاقة الجهاز (بالتوهج النيون وشفافية الخلفية)
  Widget _buildDeviceCard(BuildContext context, BleController bleController, Map<String, dynamic> device) {
    final name = device['name'] as String;
    final subtitle = device['subtitle'] as String;
    final iconData = device['icon'] as IconData;

    // تهيئة الأيقونة الأساسية
    Widget iconWidget = Icon(
      iconData,
      size: 35, // تم التصغير
      color: neonColor,
      shadows: const [
        Shadow(blurRadius: 15.0, color: neonColor), // تأثير التوهج
      ],
    );

    // 1. تدوير السوار 90 درجة (بالعرض)
    if (name == 'Bracelet') {
      iconWidget = Transform.rotate(
        angle: 90 * pi / 180, // تدوير 90 درجة
        child: iconWidget,
      );
    }

    // 2. تدوير سماعات الأذن (ميل خفيف للأعلى واليسار)
    if (name == 'Earbuds') {
      // 🚨 التعديل: تدوير خفيف (15 درجة) بدون شقلبة
      iconWidget = Transform.rotate(
        angle: 15 * pi / 180, // تم تعيينها على 15 درجة كبداية
        child: iconWidget,
      );
    }

    // 3. تدوير العصا (Cane)
    // 🚨 التعديل: تدوير MdiIcons.slashForward لتبدو كعصا بيضاء مائلة
    if (name == 'Cane' && iconData == MdiIcons.slashForward) {
      // لا تدوير إضافي، فقط تغيير الحجم لجعلها تظهر كعصا طويلة
      iconWidget = Icon(
        iconData,
        // ✅ زيادة الحجم لتبدو كعصا طويلة وواضحة
        size: 60,
        color: neonColor,
        shadows: const [
          Shadow(blurRadius: 15.0, color: neonColor),
        ],
      );
    }


    return GestureDetector(
      onTap: () => _navigateToDevice(device, bleController),
      child: Card(
        // 🚨 (2) زيادة شفافية البوكسات لتظهر الخلفية من خلالها (0.6)
        color: darkSurface.withOpacity(0.6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            // 🚨 الترتيب: يحافظ على الأيقونة/الاسم في الأعلى والوصف في الأسفل
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // الصف الأول: الأيقونة + الاسم (في الأعلى)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  iconWidget, // استخدام الـ widget بعد تطبيق الـ Transform
                  // 🚨 التعديل 2: مسافة صغيرة جداً تحت الأيقونة مباشرةً
                  const SizedBox(height: 5),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: onBackground,
                    ),
                  ),
                ],
              ),

              // الصف الثاني: الوصف (في الأسفل وفي المنتصف)
              // 🚨 التعديل 3: استخدام Center لتوسيط النص أفقياً في الأسفل
              Center(
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: onBackground.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper for Bottom Nav Bar items
  Widget _buildBottomNavItem({required IconData icon, required bool isActive, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        // ✅ استخدام أيقونة الشخص المطلوبة (fluent:person-16-filled)
        child: Icon(
            icon == Icons.person_outline ? FluentIcons.person_16_filled : icon,
            size: 30,
            color: isActive ? neonColor : onBackground.withOpacity(0.7)
        ),
      ),
    );
  }

  // 🚨 البنية الجديدة التي تدمج الزر وشريط التنقل
  Widget _buildIntegratedBottomBar() {
    return Column(
      mainAxisSize: MainAxisSize.min, // مهم جداً لتحديد ارتفاع العمود
      children: [
        // 1. زر Add Device (مباشرة فوق شريط التنقل)
        Padding(
          // 🚨 (تعديل المسافة): تم تقليل الـ vertical padding إلى 10 لرفع الزر قليلاً
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
          child: ElevatedButton(
            onPressed: _navigateToAddDevice,
            style: ElevatedButton.styleFrom(
              backgroundColor: neonColor,
              // الحجم المستطيل الكبير المطلوب
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(
                // تم تقليل الاستدارة قليلاً لتناسب التصميم المدمج
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 10,
            ),
            child: const Text(
              'Add device',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: darkBackground,
              ),
            ),
          ),
        ),

        // 2. شريط التنقل السفلي (Bottom Navigation)
        Container(
          // 🚨 (تعديل الارتفاع): تم تقليل الارتفاع ليتطابق مع الصورة
          height: 60.0,
          decoration: BoxDecoration(
            color: darkBackground.withOpacity(0.95),
            // 🚨 (تعديل الـ Radius): تم تقليل الـ Radius ليتطابق مع الصورة
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _buildBottomNavItem(
                icon: Icons.home_filled,
                isActive: true,
                onTap: () => _bleController.speak('You are already on the Home screen.'),
              ),
              _buildBottomNavItem(
                icon: Icons.grid_view,
                isActive: false,
                onTap: () => _bleController.speak('Devices view.'),
              ),
              _buildBottomNavItem(
                icon: Icons.person_outline, // نستخدمها كرمز placeholder
                isActive: false,
                onTap: () => _bleController.speak('User profile screen.'),
              ),
              _buildBottomNavItem(
                icon: Icons.settings_outlined,
                isActive: false,
                onTap: _goToSettings,
              ),
            ],
          ),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<BleController>(
      builder: (context, bleController, child) {
        isListening = bleController.isListening;

        // ** 1. Background Wrapper (تفعيل صورة الخلفية) **
        return GestureDetector(
          onLongPressStart: (_) => _onLongPressStart(bleController),
          onLongPressEnd: _onLongPressEnd,
          child: Container(
            // ⚠️ هذا هو الكود المسؤول عن وضع الصورة كخلفية
            decoration: const BoxDecoration(
              color: darkBackground,
              image: DecorationImage(
                image: AssetImage('assets/images/background.jpg'), // المسار المطلوب
                fit: BoxFit.cover,
                opacity: 1.0,
                // 🚨 التعديل: إزاحة الصورة لليمين والأعلى بزيادة
                alignment: Alignment(0.1, -0.2), // تم التغيير لليمين والأعلى
              ),
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent, // يسمح بظهور خلفية الـ Container

              // ** 3. Bottom Navigation Bar (BottomAppBar) - تم دمج الزر هنا **
              bottomNavigationBar: _buildIntegratedBottomBar(),

              // ** 4. Body Content (Header, Grid) **
              body: Stack(
                children: [
                  CustomScrollView(
                    slivers: [
                      SliverList(
                        delegate: SliverChildListDelegate(
                          [
                            // 🚨 (تعديل المسافة العلوية): تم تقليل المسافة إلى 80
                            const SizedBox(height: 80),
                            // Page Title: Home
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20.0),
                              child: Text(
                                'Home',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: onBackground,
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),

                            // Device Count
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Text(
                                '${_devices.length} devices',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: onBackground.withOpacity(0.6),
                                ),
                              ),
                            ),
                            // 🚨 (تعديل المسافة): تم تقليل المسافة إلى 20
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                      // Device Grid (البوكسات)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                            // 🚨 (مقاس البوكسات): تم زيادتها إلى 0.9 لتصغير البوكسات وجعلها مستطيلة أكثر
                            childAspectRatio: 0.9,
                          ),
                          delegate: SliverChildListDelegate(
                            _devices.map((device) {
                              return _buildDeviceCard(context, bleController, device);
                            }).toList(),
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(
                        // 🚨 (تعديل المسافة السفلية): تم تقليلها إلى 110
                        child: SizedBox(height: 110),
                      ),
                    ],
                  ),

                  // Loading/Listening screen
                  if (_isAwaitingInput || isListening)
                    Container(
                      color: Colors.black.withOpacity(0.8),
                      constraints: const BoxConstraints.expand(),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: neonColor),
                            const SizedBox(height: 20),
                            Text(
                              isListening
                                  ? 'Listening to you... Lift your finger to stop recording'
                                  : 'Processing your command...',
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