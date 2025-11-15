// allergies_detail_screen.dart (الكود النهائي - مطابق للتصميم الأخير)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_controller.dart';
import 'dart:async';

// Custom Colors (Matching the provided dark theme images)
const Color neonColor = Color(0xFFF39560); // Orange Accent (اللون البرتقالي المطفي)
const Color darkSurface = Color(0xFF333333); // Dark Grey Surface (لصناديق الأقسام)
const Color darkBackground = Color(0xFF1B1B1B); // Very Dark Background
const Color onBackground = Colors.white; // White text (النص الأبيض الواضح)
const Color lightGreyText = Color(0xFFCCCCCC); // Light grey text color (الرمادي المطفي)

// Structured list of allergies (تم التعديل هنا ليتطابق مع الصورة تمامًا)
const Map<String, List<String>> structuredAllergies = {
  // Food Allergens - تم ترتيبها لتظهر في 3 أعمدة ثم تنتقل لسطر جديد
  'Food Allergens': [
    'Peanut', 'Milk / Dairy', 'Egg',
    'Soybean', 'Wheat / Gluten', 'Other Food', // 'Other' في الصف الأول
    'Shellfish', 'Fish', // هذان في الصف الثالث
  ],
  // Animal / Pet Allergens - تم ترتيبها لتظهر في 2 عمود ثم تنتقل لسطر جديد
  'Animal / Pet Allergens': [
    'Cat Dander', 'Dog Dander',
    'Rodent', 'Other Pet',
  ],
  // Medication / Venom Allergens - تم ترتيبها لتظهر في 2 عمود ثم تنتقل لسطر جديد
  'Medication / Venom Allergens': [
    'Antibiotics', 'Anesthetics',
    'Insect Sting Venom', 'NSAIDs',
    'Other Medication',
  ],
  // Environmental Allergens - تم ترتيبها لتظهر في 3 أعمدة ثم تنتقل لسطر جديد
  'Environmental Allergens': [
    'Pollen', 'Dust Mites', 'Mold',
    'Cockroach', 'Smoke / Fumes', 'Other Env', // 'Other' في الصف الثاني
  ],
};

// Unified list for voice command processing
const List<String> allAllergyNames = [
  'Peanut', 'Milk / Dairy', 'Egg', 'Soybean', 'Wheat / Gluten', 'Other Food',
  'Shellfish', 'Fish', 'Cat Dander', 'Dog Dander', 'Rodent', 'Other Pet',
  'Antibiotics', 'Anesthetics', 'Insect Sting Venom', 'NSAIDs', 'Other Medication',
  'Pollen', 'Dust Mites', 'Mold', 'Cockroach', 'Smoke / Fumes', 'Other Env',
];


class AllergiesDetailScreen extends StatefulWidget {
  final String currentAllergiesString;

  const AllergiesDetailScreen({
    super.key,
    required this.currentAllergiesString,
  });

  @override
  State<AllergiesDetailScreen> createState() => _AllergiesDetailScreenState();
}

class _AllergiesDetailScreenState extends State<AllergiesDetailScreen> {
  // Set of selected allergies
  final Set<String> _selectedAllergies = {};

  bool _isAwaitingInput = false;

  late BleController _bleController;

  int _tapCount = 0;
  Timer? _tapResetTimer;
  final Duration _tapTimeout = const Duration(milliseconds: 600);

  // Current field/item being focused on for voice navigation (for example 0 is Food Allergens)
  int _currentField = 0; // -1 means done button, 0-3 are sections

  @override
  void initState() {
    super.initState();
    // Initialize with current value
    if (widget.currentAllergiesString != 'None' && widget.currentAllergiesString.isNotEmpty) {
      _selectedAllergies.addAll(widget.currentAllergiesString.split(', '));
    }

    // Initialize _bleController
    _bleController = Provider.of<BleController>(context, listen: false);

    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      // TTS Instruction (English only)
      _speak('Screen for Allergies. Current selection: ${_selectedAllergies.isEmpty ? 'None' : _selectedAllergies.join(', ')}. Double-tap to confirm and save. Triple-tap to move to the next section.');
    });
  }

  // Helper functions for TTS
  void _speak(String text) {
    if (!mounted) return;
    _bleController.speak(text);
  }

  // Toggles the selection of an allergy item
  void _toggleSelection(String allergy) {
    setState(() {
      if (_selectedAllergies.contains(allergy)) {
        _selectedAllergies.remove(allergy);
        _speak('$allergy removed.');
      } else {
        _selectedAllergies.add(allergy);
        _speak('$allergy selected.');
      }
    });
  }

  // Voice recognition handler
  void _onLongPressStart() {
    if (_isAwaitingInput || _bleController.isListening) return;

    if (_currentField == -1) {
      _speak('Long press is disabled on Done button. Double-tap to save.');
      return;
    }

    setState(() {
      _isAwaitingInput = true;
    });

    final currentSectionKeys = structuredAllergies.keys.toList();
    final currentSection = currentSectionKeys[_currentField];

    _speak('Recording started for section $currentSection. Say an item name from this section to select or deselect it.');

    _bleController.startListening(
      onResult: (spokenText) {
        if (mounted) {
          setState(() {
            _isAwaitingInput = false;
          });

          final spokenWord = spokenText.trim();

          // Get the list of possible items for the current section
          final currentItems = structuredAllergies[currentSection]!;

          // Find the best match
          final matchedItem = _findBestMatch(spokenWord, currentItems);

          if (matchedItem != null) {
            _toggleSelection(matchedItem);
          } else {
            // TTS Instruction (English only)
            _speak('Could not find a match for $spokenText in the current section. Please try again.');
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

  // Simple matching function (can be improved with fuzzy search)
  String? _findBestMatch(String spokenText, List<String> possibleMatches) {
    final lowerSpoken = spokenText.toLowerCase();
    for (var item in possibleMatches) {
      // Check for exact word matches or close containment (case-insensitive)
      if (item.toLowerCase().contains(lowerSpoken) || lowerSpoken.contains(item.toLowerCase())) {
        return item;
      }
    }
    return null;
  }

  // Gesture Handlers
  void _handleScreenTap() {
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
    } else {
      _speakCurrentFocus();
    }
  }

  void _speakCurrentFocus() {
    if (_currentField == -1) {
      _speak('Focus on Done button. Double-tap to save and continue. Triple-tap to go back to the top.');
    } else {
      final currentSectionKeys = structuredAllergies.keys.toList();
      final currentSection = currentSectionKeys[_currentField];
      final selectedInCurrent = structuredAllergies[currentSection]!.where((a) => _selectedAllergies.contains(a)).toList();

      _speak('Focus on section $currentSection. Selected: ${selectedInCurrent.isEmpty ? 'None' : selectedInCurrent.join(', ')}. Long press to dictate an item name to select or deselect it. Triple-tap to move to the next section.');
    }
  }

  void _handleDoubleTap() {
    if (_isAwaitingInput || _bleController.isListening) {
      _speak('Please wait for voice processing to finish.');
      return;
    }

    // If on Done button, save
    if (_currentField == -1) {
      _saveAndReturn();
    } else {
      // If on a section, toggle between the items within the section (or simply speak the current status)
      // Since the interaction is primarily voice-based via long press, double-tap here mainly serves as a feedback mechanism or simple navigation
      _speakCurrentFocus();
    }
  }

  void _handleTripleTap() {
    if (_isAwaitingInput || _bleController.isListening) return;

    setState(() {
      if (_currentField == -1) {
        // From Done, go back to the first section (Food Allergens)
        _currentField = 0;
      } else {
        // Move to the next section or to the Done button
        _currentField = (_currentField + 1) % (structuredAllergies.length + 1);
        if (_currentField == structuredAllergies.length) {
          _currentField = -1; // Move to Done button
        }
      }
    });

    _speakCurrentFocus();
  }

  void _saveAndReturn() {
    final resultString = _selectedAllergies.isEmpty ? 'None' : _selectedAllergies.join(', ');
    // TTS Instruction (English only)
    _speak('Allergies saved. Returning to profile.');
    Navigator.of(context).pop(resultString);
  }


  @override
  Widget build(BuildContext context) {
    final isListening = _bleController.isListening;
    final currentSectionKeys = structuredAllergies.keys.toList();

    return GestureDetector(
      onTap: _handleScreenTap,
      onLongPressStart: (_) => _onLongPressStart(),
      onLongPressEnd: _onLongPressEnd,
      child: Scaffold(
        backgroundColor: darkBackground,
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(top: 60.0, left: 24.0, right: 24.0, bottom: 100.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Medical Profile Title (أبيض - في المنتصف)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5.0),
                    child: Text(
                      'Medical Profile',
                      textAlign: TextAlign.center, // تم التوسيط
                      style: TextStyle(
                          fontSize: 30, // حجم أكبر
                          fontWeight: FontWeight.bold, // أكثر سمكًا
                          color: onBackground // اللون الأبيض النقي
                      ),
                    ),
                  ),
                  // Allergies Subtitle (رمادي مطفي - في المنتصف)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 30.0),
                    child: Text(
                      'Allergies',
                      textAlign: TextAlign.center, // تم التوسيط
                      style: TextStyle(
                          fontSize: 20, // حجم أصغر
                          fontWeight: FontWeight.w300, // خط أرق
                          color: lightGreyText), // اللون الرمادي المطفي
                    ),
                  ),

                  ...List.generate(structuredAllergies.length, (sectionIndex) {
                    final sectionTitle = currentSectionKeys[sectionIndex];
                    final sectionItems = structuredAllergies[sectionTitle]!;
                    final isFocused = _currentField == sectionIndex;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 15.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: darkSurface,
                        borderRadius: BorderRadius.circular(20.0),
                        // الحدود البرتقالية مطفأة وثابتة السمك
                        border: Border.all(
                            color: neonColor.withOpacity(0.6), // مطفأة دائمًا
                            width: 1), // سُمك ثابت
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Text(
                              sectionTitle,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                // أسماء الأقسام باللون الرمادي المطفي
                                color: lightGreyText,
                              ),
                            ),
                          ),
                          Wrap(
                            spacing: 20.0, // التباعد الأفقي
                            runSpacing: 15.0, // التباعد العمودي
                            children: sectionItems.map((allergy) {
                              final isSelected = _selectedAllergies.contains(allergy);
                              return GestureDetector(
                                onTap: () => _toggleSelection(allergy),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: isSelected ? neonColor : Colors.white,
                                        borderRadius: BorderRadius.circular(8.0),
                                        border: Border.all(
                                          color: neonColor,
                                          width: 3,
                                        ),
                                      ),
                                      child: isSelected
                                          ? Icon(Icons.check, size: 16, color: darkBackground)
                                          : null,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      allergy.replaceAll(' / ', '/'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        // نص الحساسيات مطفأ
                                        color: lightGreyText,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Floating Done Button at the bottom
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20, left: 24, right: 24),
                child: GestureDetector(
                  onDoubleTap: !isListening && !_isAwaitingInput ? _saveAndReturn : null,
                  child: Container(
                    height: 65,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: neonColor, // لون زر Done بالبرتقالي المطفي
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: darkBackground,
                      ),
                    ),
                  ),
                ),
              ),
            ),


            // Voice/Listening Overlay
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
                            ? 'Listening to command...'
                            : 'Processing selection...',
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
  }
}