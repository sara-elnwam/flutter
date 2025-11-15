// sign_up_screen.dart (FINAL - TRUSTING BLE_CONTROLLER TIMEOUT)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../services/ble_controller.dart';
import '../models/user_profile.dart';
import 'registration_screen.dart'; // MedicalProfileScreen
import 'dart:async';

// Custom Colors
// 🚨 لون إطار حقل الإدخال (برتقالي مطفأ)
const Color inputFieldBorderColor = Color(0xFFB26740);
const Color darkBodyBackground = Color(0xFF1B1B1B); // اللون الأغمق في الخلفية (نص زر Next)
const Color onBackground = Colors.white; // لون النص الأبيض
// 🚨 لون زر Next (برتقالي ساطع)
const Color nextButtonColor = Color(0xFFFFB267);

// 🚨 ألوان التدرج اللوني للخلفية - طبقاً لـ Figma
const Color gradientTopColor = Color(0xFF2D2929);
const Color gradientBottomColor = Color(0xFF110F0F);

// Registration Field Enumeration
enum RegistrationField {
  fullName,
  email,
  password,
  complete,
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Controllers for text input
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // State management
  RegistrationField _currentField = RegistrationField.fullName;
  String _currentLabel = 'Full Name';

  // Interaction State
  bool _isAwaitingInput = false;
  bool _isLoading = false;
  late BleController _bleController;

  @override
  void initState() {
    super.initState();

    _bleController = Provider.of<BleController>(context, listen: false);

    // 🚨 التعديل لإصلاح مشكلة TTS: استخدام PostFrameCallback لضمان تهيئة الـ context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakCurrentInstruction();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Helper to check if any interaction is ongoing
  bool get isInteractionDisabled => _isLoading || _bleController.isListening;

  // TTS Instruction Logic
  void _speakCurrentInstruction() {
    String instruction;
    switch (_currentField) {
      case RegistrationField.fullName:
        instruction = "Please say your full name.";
        break;
      case RegistrationField.email:
        instruction = "Please say your email address.";
        break;
      case RegistrationField.password:
        instruction = "Please say a strong password.";
        break;
      case RegistrationField.complete:
        instruction = "Registration fields complete. Tap the Next button or say 'Next' to continue.";
        break;
    }
    _bleController.speak(instruction);
  }

  // Voice Command Handling
  void _onLongPressStart() {
    if (_isAwaitingInput || isInteractionDisabled) return;

    setState(() {
      _isAwaitingInput = true;
    });

    _bleController.speak('Listening...');
    _bleController.startListening(
      onResult: (result) {
        // ✨ هذا سيتم استدعاؤه بعد انتهاء الاستماع (سواء بالتعرف أو بالـ Timeout)
        _handleVoiceInput(result);
      },
    );
  }

  // ⚠️ تم حذف دالة _onLongPressEnd() بالكامل.

  void _handleVoiceInput(String text) {
    if (!mounted) return;

    // ✨ التصحيح الحاسم: إعادة ضبط حالة الانتظار فور استلام النتيجة (حتى لو كانت فارغة)
    setState(() {
      _isAwaitingInput = false;
    });

    // إضافة فحص قوي لاسم المستخدم للتعامل مع النتيجة الفارغة
    if (_currentField == RegistrationField.fullName && text.trim().isEmpty) {
      _bleController.speak("Sorry, I could not hear your full name clearly. Please press and hold again to speak your name.");
      return; // إبقاء المستخدم في حقل الاسم لإعادة المحاولة
    }

    // Handle 'Next' command
    if (text.toLowerCase().contains('next') || text.toLowerCase().contains('التالي')) {
      _navigateToNextField();
      return;
    }

    // Handle data entry based on current field
    switch (_currentField) {
      case RegistrationField.fullName:
        _nameController.text = text;
        _navigateToNextField();
        break;
      case RegistrationField.email:
        _emailController.text = text.replaceAll(' ', '');
        _navigateToNextField();
        break;
      case RegistrationField.password:
        _passwordController.text = text.replaceAll(' ', '');
        _navigateToNextField();
        break;
      case RegistrationField.complete:
        break;
    }
  }

  // Navigation Logic
  void _navigateToNextField() {
    String? validationError;

    switch (_currentField) {
      case RegistrationField.fullName:
        if (_nameController.text.trim().isEmpty) {
          validationError = "Full name cannot be empty.";
        } else {
          _currentField = RegistrationField.email;
          _currentLabel = 'Email Address';
        }
        break;
      case RegistrationField.email:
        if (!_emailController.text.contains('@') || _emailController.text.length < 5) {
          validationError = "Please enter a valid email address.";
        } else {
          _currentField = RegistrationField.password;
          _currentLabel = 'Password';
        }
        break;
      case RegistrationField.password:
        if (_passwordController.text.length < 6) {
          validationError = "Password must be at least 6 characters long.";
        } else {
          _currentField = RegistrationField.complete;
          _currentLabel = 'Password';
          // لا يتم التنقل تلقائيًا، بل ينتظر ضغطة زر 'Next' أو أمر 'Next' صوتي
        }
        break;
      case RegistrationField.complete:
        _saveAndNavigateToMedicalProfile();
        return;
    }

    if (validationError != null) {
      _bleController.speak(validationError);
    } else {
      _speakCurrentInstruction();
    }
    setState(() {});
  }

  // ⭐️ دالة حفظ وتنقل معدّلة للتعامل مع نتيجة الحفظ وعرض مؤشر التحميل
  void _saveAndNavigateToMedicalProfile() async {
    if (isInteractionDisabled) return;

    setState(() {
      _isLoading = true; // بدء التحميل
    });

    _bleController.speak("Saving registration details...");

    // إنشاء نموذج المستخدم المؤقت (Temp Profile)
    final tempProfile = UserProfile(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      // تعيين الحقول المطلوبة للـ UserProfile بأي قيم افتراضية غير فارغة
      sex: 'Not Set',
      bloodType: 'Not Set',
      allergies: 'None',
      medications: 'None',
      diseases: 'None',
      // الحقول الاختيارية الأخرى
      age: 0,
      homeAddress: 'Not Set',
      emergencyPhoneNumber: 'Not Set',
      preferredVoice: 'Kore',
      isBiometricEnabled: false,
      isProfileComplete: false,
      speechRate: 0.5,
      volume: 1.0,
      localeCode: 'ar-SA',
      shakeTwiceAction: 'SilentMode',
      tapThreeTimesAction: 'EmergencyCall',
      longPressAction: 'VoiceCommand',
    );

    // التحقق من نجاح عملية الحفظ
    bool saveSuccess = true;
    try {
      // ⚠️ ملاحظة: تم تعديل دالة saveUserProfile في ble_controller.dart
      // لتقوم بإلقاء رسالة صوتية مباشرة إذا فشل الحفظ، لذا لا حاجة لـ try-catch مع speak() هنا،
      // ولكن يتم تركها لالتقاط الأخطاء العامة.
      await _bleController.saveUserProfile(tempProfile);

      // إذا وصلت إلى هنا، يعتبر الحفظ ناجحًا (سواء نجح SharedPreferences أو فشل
      // وأصدرت رسالة صوتية من داخل المتحكم)
    } catch (e) {
      print("Error during saveUserProfile call: $e");
      saveSuccess = false;
      _bleController.speak("فشل حفظ الملف الشخصي. الرجاء المحاولة مرة أخرى.");
    } finally {
      // ضمان إلغاء حالة التحميل (Loading) دائماً
      if (mounted) {
        setState(() {
          _isLoading = false; // إنهاء التحميل
        });
      }
    }

    // التنقل بعد التأكد من انتهاء عملية الحفظ
    if (saveSuccess && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MedicalProfileScreen()),
            (Route<dynamic> route) => false,
      );
    }
  }

  // --- UI Components ---

  // Widget to build the Input Field
  Widget _buildInputField(
      TextEditingController controller,
      RegistrationField field,
      String label,
      {
        bool isPassword = false,
      }) {

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        // 🚨 الخلفية شفافة
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: inputFieldBorderColor, // لون الإطار البرتقالي المطفأ
          width: 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: TextField(
          controller: controller,
          enabled: !isInteractionDisabled,
          obscureText: isPassword,
          style: const TextStyle(color: onBackground),
          textAlignVertical: TextAlignVertical.bottom,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: onBackground.withOpacity(0.7)),
            border: InputBorder.none,
            // ضبط contentPadding و isDense لارتفاع الحقل 48px
            contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20),
            // إزالة لون التعبئة (Fill Color) للحقل ليصبح شفافاً
            fillColor: Colors.transparent,
            filled: true,
            isDense: false,
          ),
          keyboardType: isPassword ? TextInputType.text : (field == RegistrationField.email ? TextInputType.emailAddress : TextInputType.text),
          textInputAction: isPassword ? TextInputAction.done : TextInputAction.next,
          onSubmitted: (_) => _navigateToNextField(),
          onTap: () {
            setState(() {
              _currentField = field;
              _currentLabel = label;
            });
            _bleController.speak("Input for $label selected. Long press the screen to speak.");
          },
        ),
      ),
    );
  }

  // Widget for the overlay when listening or loading
  Widget _buildOverlay(BleController bleController) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      constraints: const BoxConstraints.expand(),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: nextButtonColor),
            const SizedBox(height: 20),
            Text(
              _isLoading
                  ? 'Saving profile...' // تم تعديل النص ليناسب حالة الحفظ
                  : bleController.isListening
                  ? 'Listening to input...'
                  : 'Processing voice command...',
              style: const TextStyle(color: onBackground, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BleController>(
      builder: (context, bleController, child) {
        final isListening = bleController.isListening;

        return GestureDetector(
          onLongPressStart: (_) => _onLongPressStart(),
          // ⚠️ تم حذف onLongPressEnd بالكامل لعدم التداخل مع مؤقت المتحكم
          onTap: isListening ? () => _bleController.stopListening() : null,
          child: Scaffold(
            // جعل الخلفية شفافة للسماح للتدرج بالظهور
            backgroundColor: Colors.transparent,
            body: Container(
              // تطبيق التدرج اللوني الذي يملأ الشاشة بالكامل
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    gradientTopColor, // #2D2929
                    gradientBottomColor, // #110F0F
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Stack(
                children: [
                  // محتوى الشاشة
                  Column(
                    children: [
                      // الـ AppBar (شفافة وتدمج مع الخلفية)
                      AppBar(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        title: const Text(
                          'Sign Up',
                          style: TextStyle(color: onBackground, fontWeight: FontWeight.bold),
                        ),
                        centerTitle: true,
                        systemOverlayStyle: SystemUiOverlayStyle.light,
                        automaticallyImplyLeading: false,
                      ),

                      // باقي المحتوى
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 30.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Form Fields
                                    _buildInputField(
                                      _nameController,
                                      RegistrationField.fullName,
                                      'Full Name',
                                    ),
                                    _buildInputField(
                                      _emailController,
                                      RegistrationField.email,
                                      'Email Address',
                                    ),
                                    _buildInputField(
                                      _passwordController,
                                      RegistrationField.password,
                                      'Password',
                                      isPassword: true,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Next Button
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20.0),
                              child: ElevatedButton(
                                onPressed: isInteractionDisabled
                                    ? null
                                    : () => _navigateToNextField(),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: darkBodyBackground,
                                  backgroundColor: nextButtonColor, // #FFB267
                                  side: const BorderSide(
                                    color: nextButtonColor,
                                    width: 1.0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 22),
                                  elevation: 0,
                                  minimumSize: const Size(double.infinity, 68),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: darkBodyBackground,
                                    strokeWidth: 2,
                                  ),
                                )
                                    : const Text(
                                  'Next',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: darkBodyBackground,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20), // مسافة إضافية أسفل الزر
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Voice/Loading Overlay
                  if (_isAwaitingInput || bleController.isListening || _isLoading)
                    Positioned.fill(
                      child: _buildOverlay(bleController),
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