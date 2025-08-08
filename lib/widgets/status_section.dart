import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/ble_controller.dart';
import '../models/ble_device_model.dart';
import '../constants/app_colors.dart';

class StatusSection extends StatelessWidget {
  final BLEController controller;

  const StatusSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
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
          _buildSectionTitle('Device Status'),
          const SizedBox(height: 12),
          _buildConnectionStatus(),
          const SizedBox(height: 16),
          _buildLEDStatus(),
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

  Widget _buildConnectionStatus() {
    return StreamBuilder<BLEConnectionState>(
      stream: controller.connectionStateStream,
      initialData: controller.connectionState,
      builder: (context, snapshot) {
        final state = snapshot.data!;
        return _buildStatusRow(
          'Connection',
          state.displayText.contains('Terhubung ke ')
              ? 'Connected'
              : state.isConnecting
                  ? 'Connecting'
                  : 'Disconnected',
          _getConnectionStatusColor(state.status),
        );
      },
    );
  }

  Widget _buildLEDStatus() {
    return StreamBuilder<bool>(
      stream: controller.ledStatusStream,
      initialData: controller.ledStatus,
      builder: (context, snapshot) {
        final isOn = snapshot.data ?? false;
        return _buildStatusRow(
          'LED Status',
          isOn ? 'ON' : 'OFF',
          isOn ? AppColors.success : AppColors.error,
        );
      },
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.robotoMono(
            textStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryDark,
            ),
          ),
        ),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: GoogleFonts.robotoMono(
                textStyle: TextStyle(
                  fontSize: 16,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getConnectionStatusColor(BLEConnectionStatus status) {
    switch (status) {
      case BLEConnectionStatus.connected:
        return AppColors.success;
      case BLEConnectionStatus.connecting:
        return AppColors.warning;
      case BLEConnectionStatus.disconnected:
        return AppColors.error;
    }
  }
}
