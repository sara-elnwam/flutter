// action_type.dart (VERIFIED)

enum Gesture { shake_twice, tap_three_times, long_press }
enum ActionType { sos_emergency, send_location, call_contact, disable_feature } // تم تخمين هذه الإجراءات

extension GestureExtension on Gesture {
  String get displayName {
    switch (this) {
      case Gesture.shake_twice:
        return 'هز الجهاز مرتين';
      case Gesture.tap_three_times:
        return 'الضغط ثلاث مرات';
      case Gesture.long_press:
        return 'الضغط المطول';
    }
  }

  String get codeName => toString().split('.').last;
}

extension ActionTypeExtension on ActionType {
  String get displayName {
    switch (this) {
      case ActionType.sos_emergency:
        return 'نداء استغاثة (SOS)';
      case ActionType.send_location:
        return 'إرسال الموقع الجغرافي';
      case ActionType.call_contact:
        return 'الاتصال برقم الطوارئ';
      case ActionType.disable_feature:
        return 'تعطيل الميزة (إيقاف)';
    }
  }

  String get codeName => toString().split('.').last;

  static ActionType fromCodeName(String codeName) {
    return ActionType.values.firstWhere(
          (e) => e.toString().split('.').last == codeName,
      orElse: () => ActionType.disable_feature,
    );
  }
}