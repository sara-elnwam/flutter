// lib/services/ble_controller.dart - الكود المعدّل والنهائي

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, listEquals, kDebugMode;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ تم استيرادها

// استيراد النماذج والتعدادات
import '../models/user_profile.dart';
import '../enums/action_type.dart';

// -----------------------------------------------------------------
// 1. الثوابت الرئيسية (BLE)
// -----------------------------------------------------------------
const String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
const String DATA_CHAR_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
const String CONFIG_CHAR_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a7";

const String USER_PROFILE_KEY = 'user_profile_data';

// -----------------------------------------------------------------
// 2. BleController (المنطق الكامل والمعدّل)
// -----------------------------------------------------------------

class BleController with ChangeNotifier {
  // TTS و STT والـ Gemini
  final FlutterTts _flutterTts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  String _lastWords = '';
  bool _speechToTextInitialized = false;
  late final GenerativeModel _model;
  // NOTE: يجب تغيير هذا المفتاح إلى مفتاح صالح للاستخدام
  final String _geminiApiKey = 'AIzaSyBwOMGLGl6GJsKkgvyT2Mz57vmdNWhOZJI';

  // حالة الـ STT Timeout
  Timer? _sttTimeoutTimer;
  final Duration _maxListeningDuration = const Duration(seconds: 7);

  // ملف المستخدم
  late SharedPreferences _prefs; // ✅ يجب تهيئتها في initializeController
  UserProfile? _userProfile;
  UserProfile? get userProfile => _userProfile;
  double get speechRate => _userProfile?.speechRate ?? 0.5;
  double get volume => _userProfile?.volume ?? 1.0;
  String get localeCode => _userProfile?.localeCode ?? 'ar-SA';

  set userProfile(UserProfile? profile) {
    _userProfile = profile;
    notifyListeners();
  }

  // إعدادات الإيماءات (يتم إرسالها إلى الجهاز)
  Map<String, ActionType> _gestureConfig = {
    'shakeTwiceAction': ActionType.sos_emergency,
    'tapThreeTimesAction': ActionType.call_contact,
    'longPressAction': ActionType.disable_feature,
  };
  Map<String, ActionType> get gestureConfig => _gestureConfig;

  // حالة الـ BLE
  final List<ScanResult> scanResults = [];
  BluetoothDevice? connectedDevice;
  bool _isScanning = false;
  bool _isConnecting = false;
  String _receivedDataMessage = 'لا توجد بيانات مستلمة بعد.';
  StreamSubscription<List<int>>? _dataSubscription;

  bool get isListening => _isListening;
  String get lastWords => _lastWords;
  bool get isScanning => _isScanning;
  bool get isConnecting => _isConnecting;
  String get receivedDataMessage => _receivedDataMessage;
  bool get isConnected => connectedDevice != null;

  // -----------------------------------------------------------------
  // التهيئة
  // -----------------------------------------------------------------

  BleController() {
    if (_geminiApiKey.isNotEmpty && _geminiApiKey != 'YOUR_GEMINI_API_KEY') {
      _model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _geminiApiKey,
      );
      if (kDebugMode) print("✅ Gemini Model Initialized.");
    } else {
      if (kDebugMode) print("❌ Gemini API Key is missing or invalid.");
      // تهيئة نموذج وهمي لتجنب الانهيار
      _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: 'DUMMY_KEY');
    }
  }

  Future<void> initializeController() async {
    _prefs = await SharedPreferences.getInstance(); // ✅ تهيئة Shared Preferences
    await _loadUserProfile(); // ✅ تحميل الملف الشخصي
    await _configureTtsSettings();
    await initSpeech();
    notifyListeners();
  }

  // -----------------------------------------------------------------
  // إدارة ملف المستخدم (SharedPreferences) - ✅ الجزء المعدّل
  // -----------------------------------------------------------------

  // ✅ دالة تحميل الملف الشخصي
  Future<void> _loadUserProfile() async {
    final String? jsonString = _prefs.getString(USER_PROFILE_KEY);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
        _userProfile = UserProfile.fromJson(jsonMap);
        if (kDebugMode) print("UserProfile loaded successfully.");
      } catch (e) {
        if (kDebugMode) print("Error loading UserProfile: $e");
        _userProfile = UserProfile.initial; // استخدام الملف الأولي في حالة الخطأ
      }
    } else {
      // استخدام UserProfile.initial لتوفير بيانات تسجيل دخول افتراضية فارغة
      _userProfile = UserProfile.initial;
      if (kDebugMode) print("No UserProfile found in storage. Using initial.");
    }
  }

  // ✅ دالة حفظ الملف الشخصي (تم تعديلها لتصدر رسالة صوتية عند الفشل)
  Future<bool> saveUserProfile(UserProfile profile) async {
    try {
      final jsonString = jsonEncode(profile.toJson());
      await _prefs.setString(USER_PROFILE_KEY, jsonString);

      // تحديث الحالة الداخلية
      _userProfile = profile;
      await _configureTtsSettings();
      notifyListeners();

      if (kDebugMode) print("UserProfile saved and TTS settings updated successfully: ${profile.fullName}");
      return true; // نجاح الحفظ
    } catch (e) {
      if (kDebugMode) print("CRITICAL ERROR: Failed to save user profile: $e");
      // إصدار رسالة صوتية للمستخدم عند الفشل
      await speak("فشل حفظ الملف الشخصي. الرجاء المحاولة مرة أخرى.");
      return false; // فشل الحفظ
    }
  }


  // دالة لمسح ملف المستخدم (تسجيل الخروج)
  Future<void> clearUserProfile() async {
    _userProfile = UserProfile.initial;
    await _prefs.remove(USER_PROFILE_KEY);
    notifyListeners();
    if (kDebugMode) print("User profile cleared (Logout).");
  }

  // -----------------------------------------------------------------
  // إعدادات TTS
  // -----------------------------------------------------------------

  Future<void> _configureTtsSettings() async {
    await _flutterTts.setSpeechRate(speechRate);
    await _flutterTts.setVolume(volume);

    try {
      await _flutterTts.setLanguage(localeCode);
    } catch (e) {
      await _flutterTts.setLanguage("ar-SA");
      if (kDebugMode) print("Warning: Locale $localeCode could not be set. Using ar-SA. Error: $e");
    }
  }

  // تحديث إعدادات TTS وحفظها في الملف الشخصي
  Future<void> updateTtsSettings({double? rate, double? vol, String? locale}) async {
    if (_userProfile == null) return;

    // استخدام copyWith لتحديث الحقول الفردية مع الاحتفاظ بالباقي
    final updatedProfile = _userProfile!.copyWith(
      speechRate: rate,
      volume: vol,
      localeCode: locale,
    );

    await saveUserProfile(updatedProfile);
  }

  // -----------------------------------------------------------------
  // دوال TTS (النطق)
  // -----------------------------------------------------------------

  Future<void> speak(String text) async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
      _isListening = false;
    }

    // إعداد معالج الإكمال قبل النطق
    _flutterTts.setCompletionHandler(() {
      notifyListeners(); // لتحديث حالة speaking إذا أردنا تتبعها
    });

    await _flutterTts.stop();
    await _flutterTts.speak(text);
    notifyListeners();
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  // دالة مساعدة لإنشاء وإلقاء رسالة تأكيد الاسم (للاستخدام في شاشة التسجيل)
  Future<void> confirmNamePrompt(String name) async {
    // بناء رسالة التوجيه المطلوبة من المستخدم
    final message = '''
      الاسم الذي تم التقاطه هو: $name. 
      إذا كان صحيحاً، يرجى الضغط مرتين (Double Tap) للانتقال إلى الحقل التالي. 
      وإذا كان خاطئاً، يرجى الضغط ثلاث مرات (Triple Tap) لإعادة تسجيل الاسم.
      ''';
    await speak(message);
  }

  // -----------------------------------------------------------------
  // دوال STT (التعرف على الكلام) - لم يتم تعديلها بناء على طلبك
  // -----------------------------------------------------------------

  Future<bool> initSpeech() async {
    if (_speechToTextInitialized) return true;

    // 1. طلب إذن الميكروفون
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      await speak("الرجاء منح إذن الميكروفون لاستخدام المساعد الصوتي.");
      return false;
    }

    try {
      _speechToTextInitialized = await _speechToText.initialize(
        onError: (e) => { if (kDebugMode) print('STT Error: $e') },
      );
      if (_speechToTextInitialized) {
        if (kDebugMode) print('✅ SpeechToText Initialized.');
      } else {
        if (kDebugMode) print('❌ SpeechToText failed to initialize.');
        await speak('عذراً، لا يمكن تهيئة خاصية التعرف الصوتي على هذا الجهاز.');
      }
      return _speechToTextInitialized; // إرجاع الحالة النهائية
    } catch (e) {
      if (kDebugMode) print("Error initializing STT: $e");
      return false;
    }
  }

  // دالة لبدء الاستماع وإعادة النتيجة إلى الواجهة
  // تم إزالة الربط التلقائي بـ Gemini هنا
  void startListening({required Function(String) onResult}) async {
    // التأكد من التهيئة قبل البدء
    if (!_speechToTextInitialized) {
      final initialized = await initSpeech();
      if (!initialized) return;
    }

    if (_speechToText.isListening) return;

    _isListening = true;
    _lastWords = '';
    notifyListeners();

    // 1. بدء المؤقت (Timeout Timer)
    _sttTimeoutTimer?.cancel();
    _sttTimeoutTimer = Timer(_maxListeningDuration, () {
      if (kDebugMode) print('STT Timeout: Forcing result resolution after 7 seconds.');
      stopListening(shouldSpeakStop: false);
      // إرسال النتيجة إلى الواجهة (حتى لو كانت فارغة بسبب Timeout)
      onResult(_lastWords);
    });

    try {
      await _speechToText.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          notifyListeners();
          if (result.finalResult) {
            // 2. إلغاء المؤقت عند الحصول على نتيجة
            _sttTimeoutTimer?.cancel();
            stopListening(shouldSpeakStop: false);
            // إرسال النتيجة النهائية إلى الواجهة (للتطبيق أو للتحقق)
            onResult(_lastWords);
          }
        },
        localeId: localeCode,
      );
    } catch (e) {
      if (kDebugMode) print("Error during listening: $e");
      _sttTimeoutTimer?.cancel();
      stopListening(shouldSpeakStop: false);
      // إرسال نتيجة فارغة في حالة حدوث خطأ
      onResult('');
    }
  }

  void stopListening({bool shouldSpeakStop = true}) {
    // 3. إلغاء المؤقت عند الإيقاف اليدوي أو عن طريق النتيجة
    _sttTimeoutTimer?.cancel();

    if (_speechToText.isListening) {
      _speechToText.stop();
      _isListening = false;
      notifyListeners();
    } else if (!_speechToText.isListening && _isListening) {
      _isListening = false;
      notifyListeners();
    }
  }

  // -----------------------------------------------------------------
  // دوال Gemini API - أصبحت تُستدعى يدوياً من الواجهة عند الحاجة
  // -----------------------------------------------------------------

  Future<void> getGeminiResponse(String prompt) async {
    if (_geminiApiKey.isEmpty || _geminiApiKey == 'YOUR_GEMINI_API_KEY') {
      await speak('عفواً، خدمة المساعد الذكي غير متاحة. يرجى تزويد مفتاح API صالح.');
      return;
    }

    // نطق رسالة إيجابية قبل الاتصال بـ API
    await speak('حسناً، جاري معالجة طلبك: $prompt');

    try {
      final response = await _model.generateContent([
        Content.text(prompt)
      ]);
      final geminiText = response.text ?? 'عذراً، لم أتلق رداً واضحاً من المساعد الذكي.';
      await speak(geminiText);
    } catch (e) {
      if (kDebugMode) print("Gemini API Error: $e");
      await speak('حدث خطأ أثناء التواصل مع المساعد الذكي. الرجاء التأكد من اتصال الإنترنت.');
    }
  }


  // -----------------------------------------------------------------
  // دوال BLE
  // -----------------------------------------------------------------

  Future<void> startScan() async {
    // طلب الأذونات الضرورية
    if (!kIsWeb) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.location,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();

      if (statuses.values.any((s) => s != PermissionStatus.granted)) {
        await speak("الرجاء منح أذونات الموقع والبلوتوث لبدء البحث عن الأجهزة.");
        return;
      }
    }

    if (!await FlutterBluePlus.isSupported) {
      await speak("هذا الجهاز لا يدعم تقنية البلوتوث.");
      return;
    }

    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      await speak("الرجاء تفعيل البلوتوث للمتابعة.");
      return;
    }

    if (_isScanning) return;

    _isScanning = true;
    scanResults.clear();
    notifyListeners();
    await speak("جاري البحث عن أجهزة ذكية في النطاق...");

    try {
      await FlutterBluePlus.startScan(
        withServices: [Guid(SERVICE_UUID)],
        timeout: const Duration(seconds: 4),
      );

      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          if (!scanResults.any((e) => e.device.remoteId == r.device.remoteId)) {
            scanResults.add(r);
          }
        }
        notifyListeners();
      });

      FlutterBluePlus.isScanning.listen((isScanning) {
        if (!isScanning) {
          _isScanning = false;
          notifyListeners();
          if (scanResults.isEmpty) {
            speak("لم يتم العثور على أي أجهزة ذكية في النطاق.");
          } else {
            speak("تم العثور على ${scanResults.length} جهاز.");
          }
        }
      });
    } catch (e) {
      if (kDebugMode) print("Scan error: $e");
      await speak("حدث خطأ أثناء مسح أجهزة البلوتوث.");
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _isScanning = false;
    notifyListeners();
    if (kDebugMode) print("Scanning stopped.");
  }

  Future<void> connect(BluetoothDevice device) async {
    if (_isConnecting || connectedDevice != null) return;

    _isConnecting = true;
    notifyListeners();
    await speak("جاري محاولة الاتصال بالجهاز: ${device.platformName}");

    try {
      await device.connect(timeout: const Duration(seconds: 15));

      connectedDevice = device;
      _isConnecting = false;
      notifyListeners();
      await speak("تم الاتصال بالجهاز بنجاح. النظام جاهز للعمل.");
      if (kDebugMode) print("Connected to device: ${device.remoteId}");

      await _subscribeToDataCharacteristic(device);

    } on FlutterBluePlusException catch (e) {
      if (kDebugMode) print("Connection failed: $e");
      await speak("فشل الاتصال بالجهاز. الرجاء المحاولة مرة أخرى.");
      _isConnecting = false;
      connectedDevice = null;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    if (connectedDevice != null) {
      await _dataSubscription?.cancel();
      await connectedDevice!.disconnect();
      connectedDevice = null;
      _receivedDataMessage = 'لا توجد بيانات مستلمة بعد.';
      notifyListeners();
      await speak("تم قطع الاتصال بالجهاز بنجاح.");
      if (kDebugMode) print("Disconnected.");
    }
  }

  Future<void> _subscribeToDataCharacteristic(BluetoothDevice device) async {
    final characteristic = await _findServiceCharacteristic(
        device, SERVICE_UUID, DATA_CHAR_UUID);

    if (characteristic != null) {
      await characteristic.setNotifyValue(true);
      _dataSubscription = characteristic.value.listen((value) {
        if (value.isNotEmpty) {
          final command = utf8.decode(value);
          _handleReceivedData(command);
        }
      });
      if (kDebugMode) print('Subscribed to data characteristic.');
    } else {
      if (kDebugMode) print('Data characteristic not found!');
      await speak('عذراً، لم يتم العثور على قناة البيانات الرئيسية.');
    }
  }

  void _handleReceivedData(String command) {
    if (kDebugMode) print('Received: $command');

    final spokenMessage = _mapCommandToMessage(command);
    speak(spokenMessage);

    _receivedDataMessage = spokenMessage;
    notifyListeners();
  }

  // محاكاة استقبال البيانات (لشاشة ble_scan_screen)
  Future<void> sendMockData(String command) async {
    if (command.isNotEmpty) {
      _handleReceivedData(command);
    }
  }

  Future<void> sendGestureConfig(Map<String, ActionType> config) async {
    _gestureConfig = config;
    notifyListeners();

    if (connectedDevice == null) {
      await speak("الرجاء الاتصال بالجهاز الذكي أولاً لحفظ الإعدادات.");
      return;
    }

    final characteristic = await _findServiceCharacteristic(
        connectedDevice!, SERVICE_UUID, CONFIG_CHAR_UUID);

    if (characteristic != null) {
      try {
        // تحويل مفاتيح التعداد إلى سلاسل نصية عند الإرسال
        final jsonString = jsonEncode(config.map((key, value) =>
            MapEntry(key, value.toString().split('.').last)));

        await characteristic.write(utf8.encode(jsonString), withoutResponse: true);
        await speak("تم إرسال إعدادات الإيماءات بنجاح إلى الجهاز.");
        if (kDebugMode) print("Sent config: $jsonString");

      } catch (e) {
        await speak("فشل إرسال الإعدادات إلى الجهاز.");
        if (kDebugMode) print("Failed to write characteristic: $e");
      }
    } else {
      await speak("عذراً، لم يتم العثور على قناة إرسال الإعدادات.");
    }
  }

  String _mapCommandToMessage(String command) {
    switch (command.toUpperCase()) {
      case 'OBSTACLE_FRONT':
        return 'عائق أمامي! توقف!';
      case 'OBSTACLE_LEFT':
        return 'عائق على اليسار. كن حذراً.';
      case 'GESTURE_SOS':
        return 'تم تفعيل إيماءة الاستغاثة. جاري إرسال نداء SOS.';
      case 'GESTURE_CALL':
        return 'تم تفعيل إيماءة الاتصال. جاري الاتصال برقم الطوارئ.';
      case 'BATTERY_LOW':
        return 'البطارية منخفضة. يرجى الشحن قريباً.';
      case 'SETTINGS_ACK':
        return 'تم تأكيد الإعدادات بنجاح.';
      default:
        return 'تم استلام أمر غير معروف: $command.';
    }
  }

  Future<BluetoothCharacteristic?> _findServiceCharacteristic(
      BluetoothDevice device, String serviceUuid, String charUuid) async {

    List<BluetoothService> services = await device.discoverServices();

    final candidates = services
        .where((s) => s.uuid.str.toLowerCase() == serviceUuid.toLowerCase())
        .toList();

    final customService = candidates.isNotEmpty ? candidates.first : null;

    if (customService != null) {
      final charCandidates = customService.characteristics
          .where((c) => c.uuid.str.toLowerCase() == charUuid.toLowerCase())
          .toList();

      return charCandidates.isNotEmpty ? charCandidates.first : null;
    }

    return null;
  }

  // -----------------------------------------------------------------
  // التخلص من الموارد
  // -----------------------------------------------------------------

  @override
  void dispose() {
    _sttTimeoutTimer?.cancel();
    _speechToText.stop();
    _flutterTts.stop();
    _dataSubscription?.cancel();
    // تجنب قطع الاتصال هنا لأنه قد يتم استخدام المتحكم في شاشات أخرى، ولكن يمكن تركه اختيارياً
    // connectedDevice?.disconnect();
    super.dispose();
  }
}