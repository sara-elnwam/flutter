import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_controller.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'local_auth_screen.dart';

const Color darkBackground = Color(0xFF1F1A1B);
const Color darkSurface = Color(0xFF272523);
const Color onSurfaceText = Color(0xFF727272);
const Color dividerColor = Color(0xFF424242);
const Color logoutColor = Color(0xFFFF5B5B);
const Color onBackground = Colors.white;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late BleController _bleController;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _bleController = Provider.of<BleController>(context, listen: false);
      _bleController.speak('Settings screen. Options include Language, Updates, Help, About, and Logout.');
    });
  }

  void _speakOption(String option) {
    _bleController.speak('Tapped on $option.');
  }

  void _logout() async {
    _bleController.speak('Logging out. Returning to authentication screen.');
    await _bleController.clearUserProfile();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LocalAuthScreen()),
            (Route<dynamic> route) => false,
      );
    }
  }

  Widget _buildSettingItem(
      BuildContext context,
      String title,
      VoidCallback onTap, {
        Color textColor = onBackground,
        bool showDivider = true,
      }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: textColor == onBackground ? onSurfaceText : textColor,
                  size: 18,
                ),
              ],
            ),
          ),
          if (showDivider)
            Divider(
              color: dividerColor,
              height: 1,
              thickness: 1,
              indent: 20,
              endIndent: 20,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    color: onBackground,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Settings',
                        style: TextStyle(
                          color: onBackground,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 30),

              Container(
                decoration: BoxDecoration(
                  color: darkSurface,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    _buildSettingItem(context, 'Language', () => _speakOption('Language')),
                    _buildSettingItem(context, 'Updates', () => _speakOption('Updates')),
                    _buildSettingItem(context, 'Help and Feedback', () => _speakOption('Help and Feedback')),
                    _buildSettingItem(context, 'About Lumos', () => _speakOption('About Lumos')),

                    _buildSettingItem(
                        context,
                        'Logout',
                        _logout,
                        textColor: logoutColor,
                        showDivider: false
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}