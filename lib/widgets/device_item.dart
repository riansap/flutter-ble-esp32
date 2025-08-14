import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/ble_controller.dart';
import '../models/ble_device_model.dart';
import '../constants/app_colors.dart';

class DeviceItem extends StatelessWidget {
  final BLEDeviceModel device;
  final BLEController controller;

  const DeviceItem({
    super.key,
    required this.device,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BLEConnectionState>(
      stream: controller.connectionStateStream,
      initialData: controller.connectionState,
      builder: (context, snapshot) {
        final connectionState = snapshot.data!;
        final isConnected = connectionState.isConnected &&
            connectionState.device?.id == device.id;
        final isConnecting = connectionState.isConnecting &&
            connectionState.device?.id == device.id;

        return CupertinoButton(
          onPressed: isConnected
              ? controller.disconnect
              : isConnecting
                  ? null
                  : () => controller.connectToDevice(device),
          padding: EdgeInsets.zero,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                _buildDeviceIcon(isConnected),
                const SizedBox(width: 12),
                Expanded(child: _buildDeviceInfo()),
                _buildDeviceStatus(isConnected, isConnecting),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeviceIcon(bool isConnected) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isConnected ? AppColors.success : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        CupertinoIcons.device_phone_portrait,
        color: AppColors.white,
        size: 20,
      ),
    );
  }

  Widget _buildDeviceInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          device.name,
          style: GoogleFonts.robotoMono(
            textStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          device.id,
          style: GoogleFonts.robotoMono(
            textStyle: TextStyle(
              fontSize: 12,
              color: AppColors.disabled,
            ),
          ),
        ),
        if (device.rssi != null) ...[
          const SizedBox(height: 2),
          Text(
            'RSSI: ${device.rssi} dBm',
            style: GoogleFonts.robotoMono(
              textStyle: TextStyle(
                fontSize: 11,
                color: AppColors.disabled,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDeviceStatus(bool isConnected, bool isConnecting) {
    if (isConnecting) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoActivityIndicator(
            radius: 8,
            color: AppColors.warning,
          ),
          SizedBox(width: 8),
          Text(
            'Connecting...',
            style: GoogleFonts.robotoMono(
              textStyle: TextStyle(
                fontSize: 12,
                color: AppColors.warning,
              ),
            ),
          ),
        ],
      );
    }

    if (isConnected) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.checkmark_circle_fill,
            color: AppColors.success,
            size: 16,
          ),
          SizedBox(width: 2),
        ],
      );
    }

    return const Icon(
      CupertinoIcons.chevron_right,
      color: AppColors.disabled,
      size: 16,
    );
  }
}
