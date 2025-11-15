// registration_screen.dart (FINAL FIX: Fixed 'field' typo in _applyAndMoveToNextField)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../models/user_profile.dart';
import '../services/ble_controller.dart';
import 'dart:async';
// Navigation Target (Biometrics) - REMOVED
// import 'local_auth_screen.dart';
import 'allergies_detail_screen.dart'; // Allergies Screen
import 'medications_detail_screen.dart'; // Medications & Diseases Screen
import 'sign_up_screen.dart'; // Sign Up Screen for navigation
import 'main_chat_screen.dart'; // <<<--- [تم التعديل] استخدام مسار '../' للوصول للمجلد الأب (lib/).

// Custom Colors (Based on Figma image_a4505a.png)
const Color accentColor = Color(0xFFFFB267); // The bright orange/accent color from Figma border (#FFB267)
const Color darkBackground = Color(0xFF1B1B1B); // Very Dark Background
const Color inputSurfaceColor = Color(0x992B2B2B); // Field background: #2B2B2B at 60% opacity (0x99 = 60% of 0xFF)
const Color onBackground = Color(0xFFF8F8F8); // White text (for titles and main content)

// Define fields
enum MedicalField {
  sex,
  bloodType,
  allergies,
  medications,
  diseases,
  complete,
}

class MedicalProfileScreen extends StatefulWidget {
  const MedicalProfileScreen({super.key});

  @override
  State<MedicalProfileScreen> createState() => _MedicalProfileScreenState();
}

class _MedicalProfileScreenState extends State<MedicalProfileScreen> {
  MedicalField _currentField = MedicalField.sex;

  String _selectedSex = '';
  String _selectedBloodType = '';
  String _selectedAllergies = 'None';
  String _selectedMedications = 'None';
  String _selectedDiseases = 'None';

  bool _isSexDropdownOpen = false;
  bool _isBloodTypeDropdownOpen = false;

  bool _isLoading = false;
  bool _isAwaitingInput = false;
  String _currentValueForConfirmation = '';

  late BleController _bleController;

  int _tapCount = 0;
  Timer? _tapResetTimer;
  final Duration _tapTimeout = const Duration(milliseconds: 600);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _bleController = Provider.of<BleController>(context, listen: false);
      _loadCurrentProfile();
      _speakInstruction(
          'Medical profile setup. Current field is Sex. Double-tap to open the dropdown or long-press for voice input.');
    });
  }

  @override
  void dispose() {
    _tapResetTimer?.cancel();
    _bleController.stopListening(shouldSpeakStop: false);
    super.dispose();
  }

  void _loadCurrentProfile() {
    final profile = _bleController.userProfile;
    if (profile != null) {
      if (mounted) {
        setState(() {
          _selectedSex = profile.sex == 'Not Set' ? '' : profile.sex;
          _selectedBloodType = profile.bloodType == 'Not Set' ? '' : profile.bloodType;
          _selectedAllergies = profile.allergies == 'None' ? 'None' : profile.allergies;
          _selectedMedications = profile.medications == 'None' ? 'None' : profile.medications;
          _selectedDiseases = profile.diseases == 'None' ? 'None' : profile.diseases;
        });
      }
    }
  }

  String _getFieldTitle(MedicalField field) {
    switch (field) {
      case MedicalField.sex: return 'Sex';
      case MedicalField.bloodType: return 'Blood Type';
      case MedicalField.allergies: return 'Allergies';
      case MedicalField.medications: return 'Medications';
      case MedicalField.diseases: return 'Chronic Diseases';
      case MedicalField.complete: return 'Save Profile';
    }
  }

  void _speakInstruction(String instruction) {
    if (!mounted) return;
    _bleController.speak(instruction);
  }

  void _onLongPressStart(BleController bleController) {
    if (_isLoading || bleController.isListening || _currentField.index >= MedicalField.allergies.index) {
      if (_currentField.index >= MedicalField.allergies.index) {
        _speakInstruction('Voice input is not available here. Double-tap to enter the detail screen.');
      }
      return;
    }

    setState(() {
      _isSexDropdownOpen = false;
      _isBloodTypeDropdownOpen = false;
      _isAwaitingInput = true;
    });

    final fieldName = _getFieldTitle(_currentField);
    _speakInstruction('Recording started. Say $fieldName now.');

    bleController.startListening(
      onResult: (spokenText) {
        if (mounted) {
          setState(() {
            _isAwaitingInput = false;
            _currentValueForConfirmation = spokenText.toLowerCase().trim();
          });
          if (_currentValueForConfirmation.isNotEmpty) {
            _handleVoiceInput(_currentValueForConfirmation);
          } else {
            _speakInstruction('Could not recognize your speech. Try again by long-pressing.');
          }
        }
      },
    );
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (_bleController.isListening) {
      _bleController.stopListening(shouldSpeakStop: false);
    }
  }

  void _handleVoiceInput(String spokenText) {
    String message = 'Input recorded. Double-tap to confirm and move next, or triple-tap to re-record.';
    bool isHandled = false;

    if (_currentField == MedicalField.sex) {
      if (spokenText.contains('male') || spokenText.contains('ذكر') || spokenText.contains('رجل')) {
        _currentValueForConfirmation = 'Male';
        isHandled = true;
      } else if (spokenText.contains('female') || spokenText.contains('انثى') || spokenText.contains('امرأة')) {
        _currentValueForConfirmation = 'Female';
        isHandled = true;
      } else {
        message = 'Sex not recognized. Say "male" or "female".';
        _currentValueForConfirmation = '';
      }
    } else if (_currentField == MedicalField.bloodType) {
      final validBloodTypes = ['a+', 'a-', 'b+', 'b-', 'ab+', 'ab-', 'o+', 'o-'];
      final cleanedText = spokenText
          .replaceAll(' ', '')
          .replaceAll('positive', '+')
          .replaceAll('negative', '-')
          .replaceAll('minus', '-')
          .replaceAll('plus', '+');

      if (validBloodTypes.contains(cleanedText)) {
        _currentValueForConfirmation = cleanedText.toUpperCase();
        isHandled = true;
      } else {
        message = 'Invalid blood type. Say A positive, B negative, etc.';
        _currentValueForConfirmation = '';
      }
    }

    if (isHandled && _currentValueForConfirmation.isNotEmpty) {
      message = 'Recorded: ${_currentValueForConfirmation}. Double-tap to confirm and move to the next field.';
    }

    _speakInstruction(message);
  }

  void _handleScreenTap() {
    if (_isLoading) return;
    _tapCount++;
    _tapResetTimer?.cancel();
    _tapResetTimer = Timer(_tapTimeout, () => _processTapCount());
  }

  void _processTapCount() {
    final int count = _tapCount;
    _tapCount = 0;

    if (count == 2) {
      _handleDoubleTap();
    } else if (count == 3) {
      _handleTripleTap();
    }
  }

  void _handleDoubleTap() {
    if (_isAwaitingInput || _bleController.isListening) {
      _speakInstruction('Please wait for voice processing to finish.');
      return;
    }

    if (_currentField == MedicalField.complete) {
      _saveProfile();
      return;
    }

    if (_currentField == MedicalField.sex) {
      if (_currentValueForConfirmation.isNotEmpty) {
        _applyAndMoveToNextField(_currentValueForConfirmation);
        _currentValueForConfirmation = '';
        return;
      }

      setState(() => _isSexDropdownOpen = !_isSexDropdownOpen);
      if (_isSexDropdownOpen) {
        _speakInstruction('Sex dropdown opened. Select manually or long-press for voice input.');
      } else if (_selectedSex.isNotEmpty) {
        // If selection was already made, close and move next
        _applyAndMoveToNextField(_selectedSex);
      } else {
        _speakInstruction('Sex dropdown closed. Please select or use voice input.');
      }
      return;

    } else if (_currentField == MedicalField.bloodType) {
      if (_currentValueForConfirmation.isNotEmpty) {
        _applyAndMoveToNextField(_currentValueForConfirmation);
        _currentValueForConfirmation = '';
        return;
      }

      setState(() => _isBloodTypeDropdownOpen = !_isBloodTypeDropdownOpen);
      if (_isBloodTypeDropdownOpen) {
        _speakInstruction('Blood type dropdown opened. Select manually or long-press for voice input.');
      } else if (_selectedBloodType.isNotEmpty) {
        // If selection was already made, close and move next
        _applyAndMoveToNextField(_selectedBloodType);
      } else {
        _speakInstruction('Blood type dropdown closed. Please select or use voice input.');
      }
      return;
    }

    if (_currentField.index >= MedicalField.allergies.index) {
      _navigateToDetailScreen(_currentField);
    } else {
      _speakInstruction('Please input data or double-tap the next field to proceed.');
    }
  }

  void _handleTripleTap() {
    if (_isAwaitingInput || _bleController.isListening) return;

    if (_currentField == MedicalField.sex) {
      setState(() {
        _selectedSex = '';
        _currentValueForConfirmation = '';
        _isSexDropdownOpen = false;
      });
      _speakInstruction('Sex field cleared. Long-press to re-record or double-tap to open dropdown.');
    } else if (_currentField == MedicalField.bloodType) {
      setState(() {
        _selectedBloodType = '';
        _currentValueForConfirmation = '';
        _isBloodTypeDropdownOpen = false;
      });
      _speakInstruction('Blood type field cleared. Long-press to re-record or double-tap to open dropdown.');
    } else {
      _speakInstruction('Triple-tap function only works on Sex and Blood Type fields to clear the value.');
    }
  }

  void _applyAndMoveToNextField(String value) {
    MedicalField nextField = MedicalField.complete;
    String nextInstruction = 'Profile complete. Double-tap the Save (Done) button.';

    if (_currentField == MedicalField.sex) {
      _selectedSex = value;
      _isSexDropdownOpen = false;
      nextField = MedicalField.bloodType;
      nextInstruction = 'Sex recorded: ${_selectedSex}. Current field is Blood Type. Double-tap to open the dropdown.';
    } else if (_currentField == MedicalField.bloodType) {
      _selectedBloodType = value;
      _isBloodTypeDropdownOpen = false;
      nextField = MedicalField.allergies;
      nextInstruction = 'Blood type recorded: ${_selectedBloodType}. Current field is Allergies. Double-tap to enter detail screen.';
    } else if (_currentField == MedicalField.allergies) {
      nextField = MedicalField.medications;
      nextInstruction = 'Allergies saved. Current field is Medications. Double-tap to enter detail screen.';
    } else if (_currentField == MedicalField.medications) {
      nextField = MedicalField.diseases;
      nextInstruction = 'Medications saved. Current field is Chronic Diseases. Double-tap to enter detail screen.';
    } else if ( _currentField == MedicalField.diseases) {
      nextField = MedicalField.complete;
      nextInstruction = 'All details set. Current field is the Done button. Double-tap to save your profile.';
    }

    setState(() {
      _currentField = nextField;
      _currentValueForConfirmation = '';
    });
    _speakInstruction(nextInstruction);
  }

  void _navigateToDetailScreen(MedicalField field) async {
    _speakInstruction('Navigating to ${_getFieldTitle(field)} screen.');

    dynamic result;

    if (field == MedicalField.allergies) {
      result = await Navigator.of(context).push(
        MaterialPageRoute(
          // 💡 FIX: Use block body for builder to resolve compiler ambiguity
          builder: (context) {
            return AllergiesDetailScreen(
              currentAllergiesString: _selectedAllergies,
            );
          },
        ),
      );

      if (mounted && result is String) setState(() => _selectedAllergies = result);
    } else if (field == MedicalField.medications) {
      result = await Navigator.of(context).push(
        MaterialPageRoute(
          // 💡 FIX: Use block body for builder to resolve compiler ambiguity
          builder: (context) {
            return MedicationsDetailScreen(
              title: 'Medications',
              currentValueString: _selectedMedications,
            );
          },
        ),
      );

      if (mounted && result is String) setState(() => _selectedMedications = result);
    } else if (field == MedicalField.diseases) {
      result = await Navigator.of(context).push(
        MaterialPageRoute(
          // 💡 FIX: Use block body for builder to resolve compiler ambiguity
          builder: (context) {
            return MedicationsDetailScreen(
              title: 'Chronic Diseases',
              currentValueString: _selectedDiseases,
            );
          },
        ),
      );

      if (mounted && result is String) setState(() => _selectedDiseases = result);
    }

    // After returning from the detail screen, apply and move to the next field
    _applyAndMoveToNextField('');
  }


  // 💡 التعديل الأساسي هنا: تم تغيير التوجيه من LocalAuthScreen إلى MainScreen وتم إزالة 'const'
  void _saveProfile() async {
    if (_selectedSex.isEmpty || _selectedBloodType.isEmpty) {
      _speakInstruction('Please set Sex and Blood Type before saving. You will be redirected to the Sex field now.');
      setState(() => _currentField = MedicalField.sex);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _speakInstruction('Saving medical profile. Please wait.');

    final UserProfile? currentProfile = _bleController.userProfile;
    if (currentProfile != null) {
      final newProfile = currentProfile.copyWith(
        sex: _selectedSex,
        bloodType: _selectedBloodType,
        allergies: _selectedAllergies,
        medications: _selectedMedications,
        diseases: _selectedDiseases,
        isProfileComplete: true,
      );

      await _bleController.saveUserProfile(newProfile);
    }

    setState(() {
      _isLoading = false;
    });

    _speakInstruction('Medical profile saved successfully. Navigating to the Main Screen.'); // رسالة موجهة

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        // [NEW] توجيه إلى شاشة MainScreen وإزالة كلمة 'const'
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MainChatScreen()), // تم التغيير هنا (إزالة const)
        );
      }
    });
  }

  // Helper widget for Sex and Blood Type (Dropdown)
  Widget _buildSelectionBox({
    required String title,
    required String value,
    required MedicalField field,
    required bool isDropdownOpen,
    required List<String> options,
    required Function(String) onSelectOption,
  }) {
    final displayValue = value.isEmpty || value == 'Not Set' ? '' : value;
    final bool isSex = field == MedicalField.sex;

    // Determine the height of the dropdown list based on the number of options
    final double dropdownHeight = isSex ? (options.length * 48.0) + 16.0 : (options.length * 48.0) + 16.0;

    // Radius and Border
    const double boxRadius = 24.0; // Adjusted based on Figma
    final Color valueColor = accentColor.withOpacity(0.9); // Brighter accent for value
    final Color borderColor = accentColor.withOpacity(0.25); // 25% opacity border
    const double borderWidth = 1.0; // 1px border width from Figma

    // Reduced vertical padding for smaller height (as requested previously)
    const double verticalPadding = 14;


    return GestureDetector(
      onDoubleTap: () => _handleDoubleTap(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The main header/value display area
            Container(
              decoration: BoxDecoration(
                // استخدام اللون الشفاف للحقل
                color: inputSurfaceColor,
                borderRadius: BorderRadius.circular(boxRadius),
                // استخدام لون التحديد بنسبة 25% شفافية
                border: Border.all(
                    color: borderColor,
                    width: borderWidth),
              ),
              // تقليل الـ padding للحصول على ارتفاع أقل
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: verticalPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                        color: onBackground.withOpacity(0.8),
                        fontSize: 18,
                        fontWeight: FontWeight.w600),
                  ),
                  Row(
                    children: [
                      Text(
                        displayValue,
                        // استخدام لون التحديد للقيمة
                        style: TextStyle(
                            color: value.isEmpty || value == 'Not Set' ? onBackground.withOpacity(0.4) : valueColor,
                            fontSize: 18),
                      ),
                      const SizedBox(width: 8),
                      // استخدام لون التحديد للسهم
                      Icon(
                        Icons.arrow_forward_ios,
                        color: valueColor,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // The Dropdown options list
            if (isDropdownOpen)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: isDropdownOpen ? dropdownHeight : 0,
                margin: const EdgeInsets.only(top: 8.0),
                decoration: BoxDecoration(
                  // استخدام اللون الشفاف للحقل
                  color: inputSurfaceColor,
                  borderRadius: BorderRadius.circular(boxRadius),
                  // استخدام لون التحديد بنسبة 25% شفافية
                  border: Border.all(color: borderColor, width: borderWidth),
                ),
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: options.map((option) {
                      final isSelected = option == value;
                      return InkWell(
                        onTap: () {
                          onSelectOption(option);
                          _applyAndMoveToNextField(option);
                        },
                        child: Container(
                          height: 48,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                          decoration: BoxDecoration(
                            // استخدام لون التحديد بخلفية شفافة للاختيار
                            color: isSelected ? accentColor.withOpacity(0.2) : Colors.transparent,
                            borderRadius: BorderRadius.circular(boxRadius),
                          ),
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: 18,
                              // لون النص المحدد
                              color: isSelected ? accentColor : onBackground.withOpacity(0.9),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper widget for Allergies, Medications, Diseases (Navigation)
  Widget _buildNavigationBox({
    required String title,
    required String value,
    required MedicalField field,
  }) {
    // Display value logic: show count if set, otherwise empty string
    final displayValue = value == 'None'
        ? ''
        : (value.contains(',') ? '${value.split(',').length} items set' : 'Set');

    // Radius and Border
    const double boxRadius = 24.0; // Adjusted based on Figma
    final Color valueColor = accentColor.withOpacity(0.9); // Brighter accent for value
    final Color borderColor = accentColor.withOpacity(0.25); // 25% opacity border
    const double borderWidth = 1.0; // 1px border width from Figma

    // Reduced vertical padding for smaller height (as requested previously)
    const double verticalPadding = 14;

    return InkWell(
      onTap: () => setState(() => _currentField = field),
      onDoubleTap: () => _handleDoubleTap(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15.0),
        // تقليل الـ padding للحصول على ارتفاع أقل
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: verticalPadding),
        decoration: BoxDecoration(
          // استخدام اللون الشفاف للحقل
          color: inputSurfaceColor,
          borderRadius: BorderRadius.circular(boxRadius),
          // استخدام لون التحديد بنسبة 25% شفافية
          border: Border.all(
              color: borderColor,
              width: borderWidth),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                  color: onBackground.withOpacity(0.8),
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
            Row(
              children: [
                Text(
                  displayValue,
                  // استخدام لون التحديد للقيمة
                  style: TextStyle(
                      color: value == 'None' ? onBackground.withOpacity(0.4) : valueColor,
                      fontSize: 18),
                ),
                const SizedBox(width: 8),
                // استخدام لون التحديد للسهم
                Icon(
                  Icons.arrow_forward_ios,
                  color: valueColor,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // الودجت الخاص بزر "Done" (حفظ)
  Widget _buildDoneButton() {
    // Radius
    const double buttonRadius = 25.0;

    return GestureDetector(
      onDoubleTap: _saveProfile,
      child: Container(
        height: 65,
        width: double.infinity,
        decoration: BoxDecoration(
          // استخدام لون التحديد الرئيسي للزر
          color: accentColor,
          borderRadius: BorderRadius.circular(buttonRadius),
          // Removed boxShadow
        ),
        alignment: Alignment.center,
        child: _isLoading
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(color: darkBackground, strokeWidth: 2),
        )
            : const Text(
          'Done',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: darkBackground, // Dark background color for text on orange button
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const List<String> sexOptions = ['Male', 'Female'];
    const List<String> bloodTypeOptions = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

    return Consumer<BleController>(
      builder: (context, bleController, child) {
        _bleController = bleController;

        return GestureDetector(
          onTap: _handleScreenTap,
          onLongPressStart: (_) => _onLongPressStart(bleController),
          onLongPressEnd: _onLongPressEnd,
          child: Scaffold(
            backgroundColor: darkBackground,
            // Custom Header instead of AppBar
            body: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Custom Header Section: Sign Up & Medical Profile
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 50.0, 16.0, 0.0), // Padding adjusted for status bar
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Row: Back Button and Sign Up Title
                          Row(
                            children: [
                              // Back Button (Left)
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios),
                                color: onBackground, // White color
                                onPressed: () {
                                  // 💡 الإصلاح النهائي: التحقق أولاً من إمكانية العودة (pop) لتجنب أخطاء Navigator.
                                  if (Navigator.of(context).canPop()) {
                                    // إذا كانت شاشة التسجيل موجودة في الخلف، نعود إليها مباشرة.
                                    Navigator.of(context).pop();
                                  } else {
                                    // إذا لم يكن هناك شيء للعودة إليه، نقوم باستبدال الشاشة الحالية بشاشة التسجيل.
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(builder: (context) => const SignUpScreen()),
                                    );
                                  }
                                },
                              ),
                              // Sign Up Title (Center)
                              Expanded(
                                child: Center(
                                  child: Text(
                                    'Sign Up', // Text "Sign Up"
                                    style: TextStyle(
                                      color: onBackground, // White color #F8F8F8
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 48), // مسافة لموازاة زر الرجوع
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Medical Profile Title (Center Alignment)
                          Center(
                            child: Text(
                              'Medical Profile', // Text "Medical Profile"
                              style: TextStyle(
                                color: onBackground, // White color #F8F8F8
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                    // -----------------------------------------------------

                    // Main Content (Fields and Button)
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            // 1. Sex
                            _buildSelectionBox(
                              title: 'Sex',
                              value: _selectedSex,
                              field: MedicalField.sex,
                              isDropdownOpen: _isSexDropdownOpen,
                              options: sexOptions,
                              onSelectOption: (sex) => setState(() => _selectedSex = sex),
                            ),

                            // 2. Blood Type
                            _buildSelectionBox(
                              title: 'Blood Type',
                              value: _selectedBloodType,
                              field: MedicalField.bloodType,
                              isDropdownOpen: _isBloodTypeDropdownOpen,
                              options: bloodTypeOptions,
                              onSelectOption: (type) => setState(() => _selectedBloodType = type),
                            ),

                            // 3. Allergies
                            _buildNavigationBox(
                              title: 'Allergies',
                              value: _selectedAllergies,
                              field: MedicalField.allergies,
                            ),

                            // 4. Medications
                            _buildNavigationBox(
                              title: 'Medications',
                              value: _selectedMedications,
                              field: MedicalField.medications,
                            ),

                            // 5. Diseases
                            _buildNavigationBox(
                              title: ' Chronic Diseases',
                              value: _selectedDiseases,
                              field: MedicalField.diseases,
                            ),

                            const SizedBox(height: 50),

                            // Save Button (Done)
                            _buildDoneButton(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Voice/Loading Overlay
                if (_isAwaitingInput || bleController.isListening || _isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.8),
                    constraints: const BoxConstraints.expand(),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: accentColor),
                          const SizedBox(height: 20),
                          Text(
                            _isLoading
                                ? 'Saving profile...'
                                : bleController.isListening
                                ? 'Listening to input...'
                                : 'Processing voice command...',
                            style: const TextStyle(color: onBackground, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}