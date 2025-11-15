
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:ui';

import 'main_chat_screen.dart';
import 'glasses_screen.dart';
import 'cane_screen.dart';
import 'gesture_config_screen.dart';

const Color neonColor = Color(0xFFFFB267);
const Color darkSurface = Color(0xFF2D2929);
const Color cardColor = Color(0xFF282424);
const Color onBackground = Colors.white;

const Color newDarkBackground = Color(0xFF1D1D1D);
const Color gradientTopColor = Color(0xFF2D2929);
const Color gradientMidColor = Color(0xFF221F1F);

class BraceletScreen extends StatefulWidget {
  const BraceletScreen({super.key});

  @override
  State<BraceletScreen> createState() => _BraceletScreenState();
}

class _BraceletScreenState extends State<BraceletScreen> {
  bool _isConnected = true;
  final String _batteryLevel = '36%';
  final String _timeRemaining = '3h 20m';

  bool _showSensorsView = false;

  List<bool> _sensorConnectionStatus = [true, true, true, false];

  bool _isAwaitingInput = false;
  String _lastSpokenPrompt = '';

  late BleController _bleController;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _bleController = Provider.of<BleController>(context, listen: false);
      _bleController.speak('You are now in the Smart Bracelet screen. The battery level is $_batteryLevel with an estimated time remaining of $_timeRemaining. The device is currently ${_isConnected ? 'connected' : 'disconnected'}. Tap anywhere to view sensor details. Long press to give a voice command. Double tap to go back to the home screen.');
    });
  }

  void _onLongPressStart(BleController bleController) {
    if (_isAwaitingInput || bleController.isListening) return;
    setState(() {
      _isAwaitingInput = true;
    });
    bleController.speak('Recording started. Speak now.');
    bleController.startListening(
      onResult: (spokenText) {
        if (mounted) {
          setState(() {
            _isAwaitingInput = false;
            _lastSpokenPrompt = spokenText;
          });
          if (spokenText.isNotEmpty) {
            _handleCommand(bleController, spokenText);
          } else {
            bleController.speak('Could not recognize your speech. Long press and try again.');
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

  void _triggerEmergencyCall(BleController bleController) async {
    const url = 'tel:911';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      bleController.speak('Sorry, emergency call cannot be placed.');
    }
  }

  void _goToSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const GestureConfigScreen()),
    );
  }

  void _handleCommand(BleController bleController, String command) async {
    final normalizedCommand = command.toLowerCase().trim();

    void navigateTo(Widget screen, String name) {
      bleController.speak('Navigating to $name screen.');
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => screen));
    }

    if (normalizedCommand.contains('glasses') || normalizedCommand.contains('نظاره')) {
      bleController.speak('Sorry, Glasses screen not implemented for direct voice navigation from here yet.');
      return;
    } else if (normalizedCommand.contains('cane') || normalizedCommand.contains('عصا')) {
      bleController.speak('Sorry, Cane screen not implemented for direct voice navigation from here yet.');
      return;
    } else if (normalizedCommand.contains('bracelet') || normalizedCommand.contains('سوار')) {
      bleController.speak('You are already on the Bracelet screen.');
      return;
    } else if (normalizedCommand.contains('home') || normalizedCommand.contains('رئيسية') || normalizedCommand.contains('main')) {
      bleController.speak('Returning to Home screen.');
      Navigator.of(context).pop();
      return;
    } else if (normalizedCommand.contains('settings') || normalizedCommand.contains('اعدادات')) {
      bleController.speak('Navigating to Settings screen.');
      _goToSettings();
      return;
    } else if (normalizedCommand.contains('emergency') || normalizedCommand.contains('طوارئ') || normalizedCommand.contains('911')) {
      bleController.speak('Initiating emergency call.');
      _triggerEmergencyCall(bleController);
      return;
    }
    bleController.speak('I did not recognize a navigation command. Processing your query now.');
  }

  void _toggleView() {
    setState(() {
      _showSensorsView = !_showSensorsView;
    });
    if (_showSensorsView) {
      _bleController.speak('Displaying sensor details. Tap to return to battery status.');
    } else {
      _bleController.speak('Displaying battery status. Tap to view sensor details.');
    }
  }

  void _toggleConnection(BleController bleController) {
    setState(() {
      _isConnected = !_isConnected;
    });
    final status = _isConnected ? 'Connected' : 'Disconnected';
    bleController.speak('The connection status for Bracelet has been changed to: $status.');
  }

  void _toggleSensorStatus(int index) {
    setState(() {
      _sensorConnectionStatus[index] = !_sensorConnectionStatus[index];
    });
    final sensorName = ['Left Hand', 'Right Hand', 'Left Leg', 'Right Leg'][index];
    final status = _sensorConnectionStatus[index] ? 'Connected' : 'Disconnected';
    _bleController.speak('$sensorName sensor status changed to: $status.');
  }

  void _handleDoubleTap(BleController bleController) {
    bleController.speak('Returning to the Home Screen.');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Consumer<BleController>(
      builder: (context, bleController, child) {
        final chatOverlay = Container(
          color: Colors.black.withOpacity(0.7),
          constraints: const BoxConstraints.expand(),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: darkSurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: neonColor),
                  const SizedBox(height: 20),
                  Text(
                    bleController.isListening
                        ? 'Listening... (Lift finger to send)'
                        : 'Processing your query...',
                    style: const TextStyle(color: onBackground, fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
        );

        return GestureDetector(
          onTap: _toggleView,
          onLongPressStart: (_) => _onLongPressStart(bleController),
          onLongPressEnd: _onLongPressEnd,
          onDoubleTap: () => _handleDoubleTap(bleController),
          child: Scaffold(
            body: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    _showSensorsView ? 'assets/images/bracelet4.jpg' : 'assets/images/bracelet.jpg',
                    fit: BoxFit.cover,
                  ),
                ),

                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.6),
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 50,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (!_showSensorsView)
                            InkWell(
                              onTap: () => Navigator.of(context).pop(),
                              child: const Icon(Icons.arrow_back_ios, color: onBackground, size: 24),
                            ),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: _showSensorsView ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Bracelet',
                                  textAlign: _showSensorsView ? TextAlign.start : TextAlign.center,
                                  style: TextStyle(
                                    fontSize: _showSensorsView ? 32 : 24,
                                    fontWeight: _showSensorsView ? FontWeight.w500 : FontWeight.w600,
                                    color: const Color(0xFFF8F8F8),
                                  ),
                                ),
                                if (_showSensorsView)
                                  const Text(
                                    '4 devices',
                                    style: TextStyle(
                                      fontSize: 17,
                                      color: onBackground,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          if (!_showSensorsView)
                            const Icon(Icons.notifications_none, color: onBackground, size: 24),
                        ],
                      ),
                    ],
                  ),
                ),

                if (!_showSensorsView)
                  Positioned(
                    bottom: screenHeight * 0.10,
                    left: screenWidth * 0.112,
                    right: screenWidth * 0.112,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20.0),
                      decoration: BoxDecoration(
                        color: cardColor.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _batteryLevel,
                            textAlign: TextAlign.left,
                            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: onBackground),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Estimated time remaining: $_timeRemaining',
                            textAlign: TextAlign.left,
                            style: TextStyle(fontSize: 14, color: onBackground.withOpacity(0.8)),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _isConnected ? 'On' : 'Off',
                                style: const TextStyle(
                                  fontSize: 24,
                                  color: onBackground,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Switch(
                                value: _isConnected,
                                onChanged: (val) => _toggleConnection(bleController),
                                activeTrackColor: neonColor,
                                activeThumbColor: Colors.black,
                                inactiveTrackColor: Colors.black.withOpacity(0.5),
                                inactiveThumbColor: Colors.black,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Positioned.fill(
                    top: 150,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
                      child: GridView.builder(
                        itemCount: 4,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 18,
                          mainAxisSpacing: 18,
                          childAspectRatio: 1.0,
                        ),
                        itemBuilder: (context, index) {
                          final names = ['Left Hand\nSensor', 'Right Hand\nSensor', 'Left Leg\nSensor', 'Right Leg\nSensor'];
                          final status = _sensorConnectionStatus[index] ? 'Connected' : 'Disconnected';

                          return _buildSensorCard(
                            names[index],
                            status,
                            isConnected: _sensorConnectionStatus[index],
                            onTap: () => _toggleSensorStatus(index),
                          );
                        },
                      ),
                    ),
                  ),

                if (_isAwaitingInput || bleController.isListening)
                  chatOverlay,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSensorCard(String title, String status, {bool isConnected = true, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor.withOpacity(0.6),
          borderRadius: BorderRadius.circular(24.0),
        ),
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: Text(
                title,
                style: const TextStyle(
                  color: onBackground,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Text(
                status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isConnected ? neonColor : onBackground.withOpacity(0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}