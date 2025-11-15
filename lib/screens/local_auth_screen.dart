// local_auth_screen.dart (FINAL MODIFIED VERSION)

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../services/ble_controller.dart';
// ✨ NEW: استيراد شاشة التسجيل الأساسية
import 'sign_up_screen.dart';
// الملف يحتوي على كلاس MedicalProfileScreen
import 'registration_screen.dart';
// تم إزالة BleScanScreen من التوجيهات النهائية
import 'main_chat_screen.dart'; // نقطة الوصول النهائية

// Custom Colors (Matching other screens)
const Color darkBackground = Color(0xFF141318);

class LocalAuthScreen extends StatefulWidget {
  final bool isPostRegistration;

  const LocalAuthScreen({super.key, this.isPostRegistration = false});

  @override
  State<LocalAuthScreen> createState() => _LocalAuthScreenState();
}

class _LocalAuthScreenState extends State<LocalAuthScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  String _message = 'Please authenticate to continue.'; // Translated: "Please authenticate to continue."
  late BleController _bleController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () async {
      _bleController = Provider.of<BleController>(context, listen: false);

      setState(() { _isLoading = false; });

      final userProfile = _bleController.userProfile;

      // SCENARIO A: First-time user (No profile exists)
      if (userProfile == null) {
        // يتم طلب البصمة أولاً قبل التوجيه لصفحة التسجيل
        _bleController.speak('Welcome. Please authenticate to start registration.');
        await _authenticateUser(
          onSuccess: () => _navigateToSignUpScreen(context), // Auth -> SignUp
          onFail: () => setState(() => _message = 'Authentication failed. Restart application to retry.'),
        );
        return;
      }

      // SCENARIO B: Returning user (Profile exists - This covers both normal login AND post-registration confirmation)
      if (userProfile.isBiometricEnabled) {
        final instruction = widget.isPostRegistration
            ? 'Please authenticate to confirm registration.'
            : 'Please authenticate with a fingerprint to continue.';

        _bleController.speak(instruction);
        await _authenticateUser(
          onSuccess: () => _navigateToNextScreen(context), // Auth -> Next Screen
          onFail: () => setState(() => _message = 'Authentication failed. Please tap to continue or retry.'),
        );
      } else {
        // إذا لم يكن البصمة مفعلة، نتوجه مباشرة للشاشة التالية (تسجيل أو رئيسية)
        _bleController.speak('Biometric authentication has been skipped. Redirecting.');
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          _navigateToNextScreen(context);
        }
      }
    });
  }

  Future<void> _authenticateUser({
    required VoidCallback onSuccess,
    required VoidCallback onFail,
  }) async {
    bool authenticated = false;
    if (mounted) setState(() => _message = 'Authenticating...');

    try {
      authenticated = await auth.authenticate(
        localizedReason: 'Scan your fingerprint (or face) to access the application.',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on Exception {
      // Handle exception
    }

    if (mounted) {
      if (authenticated) {
        _bleController.speak('Authentication successful.');
        await Future.delayed(const Duration(milliseconds: 1000));
        onSuccess();
      } else {
        _bleController.speak('Authentication failed. Please tap to continue or retry.');
        onFail();
      }
    }
  }

  // دالة التوجيه إلى شاشة التسجيل الأساسية (بعد البصمة الأولى)
  void _navigateToSignUpScreen(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const SignUpScreen()),
          (Route<dynamic> route) => false,
    );
  }

  void _navigateToNextScreen(BuildContext context) {
    // إذا كان الملف غير كامل (بعد التسجيل الأساسي)، نذهب للملف الطبي
    if (_bleController.userProfile == null || _bleController.userProfile!.isProfileComplete == false) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MedicalProfileScreen()),
            (Route<dynamic> route) => false,
      );
    } else {
      // إذا كان الملف كاملاً (يأتي من بصمة التأكيد أو عند الدخول العادي)، نذهب لشاشة المحادثة الرئيسية
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainChatScreen()),
            (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final onBackground = Theme.of(context).colorScheme.onBackground;

    return Scaffold(
      backgroundColor: darkBackground,
      // ✨ تم إزالة الـ AppBar لجعل الشاشة كاملة
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              const CircularProgressIndicator(color: Colors.white),
            if (!_isLoading)
              Text(_message, style: TextStyle(color: onBackground, fontSize: 18)),
            if (!_isLoading && _bleController.userProfile != null)
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: ElevatedButton(
                  onPressed: () {
                    // إذا كان البصمة مفعلة، حاول المصادقة مرة أخرى
                    if (_bleController.userProfile!.isBiometricEnabled) {
                      _authenticateUser(
                        onSuccess: () => _navigateToNextScreen(context),
                        onFail: () => setState(() => _message = 'Authentication failed. Please tap to continue or retry.'),
                      );
                    } else {
                      // إذا لم تكن مفعلة، استمر إلى الشاشة التالية (يجب أن يتم التعامل مع هذا في initState)
                      _navigateToNextScreen(context);
                    }
                  },
                  child: const Text('Retry / Continue'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}