// user_profile_screen.dart (FINAL - تم تضمين كل التعديلات المطلوبة)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_controller.dart';
// يجب استيراد شاشة الملف الطبي للسماح بالتعديل
import 'registration_screen.dart';
// يُفترض أن MedicalProfileScreen موجودة في هذا الملف

// -----------------------------------------------------------------
// ✅ الألوان المستخدمة
// -----------------------------------------------------------------
const Color neonColor = Color(0xFFFFB267); // Orange Accent
const Color darkSurface = Color(0xFF282424); // لون كارد البيانات
const Color onBackground = Color(0xFFE0E0E0); // لون النصوص الرئيسي
const Color secondaryText = Color(0xFFA0A0A0); // لون نصوص الـ Hint/Label الخافتة
const Color darkText = Color(0xFF1B1B1B); // لون النص على زر الأورنج

// ✅ تعريف ألوان الخلفية للتدرج
const Color gradientTopColor = Color(0xFF2D2929);
const Color gradientBottomColor = Color(0xFF110F0F);
// -----------------------------------------------------------------


class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  // -------------------------------------------------------------
  // ** دالة مساعدة لبناء حقل معلومات (للعرض فقط) **
  // -------------------------------------------------------------
  Widget _buildProfileField(
      {required String label, required String value}) {
    // إذا كانت القيمة مجهولة أو فارغة
    final displayValue = value.isEmpty ? 'Not Set' : value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // النص الخافت (الـ Label)
        Text(
          label,
          style: TextStyle(
            color: secondaryText,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        // قيمة الحقل
        Text(
          displayValue,
          style: TextStyle(
            color: onBackground,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        // خط فاصل سفلي خفيف
        Container(
          height: 1.0,
          margin: const EdgeInsets.only(top: 8.0, bottom: 4.0),
          color: secondaryText.withOpacity(0.3),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // ** دالة مساعدة لبناء عنصر قائمة طبي (Allergies, Medications, Diseases) **
  // -------------------------------------------------------------
  Widget _buildMedicalListItem(
      {required String title, required String value, required BuildContext context}) {
    // محاكاة شكل قائمة Figma (سهم > على اليمين)
    final displayValue = value.isNotEmpty ? 'View Details' : 'Not Set';

    return InkWell(
      onTap: () {
        // يمكنك عرض تفاصيل القائمة الطويلة هنا
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title: ${value.isEmpty ? "No Data" : value}'))
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: secondaryText.withOpacity(0.3), width: 1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: onBackground,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // لعرض قيمة بسيطة تحت العنوان
                  Text(
                    displayValue,
                    style: TextStyle(
                      color: secondaryText.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: secondaryText,
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 📌📌📌 قالب حقل الإدخال المتطابق (TextFormField) 📌📌📌
  // ** يجب نسخ هذه الدالة ولصقها واستخدامها في شاشة التعديل (MedicalProfileScreen) **
  /*
  Widget _buildEditableField({
    required String label,
    required String initialValue,
    required BuildContext context,
    // يمكن إضافة controller, validator, onChanged هنا
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: secondaryText, // لون التسمية (Label)
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: initialValue,
          style: const TextStyle(
            color: onBackground, // لون النص المدخل
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.zero,

            // إزالة أي لون خلفية إضافي وإبقائها شفافة أو بلون الكارد (darkSurface)
            fillColor: darkSurface,
            filled: true,

            // إزالة الـ Border العلوي والجانبي والاحتفاظ بالخط السفلي فقط
            border: InputBorder.none, // إزالة الحدود الافتراضية
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: secondaryText.withOpacity(0.3), width: 1.0), // خط سفلي خافت عند عدم التركيز
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: neonColor, width: 2.0), // خط سفلي برتقالي عند التركيز
            ),
          ),
        ),
      ],
    );
  }
  */
  // 📌📌📌 نهاية القالب 📌📌📌
  // -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Consumer<BleController>(
      builder: (context, bleController, child) {
        final profile = bleController.userProfile;

        // حالة عدم وجود بيانات (شاشة فارغة)
        if (profile == null) {
          return Scaffold(
            backgroundColor: gradientTopColor,
            body: Center(
              child: Text(
                'User profile data not found. Please complete registration.',
                style: TextStyle(color: onBackground),
              ),
            ),
          );
        }

        // -------------------------------------------------------------
        // ** معالجة الاسم لتقسيمه إلى First Name و Last Name **
        // -------------------------------------------------------------
        final nameParts = profile.fullName?.trim().split(' ') ?? [];
        String firstName = '';
        String lastName = '';

        if (nameParts.isNotEmpty) {
          firstName = nameParts.first;
          if (nameParts.length > 1) {
            lastName = nameParts.last;
          }
        }

        // -------------------------------------------------------------
        // ** الشاشة الرئيسية **
        // -------------------------------------------------------------
        return Scaffold(
          backgroundColor: gradientTopColor,
          body: Stack(
            children: [
              // 1. الخلفية المتدرجة
              Container(
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
              ),

              // 2. المحتوى القابل للتمرير
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [

                      // عنوان الشاشة
                      const SizedBox(height: 10),
                      const Text(
                        'Medical Profile',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: onBackground,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),

                      // الصورة الرمزية (Avatar)
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: neonColor.withOpacity(0.5),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: neonColor.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: gradientBottomColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // كارد المعلومات الشخصية والطبية
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: darkSurface, // لون الكارد #282424
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Column(
                          children: [
                            // حقل 1: First Name
                            _buildProfileField(label: 'First Name', value: firstName),
                            const SizedBox(height: 15),

                            // حقل 2: Last Name
                            _buildProfileField(label: 'Last Name', value: lastName),
                            const SizedBox(height: 15),

                            // حقل 3: Email
                            _buildProfileField(label: 'Email', value: profile.email ?? ''),
                            const SizedBox(height: 15),

                            // حقل 4: Sex
                            _buildProfileField(label: 'Sex', value: profile.sex ?? ''),
                            const SizedBox(height: 15),

                            // حقل 5: Blood Type
                            _buildProfileField(label: 'Blood Type', value: profile.bloodType ?? ''),

                            // مسافة قبل قوائم التفاصيل الطبية (20px لفصل الأقسام)
                            const SizedBox(height: 20),

                            // قوائم التفاصيل الطبية (Allergies, Medications, Diseases)
                            _buildMedicalListItem(
                                title: 'Allergies',
                                value: profile.allergies ?? '',
                                context: context),
                            _buildMedicalListItem(
                                title: 'Medications',
                                value: profile.medications ?? '',
                                context: context),
                            _buildMedicalListItem(
                                title: 'Diseases',
                                value: profile.diseases ?? '',
                                context: context),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // 3. زر التعديل
                      ElevatedButton(
                        onPressed: () {
                          // الانتقال إلى شاشة MedicalProfileScreen لتعديل البيانات
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (context) => MedicalProfileScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: neonColor,
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 5,
                        ),
                        child: const Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: darkText,
                          ),
                        ),
                      ),

                      // مسافة سفلية لأجل البار السفلي (إن وجد)
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}