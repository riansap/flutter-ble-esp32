import 'package:flutter/cupertino.dart';
import '../controllers/ble_controller.dart';
import '../models/ble_device_model.dart';
import '../constants/app_colors.dart';

class ConnectionStatusIndicator extends StatelessWidget {
  final BLEController controller;

  const ConnectionStatusIndicator({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BLEConnectionState>(
      stream: controller.connectionStateStream,
      initialData: controller.connectionState,
      builder: (context, snapshot) {
        final state = snapshot.data!;
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: _getConnectionStatusColor(state.status),
            shape: BoxShape.circle,
          ),
        );
      },
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