import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/ble_controller.dart';
import '../models/ble_device_model.dart';
import '../constants/app_colors.dart';

class ControlSection extends StatelessWidget {
  final BLEController controller;

  const ControlSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryLight.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Kontrol LED'),
          const SizedBox(height: 16),
          _buildLEDControlButtons(),
          const SizedBox(height: 12),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.robotoMono(
        textStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }

  Widget _buildLEDControlButtons() {
    return StreamBuilder<bool>(
      stream: controller.connectionStateStream.map((state) => state.isConnected),
      initialData: controller.isConnected,
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? false;

        return Row(
          children: [
            Expanded(
              child: _buildLEDButton(
                'LED ON',
                AppColors.success,
                () => controller.setLED(true),
                enabled: isConnected,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildLEDButton(
                'LED OFF',
                AppColors.error,
                () => controller.setLED(false),
                enabled: isConnected,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLEDButton(
    String text,
    Color color,
    VoidCallback onPressed, {
    bool enabled = true,
  }) {
    return CupertinoButton(
      onPressed: enabled ? onPressed : null,
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: enabled ? color : AppColors.disabled,
      borderRadius: BorderRadius.circular(8),
      child: Text(
        text,
        style: GoogleFonts.robotoMono(
          textStyle: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            'Toggle LED',
            AppColors.primaryMedium,
            controller.toggleLED,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            'Refresh Status',
            AppColors.info,
            controller.refreshLEDStatus,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String text,
    Color color,
    VoidCallback onPressed,
  ) {
    return StreamBuilder<bool>(
      stream: controller.connectionStateStream.map((state) => state.isConnected),
      initialData: controller.isConnected,
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? false;

        return CupertinoButton(
          onPressed: isConnected ? onPressed : null,
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: isConnected ? color : AppColors.disabled,
          borderRadius: BorderRadius.circular(8),
          child: Text(
            text,
            style: GoogleFonts.robotoMono(
              textStyle: TextStyle(
                color: AppColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }
}