

class UserProfile {
  final String fullName;
  final String email;
  final String password;
  final String emergencyPhoneNumber;

  final String sex;
  final String bloodType;

  final String allergies;
  final String medications;
  final String diseases;
  final bool isProfileComplete;
  final int age;
  final String homeAddress;
  final String preferredVoice;
  final bool isBiometricEnabled;
  final double speechRate;
  final double volume;
  final String localeCode;

  final String shakeTwiceAction;
  final String tapThreeTimesAction;
  final String longPressAction;


  UserProfile({
    required this.fullName,
    required this.email,
    required this.password,
    required this.sex,
    required this.bloodType,
    required this.allergies,
    required this.medications,
    required this.diseases,
    this.isProfileComplete = false,

    this.age = 0,
    this.homeAddress = 'Not Set',
    this.emergencyPhoneNumber = 'Not Set',
    this.preferredVoice = 'Kore',
    this.isBiometricEnabled = false,
    this.speechRate = 0.5,
    this.volume = 1.0,
    this.localeCode = 'ar-SA',
    this.shakeTwiceAction = 'SilentMode',
    this.tapThreeTimesAction = 'EmergencyCall',
    this.longPressAction = 'VoiceCommand',
  });

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

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'email': email,
    'password': password,
    'sex': sex,
    'bloodType': bloodType,
    'allergies': allergies,
    'medications': medications,
    'diseases': diseases,
    'isProfileComplete': isProfileComplete,

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

  static UserProfile fromJson(Map<String, dynamic> json) => UserProfile(
    fullName: json['fullName'] as String? ?? '',
    email: json['email'] as String? ?? '',
    password: json['password'] as String? ?? '',
    sex: json['sex'] as String? ?? 'Not Set',
    bloodType: json['bloodType'] as String? ?? 'Not Set',
    allergies: json['allergies'] as String? ?? 'None',
    medications: json['medications'] as String? ?? 'None',
    diseases: json['diseases'] as String? ?? 'None',
    isProfileComplete: json['isProfileComplete'] as bool? ?? false,

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