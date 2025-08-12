import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class DetailAppPage extends StatelessWidget {
  const DetailAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'About App',
          style: GoogleFonts.robotoMono(
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
        ),
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Image.asset(
                  'assets/images/esp-32-logo.png',
                  width: 150,
                  height: 150,
                ),
              ),

              // App Name
              Text(
                'ESP32 BLE Controller',
                style: GoogleFonts.robotoMono(
                  textStyle: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // App Functions
              _buildFunctionSection(
                title: 'Features',
                functions: [
                  'BLE Device Scanning',
                  'Connect to ESP32 Devices',
                  'LED Control',
                  'Real-time Status Monitoring',
                  'Bluetooth Permission Management',
                  'Error Handling & Recovery',
                ],
              ),

              const SizedBox(height: 20),

              _buildFunctionSection(
                title: 'How to Use',
                functions: [
                  '1. Enable Bluetooth',
                  '2. Scan for ESP32 devices',
                  '3. Select your device',
                  '4. Control LED remotely',
                  '5. Monitor connection status',
                ],
              ),
              const SizedBox(height: 30),

              Text(
                'Rian Saputra @2025',
                style: GoogleFonts.robotoMono(
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFunctionSection({
    required String title,
    required List<String> functions,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.robotoMono(
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
        ),
        const SizedBox(height: 10),
        ...functions.map((function) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.circle_fill,
                    size: 8,
                    color: AppColors.primaryDark,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      function,
                      style: GoogleFonts.robotoMono(
                        textStyle: const TextStyle(
                          fontSize: 14,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
