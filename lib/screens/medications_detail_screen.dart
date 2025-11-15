// lib/screens/medications_detail_screen.dart (الكود الصحيح)

import 'package:flutter/material.dart';

// يمكننا إعادة استخدام الألوان من شاشات أخرى لتجنب خطأ التجميع
const Color accentColor = Color(0xFFFFB267); // Bright Orange/Accent
const Color darkBackground = Color(0xFF1B1B1B); // Dark Background
const Color inputSurfaceColor = Color(0x992B2B2B); // Field background
const Color onBackground = Color(0xFFF8F8F8); // White text

class MedicationsDetailScreen extends StatefulWidget {
  final String title;
  final String currentValueString;

  const MedicationsDetailScreen({
    super.key,
    required this.title,
    required this.currentValueString,
  });

  @override
  State<MedicationsDetailScreen> createState() => _MedicationsDetailScreenState();
}

class _MedicationsDetailScreenState extends State<MedicationsDetailScreen> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // تهيئة المتحكم بالقيمة الحالية المرسلة من الشاشة السابقة
    _controller = TextEditingController(text: widget.currentValueString == 'None' ? '' : widget.currentValueString);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // دالة لحفظ البيانات والعودة إلى الشاشة السابقة
  void _saveAndReturn() {
    String newValue = _controller.text.trim();
    // إذا كانت القيمة فارغة بعد الإزالة/التعديل، نعيدها 'None'
    if (newValue.isEmpty) {
      newValue = 'None';
    }
    // إرجاع القيمة الجديدة للشاشة السابقة
    Navigator.of(context).pop(newValue);
  }

  // دالة للعودة دون حفظ (إرجاع القيمة الأصلية)
  void _cancelAndReturn() {
    Navigator.of(context).pop(widget.currentValueString);
  }


  @override
  Widget build(BuildContext context) {
    // Radius
    const double boxRadius = 24.0;
    const double buttonRadius = 25.0;

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        // عرض العنوان المرسل (سواء "Medications" أو "Chronic Diseases")
        title: Text(
          widget.title,
          style: const TextStyle(color: onBackground, fontWeight: FontWeight.bold),
        ),
        backgroundColor: darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: onBackground),
          onPressed: _cancelAndReturn,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // 1. حقل النص للإدخال/التعديل
            Container(
              decoration: BoxDecoration(
                color: inputSurfaceColor,
                borderRadius: BorderRadius.circular(boxRadius),
                border: Border.all(color: accentColor.withOpacity(0.25), width: 1.0),
              ),
              child: TextFormField(
                controller: _controller,
                maxLines: 5,
                style: const TextStyle(color: onBackground, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Enter your ${widget.title.toLowerCase()} here, separated by commas.',
                  hintStyle: TextStyle(color: onBackground.withOpacity(0.4)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16.0),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 2. زر الحفظ (Save)
            GestureDetector(
              onTap: _saveAndReturn,
              // يمكن إضافة منطق onDoubleTap هنا للمستخدم الكفيف
              child: Container(
                height: 65,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(buttonRadius),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Save',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: darkBackground,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 3. زر الحذف (Clear) - اختياري
            GestureDetector(
              onTap: () {
                _controller.clear();
                // يمكن إضافة نطق صوتي هنا
              },
              child: Container(
                height: 65,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(buttonRadius),
                  border: Border.all(color: accentColor, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Clear All',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}