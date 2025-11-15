import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../services/ble_controller.dart';
import '../enums/action_type.dart'; // يتطلب استيراد Enums

class GestureConfigScreen extends StatefulWidget {
  const GestureConfigScreen({super.key});

  @override
  State<GestureConfigScreen> createState() => _GestureConfigScreenState();
}

class _GestureConfigScreenState extends State<GestureConfigScreen> {
  Map<Gesture, ActionType> _currentActionConfig = {};

  @override
  void initState() {
    super.initState();

    Future.microtask(_initializeSettings);
  }


  void _initializeSettings() {
    final bleController = Provider.of<BleController>(context, listen: false);
    // bleController.gestureConfig هي Map<String, ActionType>
    final currentConfig = bleController.gestureConfig;

    if (currentConfig.isNotEmpty) {
      setState(() {
        _currentActionConfig = currentConfig.map((key, value) {
          final gestureEnum = Gesture.values.firstWhere(
                (g) => g.codeName == key,
            orElse: () => Gesture.shake_twice,
          );
          return MapEntry(gestureEnum, value);
        });
      });
      bleController.speak('شاشة إعدادات الإيماءات جاهزة.');
    } else {
      setState(() {
        _currentActionConfig = {
          Gesture.shake_twice: ActionType.sos_emergency,
          Gesture.tap_three_times: ActionType.call_contact,
          Gesture.long_press: ActionType.disable_feature,
        };
      });
    }
  }

  void _saveSettings(BleController bleController) {
    final configToSend = _currentActionConfig.map(
          (key, value) => MapEntry(key.codeName, value),
    );

    bleController.sendGestureConfig(configToSend);
    Navigator.of(context).pop();
  }

  void _updateAction(Gesture gesture, ActionType? newAction) {
    if (newAction != null) {
      setState(() {
        _currentActionConfig[gesture] = newAction;
      });
    }
  }
  Widget _buildGestureDropdown(Gesture gesture) {
    final theme = Theme.of(context);
    final currentAction = _currentActionConfig[gesture] ?? ActionType.disable_feature;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: DropdownButtonFormField<ActionType>(
        decoration: InputDecoration(
          labelText: 'الإيماءة: ${gesture.displayName}',
          labelStyle: TextStyle(color: theme.colorScheme.onBackground),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: theme.colorScheme.secondary, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: theme.colorScheme.onBackground.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(10),
          ),
          fillColor: theme.colorScheme.surface,
          filled: true,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        value: currentAction,
        alignment: Alignment.centerRight,
        style: TextStyle(color: theme.colorScheme.onBackground, fontSize: 16),
        icon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.secondary),
        dropdownColor: theme.scaffoldBackgroundColor,

        onChanged: (ActionType? newValue) {
          _updateAction(gesture, newValue);
        },
        items: ActionType.values.map((ActionType action) {
          return DropdownMenuItem<ActionType>(
            value: action,
            child: Text(action.displayName, style: TextStyle(color: theme.colorScheme.onBackground)),
          );
        }).toList(),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<BleController>(
      builder: (context, bleController, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('إعدادات الإيماءات'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'قم بتعيين الإجراء المراد تنفيذه لكل إيماءة:',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onBackground),
                ),
                const Divider(height: 30, color: Colors.cyan),

                if (_currentActionConfig.isNotEmpty)
                  ...Gesture.values.map(_buildGestureDropdown).toList()
                else
                  Center(child: CircularProgressIndicator(color: theme.colorScheme.secondary)),

                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _currentActionConfig.isNotEmpty
                        ? () => _saveSettings(bleController)
                        : null,
                    icon: const Icon(Icons.send_rounded, size: 24),
                    label: const Text('حفظ وإرسال الإعدادات'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      elevation: 5,
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