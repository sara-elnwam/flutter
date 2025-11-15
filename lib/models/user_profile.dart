// lib/models/user_profile.dart (النسخة الكاملة والمحدثة)

import 'package:flutter/foundation.dart';

class UserProfile {
  // بيانات التسجيل الأساسية (Sign Up)
  final String fullName;
  final String email;
  final String password;
  final String emergencyPhoneNumber; // رقم الاتصال في حالة الطوارئ

  // حقول الملف الطبي الرئيسية (Medical Profile)
  final String sex;
  final String bloodType;

  // حقول الملف الطبي المفصلة
  final String allergies;
  final String medications; // الأدوية التي يتناولها
  final String diseases; // الأمراض المزمنة

  // إعدادات التطبيق والحالة
  final bool isProfileComplete; // حالة اكتمال الملف الشخصي
  final int age;
  final String homeAddress;
  final String preferredVoice; // اسم الصوت المفضل للـ TTS
  final bool isBiometricEnabled;
  final double speechRate;
  final double volume;
  final String localeCode; // كود اللغة/الموقع (مثل ar-SA)

  // حقول الإيماءات (يجب أن تتطابق مع أسماء الإجراءات في Controller)
  final String shakeTwiceAction;
  final String tapThreeTimesAction;
  final String longPressAction;


  UserProfile({
    // حقول التسجيل والملف الطبي الجديدة (مطلوبة)
    required this.fullName,
    required this.email,
    required this.password,
    required this.sex,
    required this.bloodType,
    required this.allergies,
    required this.medications,
    required this.diseases,
    this.isProfileComplete = false, // حالة الاكتمال (افتراضي: غير مكتمل)

    // الحقول الأخرى (افتراضيات)
    this.age = 0,
    this.homeAddress = 'Not Set',
    this.emergencyPhoneNumber = 'Not Set',
    this.preferredVoice = 'Kore',
    this.isBiometricEnabled = false,
    this.speechRate = 0.5,
    this.volume = 1.0,
    this.localeCode = 'ar-SA',
    this.shakeTwiceAction = 'SilentMode', // القيمة الافتراضية
    this.tapThreeTimesAction = 'EmergencyCall', // القيمة الافتراضية
    this.longPressAction = 'VoiceCommand', // القيمة الافتراضية
  });

  // ✅ دالة copyWith لتحديث الحقول الفردية بسهولة
  UserProfile copyWith({
    String? fullName,
    String? email,
    String? password,
    String? emergencyPhoneNumber,
    String? sex,
    String? bloodType,
    String? allergies,
    String? medications,
    String? diseases,
    bool? isProfileComplete,
    int? age,
    String? homeAddress,
    String? preferredVoice,
    bool? isBiometricEnabled,
    double? speechRate,
    double? volume,
    String? localeCode,
    String? shakeTwiceAction,
    String? tapThreeTimesAction,
    String? longPressAction,
  }) {
    return UserProfile(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      password: password ?? this.password,
      emergencyPhoneNumber: emergencyPhoneNumber ?? this.emergencyPhoneNumber,
      sex: sex ?? this.sex,
      bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies,
      medications: medications ?? this.medications,
      diseases: diseases ?? this.diseases,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      age: age ?? this.age,
      homeAddress: homeAddress ?? this.homeAddress,
      preferredVoice: preferredVoice ?? this.preferredVoice,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      speechRate: speechRate ?? this.speechRate,
      volume: volume ?? this.volume,
      localeCode: localeCode ?? this.localeCode,
      shakeTwiceAction: shakeTwiceAction ?? this.shakeTwiceAction,
      tapThreeTimesAction: tapThreeTimesAction ?? this.tapThreeTimesAction,
      longPressAction: longPressAction ?? this.longPressAction,
    );
  }

  // 👇 دالة toJson للتحويل إلى JSON (لتمكين حفظ البيانات)
  Map<String, dynamic> toJson() => {
    // حقول التسجيل والملف الطبي
    'fullName': fullName,
    'email': email,
    'password': password,
    'sex': sex,
    'bloodType': bloodType,
    'allergies': allergies,
    'medications': medications,
    'diseases': diseases,
    'isProfileComplete': isProfileComplete,

    // الحقول الأخرى
    'age': age,
    'homeAddress': homeAddress,
    'emergencyPhoneNumber': emergencyPhoneNumber,
    'preferredVoice': preferredVoice,
    'isBiometricEnabled': isBiometricEnabled,
    'speechRate': speechRate,
    'volume': volume,
    'localeCode': localeCode,
    'shakeTwiceAction': shakeTwiceAction,
    'tapThreeTimesAction': tapThreeTimesAction,
    'longPressAction': longPressAction,
  };
  // 👆 نهاية دالة toJson

  // دالة fromJson للتحويل من JSON إلى UserProfile
  static UserProfile fromJson(Map<String, dynamic> json) => UserProfile(
    // فك تشفير حقول التسجيل والملف الطبي
    fullName: json['fullName'] as String? ?? '',
    email: json['email'] as String? ?? '',
    password: json['password'] as String? ?? '',
    sex: json['sex'] as String? ?? 'Not Set',
    bloodType: json['bloodType'] as String? ?? 'Not Set',
    allergies: json['allergies'] as String? ?? 'None',
    medications: json['medications'] as String? ?? 'None',
    diseases: json['diseases'] as String? ?? 'None',
    isProfileComplete: json['isProfileComplete'] as bool? ?? false,

    // فك تشفير الحقول الأخرى (مع تحويل آمن لـ double)
    age: json['age'] as int? ?? 0,
    homeAddress: json['homeAddress'] as String? ?? 'Not Set',
    emergencyPhoneNumber: json['emergencyPhoneNumber'] as String? ?? 'Not Set',
    preferredVoice: json['preferredVoice'] as String? ?? 'Kore',
    isBiometricEnabled: json['isBiometricEnabled'] as bool? ?? false,
    speechRate: (json['speechRate'] is num ? json['speechRate'] as num : 0.5).toDouble(),
    volume: (json['volume'] is num ? json['volume'] as num : 1.0).toDouble(),
    localeCode: json['localeCode'] as String? ?? 'ar-SA',
    shakeTwiceAction: json['shakeTwiceAction'] as String? ?? 'SilentMode',
    tapThreeTimesAction: json['tapThreeTimesAction'] as String? ?? 'EmergencyCall',
    longPressAction: json['longPressAction'] as String? ?? 'VoiceCommand',
  );

  // دالة للحصول على نموذج افتراضي/أولي فارغ
  static UserProfile get initial => UserProfile(
    fullName: '',
    email: '',
    password: '',
    emergencyPhoneNumber: 'Not Set',
    sex: 'Not Set',
    bloodType: 'Not Set',
    allergies: 'None',
    medications: 'None',
    diseases: 'None',
    isProfileComplete: false,
  );
}