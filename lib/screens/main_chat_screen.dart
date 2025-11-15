import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_controller.dart';
import 'dart:async';
import 'settings_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'ble_scan_screen.dart';
import 'glasses_screen.dart';
import 'bracelet_screen.dart';
import 'cane_screen.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'user_profile_screen.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'earpods_screen.dart';


const Color neonColor = Color(0xFFFFB267);
const Color darkSurface = Color(0xFF1C1C1C);
const Color darkBackground = Color(0xFF000000);
const Color onBackground = Colors.white;

class MainChatScreen extends StatefulWidget {
  const MainChatScreen({super.key});

  @override
  State<MainChatScreen> createState() => _MainChatScreenState();
}

class _MainChatScreenState extends State<MainChatScreen> {
  late BleController _bleController;

  String _geminiResponse = '';
  String _lastSpokenPrompt = '';
  bool _isAwaitingInput = false;
  bool isListening = false;

  final List<Map<String, dynamic>> _devices = [
    {
      'name': 'Glasses',
      'subtitle': 'Smart Glasses',
      'icon': MdiIcons.glasses,
      'screen':  GlassesScreen(),
    },
    {
      'name': 'Cane',
      'subtitle': 'Smart Cane',
      'icon': MdiIcons.slashForward,
      'screen': const CaneScreen(),
    },
    {
      'name': 'Bracelet',
      'subtitle': 'Assistive Band',
      'icon': MdiIcons.watch,
      'screen':  BraceletScreen(),
    },
    {
      'name': 'Earbuds',
      'subtitle': 'Lumos Audio',
      'icon': FluentIcons.surface_earbuds_20_regular,
      'screen': const EarpodsScreen(),
    },
  ];

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () {
      _bleController = Provider.of<BleController>(context, listen: false);
      _bleController.speak('Welcome to the Home Screen. Long-press to speak a command.');
    });
  }

  void _onLongPressStart(BleController bleController) {
    if (_isAwaitingInput || bleController.isListening) return;

    setState(() { _isAwaitingInput = true; });
    bleController.speak('Recording started. Speak now.');

    bleController.startListening(
      onResult: (spokenText) async {
        if (mounted) {
          setState(() { _lastSpokenPrompt = spokenText; });
          if (spokenText.isNotEmpty) {
            _processVoiceCommand(spokenText, bleController);
          } else {
            bleController.speak('Could not recognize your speech. Long press and try again.');
            if(mounted) setState(() { _isAwaitingInput = false; });
          }
        }
      },
    );
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (_bleController.isListening) {
      _bleController.stopListening(shouldSpeakStop: false);
      _bleController.speak('Recording stopped. Processing command.');
    }
  }

  Future<void> _processVoiceCommand(String query, BleController bleController) async {
    await Future.delayed(const Duration(seconds: 1));
    if(mounted) setState(() { _isAwaitingInput = false; });
  }

  void _navigateToDevice(Map<String, dynamic> device, BleController bleController) {
    if (device['screen'] != null) {
      bleController.speak('Navigating to ${device['name']} screen.');
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => device['screen']),
      );
    } else {
      bleController.speak('${device['name']} screen is not available yet.');
    }
  }

  void _goToSettings() {
    _bleController.speak('Navigating to Settings screen.');
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  void _navigateToAddDevice() {
    _bleController.speak('Navigating to Add Device screen.');
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const BleScanScreen()),
    );
  }

  Widget _buildDeviceCard(BuildContext context, BleController bleController, Map<String, dynamic> device) {
    final name = device['name'] as String;
    final subtitle = device['subtitle'] as String;
    final iconData = device['icon'] as IconData;

    Widget iconWidget = Icon(
      iconData,
      size: 35,
      color: neonColor,
      shadows: const [
        Shadow(blurRadius: 15.0, color: neonColor),
      ],
    );

    if (name == 'Bracelet') {
      iconWidget = Transform.rotate(
        angle: 90 * pi / 180,
        child: iconWidget,
      );
    }

    if (name == 'Earbuds') {
      iconWidget = Transform.rotate(
        angle: 15 * pi / 180,
        child: iconWidget,
      );
    }

    if (name == 'Cane' && iconData == MdiIcons.slashForward) {
      iconWidget = Icon(
        iconData,
        size: 60,
        color: neonColor,
        shadows: const [
          Shadow(blurRadius: 15.0, color: neonColor),
        ],
      );
    }


    return GestureDetector(
      onTap: () => _navigateToDevice(device, bleController),
      child: Card(
        color: darkSurface.withOpacity(0.6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  iconWidget,
                  const SizedBox(height: 5),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: onBackground,
                    ),
                  ),
                ],
              ),

              Center(
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: onBackground.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({required IconData icon, required bool isActive, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Icon(
            icon == Icons.person_outline ? FluentIcons.person_16_filled : icon,
            size: 30,
            color: isActive ? neonColor : onBackground.withOpacity(0.7)
        ),
      ),
    );
  }

  Widget _buildIntegratedBottomBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
          child: ElevatedButton(
            onPressed: _navigateToAddDevice,
            style: ElevatedButton.styleFrom(
              backgroundColor: neonColor,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 10,
            ),
            child: const Text(
              'Add device',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: darkBackground,
              ),
            ),
          ),
        ),

        Container(
          height: 60.0,
          decoration: BoxDecoration(
            color: darkBackground.withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _buildBottomNavItem(
                icon: Icons.home_filled,
                isActive: true,
                onTap: () => _bleController.speak('You are already on the Home screen.'),
              ),
              _buildBottomNavItem(
                icon: Icons.grid_view,
                isActive: false,
                onTap: () => _bleController.speak('Devices view.'),
              ),
              _buildBottomNavItem(
                icon: Icons.person_outline,
                isActive: false,
                onTap: () => _bleController.speak('User profile screen.'),
              ),
              _buildBottomNavItem(
                icon: Icons.settings_outlined,
                isActive: false,
                onTap: _goToSettings,
              ),
            ],
          ),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<BleController>(
      builder: (context, bleController, child) {
        isListening = bleController.isListening;

        return GestureDetector(
          onLongPressStart: (_) => _onLongPressStart(bleController),
          onLongPressEnd: _onLongPressEnd,
          child: Container(
            decoration: const BoxDecoration(
              color: darkBackground,
              image: DecorationImage(
                image: AssetImage('assets/images/background.jpg'),
                fit: BoxFit.cover,
                opacity: 1.0,
                alignment: Alignment(0.1, -0.2),
              ),
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,

              bottomNavigationBar: _buildIntegratedBottomBar(),

              body: Stack(
                children: [
                  CustomScrollView(
                    slivers: [
                      SliverList(
                        delegate: SliverChildListDelegate(
                          [
                            const SizedBox(height: 80),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20.0),
                              child: Text(
                                'Home',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: onBackground,
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),

                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Text(
                                '${_devices.length} devices',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: onBackground.withOpacity(0.6),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                            childAspectRatio: 0.9,
                          ),
                          delegate: SliverChildListDelegate(
                            _devices.map((device) {
                              return _buildDeviceCard(context, bleController, device);
                            }).toList(),
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(
                        child: SizedBox(height: 110),
                      ),
                    ],
                  ),

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
                                  ? 'Listening to you... Lift your finger to stop recording'
                                  : 'Processing your command...',
                              style: const TextStyle(color: Colors.white, fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}