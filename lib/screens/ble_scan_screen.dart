import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/ble_controller.dart';
import 'gesture_config_screen.dart';
class BleScanScreen extends StatelessWidget {
  const BleScanScreen({super.key});
  final List<Map<String, String>> mockCommands = const [
    {"command": "OBSTACLE_FRONT", "label": "عائق أمامي ⚠️"},
    {"command": "GESTURE_SOS", "label": "إيماءة استغاثة SOS 🚨"},
    {"command": "OBSTACLE_LEFT", "label": "عائق يساري ⬅️"},
    {"command": "GESTURE_CALL", "label": "إيماءة اتصال 📞"},
    {"command": "BATTERY_LOW", "label": "بطارية منخفضة 🔋"},
    {"command": "SETTINGS_ACK", "label": "تأكيد إعدادات ✅"},
  ];

  Widget _buildScanResultTile(BleController bleController, ScanResult result) {
    final bool isConnectedToThisDevice = bleController.connectedDevice?.remoteId == result.device.remoteId;

    final isScanning = bleController.isScanning;
    final isConnecting = bleController.isConnecting && bleController.connectedDevice?.remoteId == result.device.remoteId;
    Widget trailingWidget;
    Function()? onPressedAction;
    Color buttonColor;
    String buttonText;
    if (isConnectedToThisDevice) {
      trailingWidget = const Icon(Icons.check_circle, color: Colors.green);
      onPressedAction = bleController.disconnect;
      buttonColor = Colors.red.shade600;
      buttonText = 'قطع الاتصال';
    } else if (isConnecting) {
      trailingWidget = const CircularProgressIndicator();
      onPressedAction = null;
      buttonColor = Colors.orange.shade600;
      buttonText = 'جارٍ الاتصال...';
    } else {
      trailingWidget = const Icon(Icons.link, color: Colors.blue);
      onPressedAction = () => bleController.connect(result.device);
      buttonColor = Colors.blue.shade600;
      buttonText = 'اتصال';
    }

    return ListTile(
      leading: const Icon(Icons.bluetooth, color: Colors.blue),
      title: Text(result.device.platformName.isEmpty
          ? 'جهاز غير معروف'
          : result.device.platformName),
      subtitle: Text(
          'ID: ${result.device.remoteId}\nRSSI: ${result.rssi} dBm'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isConnecting) trailingWidget else const SizedBox.shrink(),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onPressedAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BleController>(
      builder: (context, bleController, child) {
        final isConnected = bleController.connectedDevice != null;
        final isScanning = bleController.isScanning;

        return Scaffold(
          appBar: AppBar(
            title: const Text('شاشة مسح البلوتوث'),
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            elevation: 4,
            actions: [
              if (isConnected)
                IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: 'إعدادات الإيماءات',
                  onPressed: () {
                    bleController.speak("الانتقال إلى شاشة تكوين الإيماءات.");
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => const GestureConfigScreen()),
                    );
                  },
                ),
              IconButton(
                icon: Icon(isScanning ? Icons.stop : Icons.search),
                tooltip: isScanning ? 'إيقاف المسح' : 'بدء المسح',
                onPressed: isScanning
                    ? bleController.stopScan
                    : bleController.startScan,
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: bleController.scanResults.isEmpty
                    ? Center(
                  child: Text(
                    isScanning
                        ? 'جارٍ البحث عن أجهزة...'
                        : 'لا توجد أجهزة بلوتوث متاحة حاليًا.\nاضغط على أيقونة البحث للمسح.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                )
                    : ListView.builder(
                  itemCount: bleController.scanResults.length,
                  itemBuilder: (context, index) {
                    final result = bleController.scanResults[index];
                    return _buildScanResultTile(bleController, result);
                  },
                ),
              ),
              const Divider(height: 1, thickness: 1),

              if (isConnected)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'أوامر محاكاة الاستقبال (للاختبار):',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: mockCommands.map((commandData) {
                          return ElevatedButton(
                            onPressed: () => bleController.sendMockData(commandData['command']!),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade200,
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: Text(commandData['label']!),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              const Divider(height: 1, thickness: 1),
              Container(
                padding: const EdgeInsets.all(16.0),
                width: double.infinity,
                color: isConnected ? Colors.green.shade100 : Colors.red.shade100,
                child: Semantics(
                  label:
                  'حالة الاتصال والبيانات المستلمة: ${isConnected ? "متصل بالجهاز" : "منفصل"}. ${bleController.receivedDataMessage}',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'حالة النظام: ${isConnected ? "متصل (جهاز جاهز للعمل)" : "منفصل (اضغط مسح أو اتصال)"}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isConnected
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        bleController.receivedDataMessage,
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                      ),
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