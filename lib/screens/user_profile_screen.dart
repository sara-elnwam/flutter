import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_controller.dart';
import 'registration_screen.dart';

const Color neonColor = Color(0xFFFFB267);
const Color darkSurface = Color(0xFF282424);
const Color onBackground = Color(0xFFE0E0E0);
const Color secondaryText = Color(0xFFA0A0A0);
const Color darkText = Color(0xFF1B1B1B);

const Color gradientTopColor = Color(0xFF2D2929);
const Color gradientBottomColor = Color(0xFF110F0F);


class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  Widget _buildInfoField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: secondaryText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(icon, color: neonColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: onBackground,
                    fontSize: 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalInfoCard(String title, String value) {
    String displayValue = value == 'None' ? 'Not Set' : value;

    if (value.contains(',')) {
      displayValue = '${value.split(',').length} items set';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: onBackground,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            displayValue,
            style: TextStyle(
              color: value == 'None' || value == 'Not Set' ? secondaryText : neonColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BleController>(
      builder: (context, bleController, child) {
        final userProfile = bleController.userProfile;

        if (userProfile == null) {
          return const Scaffold(
            body: Center(
              child: Text('User profile not found.', style: TextStyle(color: onBackground)),
            ),
          );
        }

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [gradientTopColor, gradientBottomColor],
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  expandedHeight: 0,
                  floating: true,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: onBackground),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  title: const Text(
                    'Profile',
                    style: TextStyle(
                      color: onBackground,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  centerTitle: true,
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        const SizedBox(height: 10),

                        Center(
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: neonColor.withOpacity(0.2),
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: neonColor,
                              shadows: [
                                Shadow(blurRadius: 10.0, color: neonColor.withOpacity(0.5)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // General Info Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: darkSurface,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Personal Information',
                                style: TextStyle(
                                  color: onBackground,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 15),

                              _buildInfoField(
                                label: 'Full Name',
                                value: userProfile.fullName,
                                icon: Icons.badge_outlined,
                              ),
                              _buildInfoField(
                                label: 'Email',
                                value: userProfile.email,
                                icon: Icons.email_outlined,
                              ),
                              _buildInfoField(
                                label: 'Biometrics',
                                value: userProfile.isBiometricEnabled ? 'Enabled' : 'Disabled',
                                icon: Icons.fingerprint_outlined,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 25),

                        // Medical Info Card Title
                        const Padding(
                          padding: EdgeInsets.only(bottom: 10.0),
                          child: Text(
                            'Medical Information',
                            style: TextStyle(
                              color: onBackground,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // Medical Info Fields
                        _buildMedicalInfoCard('Sex', userProfile.sex),
                        _buildMedicalInfoCard('Blood Type', userProfile.bloodType),
                        _buildMedicalInfoCard('Allergies', userProfile.allergies),
                        _buildMedicalInfoCard('Medications', userProfile.medications),
                        _buildMedicalInfoCard('Chronic Diseases', userProfile.diseases),

                        const SizedBox(height: 40),

                        // Edit Button
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (context) => const MedicalProfileScreen()),
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

                        const SizedBox(height: 100),
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