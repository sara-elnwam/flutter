import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../services/ble_controller.dart';
import 'sign_up_screen.dart';
import 'registration_screen.dart';
import 'main_chat_screen.dart';

const Color darkBackground = Color(0xFF141318);

class LocalAuthScreen extends StatefulWidget {
  final bool isPostRegistration;

  const LocalAuthScreen({super.key, this.isPostRegistration = false});

  @override
  State<LocalAuthScreen> createState() => _LocalAuthScreenState();
}

class _LocalAuthScreenState extends State<LocalAuthScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  String _message = 'Please authenticate to continue.';
  late BleController _bleController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () async {
      _bleController = Provider.of<BleController>(context, listen: false);

      setState(() { _isLoading = false; });

      final userProfile = _bleController.userProfile;

      if (userProfile == null) {
        _bleController.speak('Welcome. Please authenticate to start registration.');
        await _authenticateUser(
          onSuccess: () => _navigateToSignUpScreen(context),
          onFail: () => setState(() => _message = 'Authentication failed. Restart application to retry.'),
        );
        return;
      }

      if (userProfile.isBiometricEnabled) {
        final instruction = widget.isPostRegistration
            ? 'Please authenticate to confirm registration.'
            : 'Please authenticate with a fingerprint to continue.';

        _bleController.speak(instruction);
        await _authenticateUser(
          onSuccess: () => _navigateToNextScreen(context),
          onFail: () => setState(() => _message = 'Authentication failed. Please tap to continue or retry.'),
        );
      } else {
        _bleController.speak('Biometric authentication has been skipped. Redirecting.');
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          _navigateToNextScreen(context);
        }
      }
    });
  }

  Future<void> _authenticateUser({
    required VoidCallback onSuccess,
    required VoidCallback onFail,
  }) async {
    bool authenticated = false;
    if (mounted) setState(() => _message = 'Authenticating...');

    try {
      authenticated = await auth.authenticate(
        localizedReason: 'Scan your fingerprint (or face) to access the application.',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on Exception {
      // Handle exception
    }

    if (mounted) {
      if (authenticated) {
        _bleController.speak('Authentication successful.');
        await Future.delayed(const Duration(milliseconds: 1000));
        onSuccess();
      } else {
        _bleController.speak('Authentication failed. Please tap to continue or retry.');
        onFail();
      }
    }
  }

  void _navigateToSignUpScreen(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const SignUpScreen()),
          (Route<dynamic> route) => false,
    );
  }

  void _navigateToNextScreen(BuildContext context) {
    if (_bleController.userProfile == null || _bleController.userProfile!.isProfileComplete == false) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MedicalProfileScreen()),
            (Route<dynamic> route) => false,
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainChatScreen()),
            (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final onBackground = Theme.of(context).colorScheme.onBackground;

    return Scaffold(
      backgroundColor: darkBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              const CircularProgressIndicator(color: Colors.white),
            if (!_isLoading)
              Text(_message, style: TextStyle(color: onBackground, fontSize: 18)),
            if (!_isLoading && _bleController.userProfile != null)
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: ElevatedButton(
                  onPressed: () {
                    if (_bleController.userProfile!.isBiometricEnabled) {
                      _authenticateUser(
                        onSuccess: () => _navigateToNextScreen(context),
                        onFail: () => setState(() => _message = 'Authentication failed. Please tap to continue or retry.'),
                      );
                    } else {
                      _navigateToNextScreen(context);
                    }
                  },
                  child: const Text('Retry / Continue'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}