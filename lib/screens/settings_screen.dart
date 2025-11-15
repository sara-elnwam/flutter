// settings_screen.dart (FINAL - تم تطبيق تصميم الصورة وحذف AppBar وFix Logout)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_controller.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
// 💡 يجب التأكد من وجود ملف local_auth_screen.dart في هذا المسار
import 'local_auth_screen.dart';

// -----------------------------------------------------------------
// ✅ Custom Colors (Deepest Muted Tones - مطابقة للتصميم)
// -----------------------------------------------------------------
const Color darkBackground = Color(0xFF1F1A1B); // لون الخلفية
const Color darkSurface = Color(0xFF272523);   // ✅ لون البوكس الرئيسي (تم تصحيح الـ Hex)
const Color onSurfaceText = Color(0xFF727272);     // لون النص المطفأ بدرجة أغمق
const Color dividerColor = Color(0xFF424242);   // لون الخط الفاصل
const Color logoutColor = Color(0xFFFF5B5B);   // لون مخصص لزر الخروج (أحمر مطفأ)
// -----------------------------------------------------------------


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late BleController _bleController;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _bleController = Provider.of<BleController>(context, listen: false);
    });
  }

  // دالة مؤقتة لمحاكاة النطق
  void _speakOption(String option) {
    if (mounted) {
      _bleController.speak('Selected $option option.');
    }
  }

  // ✅ دالة تسجيل الخروج المعدلة
  void _logout() {
    _bleController.speak('Logging out. Returning to authentication screen.');

    // الانتقال إلى شاشة المصادقة / تسجيل الدخول وحذف جميع المسارات السابقة
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LocalAuthScreen()),
      // إزالة كل المسارات السابقة لضمان عدم العودة
          (Route<dynamic> route) => false,
    );
  }

  // -------------------------------------------------------------
  // ** دالة مساعدة لبناء عنصر إعداد (List Tile) **
  // -------------------------------------------------------------
  Widget _buildSettingItem(BuildContext context, String title, VoidCallback onTap,
      {Color? textColor, bool showDivider = true}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // النص الرئيسي
                Text(
                  title,
                  style: TextStyle(
                    color: textColor ?? onSurfaceText, // استخدام اللون المطفأ الافتراضي
                    fontSize: 16,
                  ),
                ),
                // أيقونة السهم الجانبية
                Icon(
                  Icons.arrow_forward_ios,
                  color: onSurfaceText,
                  size: 16,
                ),
              ],
            ),
            // الخط الفاصل
            if (showDivider)
              Divider(
                color: dividerColor,
                thickness: 1,
                height: 20, // ارتفاع الفاصل
              ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground, // لون الخلفية الداكن

      // ✅ تم إلغاء AppBar واستبداله بـ Column داخل Body مع SafeArea
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. العنوان المخصص وزر الرجوع (Custom Header)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // زر الرجوع
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: onSurfaceText),
                    onPressed: () {
                      _bleController.speak('Returning to home screen.');
                      Navigator.of(context).pop();
                    },
                  ),

                  // العنوان
                  const Expanded(
                    child: Text(
                      'Settings',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: onSurfaceText,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // مساحة فارغة لموازنة زر الرجوع
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 30), // مسافة بين العنوان وكارد الإعدادات

              // 2. كارد الإعدادات الرئيسي
              Container(
                decoration: BoxDecoration(
                  color: darkSurface, // لون البوكس #272523
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    // الخيارات
                    _buildSettingItem(context, 'Language', () => _speakOption('Language')),
                    _buildSettingItem(context, 'Updates', () => _speakOption('Updates')),
                    _buildSettingItem(context, 'Help and Feedback', () => _speakOption('Help and Feedback')),
                    _buildSettingItem(context, 'About Lumos', () => _speakOption('About Lumos')),

                    // خيار تسجيل الخروج
                    _buildSettingItem(
                        context,
                        'Logout',
                        _logout,
                        textColor: logoutColor, // استخدام اللون الأحمر المخصص للخروج
                        showDivider: false // إلغاء الفاصل أسفل زر الخروج
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}