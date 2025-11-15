
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, listEquals, kDebugMode;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';
import '../enums/action_type.dart';

const String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
const String DATA_CHAR_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
const String CONFIG_CHAR_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a7";

const String USER_PROFILE_KEY = 'user_profile_data';

class BleController with ChangeNotifier {
  final FlutterTts _flutterTts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  String _lastWords = '';
  bool _speechToTextInitialized = false;
  late final GenerativeModel _model;
  final String _geminiApiKey = 'AIzaSyBwOMGLGl6GJsKkgvyT2Mz57vmdNWhOZJI';

  Timer? _sttTimeoutTimer;
  final Duration _maxListeningDuration = const Duration(seconds: 7);

  late SharedPreferences _prefs;
  UserProfile? _userProfile;
  UserProfile? get userProfile => _userProfile;
  double get speechRate => _userProfile?.speechRate ?? 0.5;
  double get volume => _userProfile?.volume ?? 1.0;
  String get localeCode => _userProfile?.localeCode ?? 'ar-SA';

  set userProfile(UserProfile? profile) {
    _userProfile = profile;
    notifyListeners();
  }

  Map<String, ActionType> _gestureConfig = {
    'shakeTwiceAction': ActionType.sos_emergency,
    'tapThreeTimesAction': ActionType.call_contact,
    'longPressAction': ActionType.disable_feature,
  };
  Map<String, ActionType> get gestureConfig => _gestureConfig;

  final List<ScanResult> scanResults = [];
  BluetoothDevice? connectedDevice;
  bool _isScanning = false;
  bool _isConnecting = false;
  String _receivedDataMessage = 'No data received yet.';
  StreamSubscription<List<int>>? _dataSubscription;

  bool get isListening => _isListening;
  String get lastWords => _lastWords;
  bool get isScanning => _isScanning;
  bool get isConnecting => _isConnecting;
  String get receivedDataMessage => _receivedDataMessage;
  bool get isConnected => connectedDevice != null;

  BleController() {
    if (_geminiApiKey.isNotEmpty && _geminiApiKey != 'YOUR_GEMINI_API_KEY') {
      _model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _geminiApiKey,
      );
      if (kDebugMode) print("✅ Gemini Model Initialized.");
    } else {
      if (kDebugMode) print("❌ Gemini API Key is missing or invalid.");
      _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: 'DUMMY_KEY');
    }
  }

  Future<void> initializeController() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadUserProfile();
    await _configureTtsSettings();
    await initSpeech();
    notifyListeners();
  }

  Future<void> _loadUserProfile() async {
    final String? jsonString = _prefs.getString(USER_PROFILE_KEY);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
        _userProfile = UserProfile.fromJson(jsonMap);
        if (kDebugMode) print("UserProfile loaded successfully.");
      } catch (e) {
        if (kDebugMode) print("Error loading UserProfile: $e");
        _userProfile = UserProfile.initial;
      }
    } else {
      _userProfile = UserProfile.initial;
      if (kDebugMode) print("No UserProfile found in storage. Using initial.");
    }
  }

  Future<bool> saveUserProfile(UserProfile profile) async {
    try {
      final jsonString = jsonEncode(profile.toJson());
      await _prefs.setString(USER_PROFILE_KEY, jsonString);

      _userProfile = profile;
      await _configureTtsSettings();
      notifyListeners();

      if (kDebugMode) print("UserProfile saved and TTS settings updated successfully: ${profile.fullName}");
      return true;
    } catch (e) {
      if (kDebugMode) print("CRITICAL ERROR: Failed to save user profile: $e");
      await speak("Profile save failed. Please try again.");
      return false;
    }
  }


  Future<void> clearUserProfile() async {
    _userProfile = UserProfile.initial;
    await _prefs.remove(USER_PROFILE_KEY);
    notifyListeners();
    if (kDebugMode) print("User profile cleared (Logout).");
  }

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

  Future<void> updateTtsSettings({double? rate, double? vol, String? locale}) async {
    if (_userProfile == null) return;

    final updatedProfile = _userProfile!.copyWith(
      speechRate: rate,
      volume: vol,
      localeCode: locale,
    );

    await saveUserProfile(updatedProfile);
  }

  Future<void> speak(String text) async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
      _isListening = false;
    }

    _flutterTts.setCompletionHandler(() {
      notifyListeners();
    });

    await _flutterTts.stop();
    await _flutterTts.speak(text);
    notifyListeners();
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  Future<void> confirmNamePrompt(String name) async {
    final message = '''
      The name captured is: $name. 
      If correct, please Double Tap to proceed to the next field. 
      If incorrect, please Triple Tap to re-record the name.
      ''';
    await speak(message);
  }

  Future<bool> initSpeech() async {
    if (_speechToTextInitialized) return true;

    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      await speak("Please grant microphone permission to use the voice assistant.");
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
        await speak('Sorry, voice recognition cannot be initialized on this device.');
      }
      return _speechToTextInitialized;
    } catch (e) {
      if (kDebugMode) print("Error initializing STT: $e");
      return false;
    }
  }

  void startListening({required Function(String) onResult}) async {
    if (!_speechToTextInitialized) {
      final initialized = await initSpeech();
      if (!initialized) return;
    }

    if (_speechToText.isListening) return;

    _isListening = true;
    _lastWords = '';
    notifyListeners();

    _sttTimeoutTimer?.cancel();
    _sttTimeoutTimer = Timer(_maxListeningDuration, () {
      if (kDebugMode) print('STT Timeout: Forcing result resolution after 7 seconds.');
      stopListening(shouldSpeakStop: false);
      onResult(_lastWords);
    });

    try {
      await _speechToText.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          notifyListeners();
          if (result.finalResult) {
            _sttTimeoutTimer?.cancel();
            stopListening(shouldSpeakStop: false);
            onResult(_lastWords);
          }
        },
        localeId: localeCode,
      );
    } catch (e) {
      if (kDebugMode) print("Error during listening: $e");
      _sttTimeoutTimer?.cancel();
      stopListening(shouldSpeakStop: false);
      onResult('');
    }
  }

  void stopListening({bool shouldSpeakStop = true}) {
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

  Future<void> getGeminiResponse(String prompt) async {
    if (_geminiApiKey.isEmpty || _geminiApiKey == 'YOUR_GEMINI_API_KEY') {
      await speak('Sorry, the smart assistant service is not available. Please provide a valid API key.');
      return;
    }

    await speak('Okay, processing your request: $prompt');

    try {
      final response = await _model.generateContent([
        Content.text(prompt)
      ]);
      final geminiText = response.text ?? 'Sorry, I did not receive a clear response from the smart assistant.';
      await speak(geminiText);
    } catch (e) {
      if (kDebugMode) print("Gemini API Error: $e");
      await speak('An error occurred while communicating with the smart assistant. Please check your internet connection.');
    }
  }


  Future<void> startScan() async {
    if (!kIsWeb) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.location,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();

      if (statuses.values.any((s) => s != PermissionStatus.granted)) {
        await speak("Please grant location and Bluetooth permissions to start scanning for devices.");
        return;
      }
    }

    if (!await FlutterBluePlus.isSupported) {
      await speak("This device does not support Bluetooth technology.");
      return;
    }

    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      await speak("Please enable Bluetooth to continue.");
      return;
    }

    if (_isScanning) return;

    _isScanning = true;
    scanResults.clear();
    notifyListeners();
    await speak("Scanning for smart devices in range...");

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
            speak("No smart devices found in range.");
          } else {
            speak("Found ${scanResults.length} devices.");
          }
        }
      });
    } catch (e) {
      if (kDebugMode) print("Scan error: $e");
      await speak("An error occurred while scanning for Bluetooth devices.");
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
    await speak("Attempting to connect to device: ${device.platformName}");

    try {
      await device.connect(timeout: const Duration(seconds: 15));

      connectedDevice = device;
      _isConnecting = false;
      notifyListeners();
      await speak("Successfully connected to the device. The system is ready.");
      if (kDebugMode) print("Connected to device: ${device.remoteId}");

      await _subscribeToDataCharacteristic(device);

    } on FlutterBluePlusException catch (e) {
      if (kDebugMode) print("Connection failed: $e");
      await speak("Connection to the device failed. Please try again.");
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
      _receivedDataMessage = 'No data received yet.';
      notifyListeners();
      await speak("Disconnected from the device successfully.");
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
      await speak('Sorry, the main data channel was not found.');
    }
  }

  void _handleReceivedData(String command) {
    if (kDebugMode) print('Received: $command');

    final spokenMessage = _mapCommandToMessage(command);
    speak(spokenMessage);

    _receivedDataMessage = spokenMessage;
    notifyListeners();
  }

  Future<void> sendMockData(String command) async {
    if (command.isNotEmpty) {
      _handleReceivedData(command);
    }
  }

  Future<void> sendGestureConfig(Map<String, ActionType> config) async {
    _gestureConfig = config;
    notifyListeners();

    if (connectedDevice == null) {
      await speak("Please connect to the smart device first to save the settings.");
      return;
    }

    final characteristic = await _findServiceCharacteristic(
        connectedDevice!, SERVICE_UUID, CONFIG_CHAR_UUID);

    if (characteristic != null) {
      try {
        final jsonString = jsonEncode(config.map((key, value) =>
            MapEntry(key, value.toString().split('.').last)));

        await characteristic.write(utf8.encode(jsonString), withoutResponse: true);
        await speak("Gesture settings successfully sent to the device.");
        if (kDebugMode) print("Sent config: $jsonString");

      } catch (e) {
        await speak("Failed to send settings to the device.");
        if (kDebugMode) print("Failed to write characteristic: $e");
      }
    } else {
      await speak("Sorry, the settings transmission channel was not found.");
    }
  }

  String _mapCommandToMessage(String command) {
    switch (command.toUpperCase()) {
      case 'OBSTACLE_FRONT':
        return 'Obstacle ahead! Stop!';
      case 'OBSTACLE_LEFT':
        return 'Obstacle on the left. Be careful.';
      case 'GESTURE_SOS':
        return 'SOS gesture activated. Sending SOS call.';
      case 'GESTURE_CALL':
        return 'Call gesture activated. Calling emergency number.';
      case 'BATTERY_LOW':
        return 'Battery low. Please charge soon.';
      case 'SETTINGS_ACK':
        return 'Settings successfully confirmed.';
      default:
        return 'Unknown command received: $command.';
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

  @override
  void dispose() {
    _sttTimeoutTimer?.cancel();
    _speechToText.stop();
    _flutterTts.stop();
    _dataSubscription?.cancel();
    super.dispose();
  }
}