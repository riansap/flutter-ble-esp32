import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/ble_controller.dart';
import '../constants/app_colors.dart';
import '../services/bluetooth_permission_service.dart';

class BluetoothStatusSection extends StatelessWidget {
  final BLEController controller;
  final BluetoothPermissionService permissionService;

  const BluetoothStatusSection({
    super.key,
    required this.controller,
    required this.permissionService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
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
          _buildBluetoothStatusHeader(context),
          const SizedBox(height: 12),
          _buildBluetoothStatus(context),
          const SizedBox(height: 12),
          _buildPermissionStatus(),
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

  Widget _buildBluetoothStatusHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSectionTitle('Status Bluetooth'),
          _buildEnableBluetoothButton(context),
        ],
      ),
    );
  }

  Widget _buildEnableBluetoothButton(BuildContext context) {
    return StreamBuilder<bool>(
      stream: permissionService.bluetoothStateStream,
      builder: (context, snapshot) {
        final isEnabled = snapshot.data ?? false;
        final isChecking = snapshot.connectionState == ConnectionState.waiting;

        return CupertinoButton(
          onPressed: isEnabled || isChecking
              ? () => controller.turnOffBluetooth()
              : () => _requestBluetoothEnable(context),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: isEnabled ? AppColors.error : AppColors.primaryMedium,
          borderRadius: BorderRadius.circular(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isChecking) ...[
                CupertinoActivityIndicator(
                  radius: 8,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                isEnabled ? 'Disable' : 'Enable',
                style: GoogleFonts.robotoMono(
                  textStyle: TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBluetoothStatus(BuildContext context) {
    return StreamBuilder<bool>(
      stream: permissionService.bluetoothStateStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildStatusRow(
            'Bluetooth',
            'Checking...',
            AppColors.warning,
            showAction: false,
          );
        }

        final isEnabled = snapshot.data ?? false;

        return _buildStatusRow(
          'Bluetooth',
          isEnabled ? 'Enabled' : 'Disabled',
          isEnabled ? AppColors.success : AppColors.error,
          showAction: !isEnabled,
          actionText: 'Enable',
          onActionPressed: () => _requestBluetoothEnable(context),
        );
      },
    );
  }

  Widget _buildPermissionStatus() {
    return FutureBuilder<bool>(
      future: permissionService.checkAllPermissions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildStatusRow(
            'Permissions',
            'Checking...',
            AppColors.warning,
            showAction: false,
          );
        }

        final hasPermissions = snapshot.data ?? false;

        return _buildStatusRow(
          'Permissions',
          hasPermissions ? 'Granted' : 'Required',
          hasPermissions ? AppColors.success : AppColors.warning,
          showAction: !hasPermissions,
          actionText: 'Grant',
        );
      },
    );
  }

  Widget _buildStatusRow(
    String label,
    String value,
    Color color, {
    bool showAction = false,
    String? actionText,
    VoidCallback? onActionPressed,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // KIRI: Label
        Row(
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
          ],
        ),

        // KANAN: Status bulat + Teks status atau tombol aksi
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
                  fontSize: 14,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (showAction &&
                actionText != null &&
                onActionPressed != null) ...[
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onActionPressed,
                child: Text(
                  actionText,
                  style: GoogleFonts.robotoMono(
                    textStyle: TextStyle(
                      fontSize: 14,
                      color: AppColors.primaryMedium,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Future<void> _requestBluetoothEnable(BuildContext context) async {
    try {
      final success = await permissionService.requestBluetoothEnable();

      if (!success) {
        _showErrorDialog(
          context,
          'Bluetooth Required',
          'Please enable Bluetooth to use this app. You can enable it from Settings.',
        );
      }
    } catch (e) {
      _showErrorDialog(
        context,
        'Error',
        'Failed to enable Bluetooth: $e',
      );
    }
  }

  Future<void> _requestPermissions(BuildContext context) async {
    try {
      final success = await permissionService.requestAllPermissions();

      if (!success) {
        final isPermanentlyDenied =
            await permissionService.hasPermissionsPermanentlyDenied();

        if (isPermanentlyDenied) {
          _showPermissionDialog(context);
        } else {
          _showErrorDialog(
            context,
            'Permissions Required',
            'Bluetooth permissions are required to scan and connect to devices.',
          );
        }
      }
    } catch (e) {
      _showErrorDialog(
        context,
        'Error',
        'Failed to request permissions: $e',
      );
    }
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Permissions Required'),
        content: Text(
          'Bluetooth permissions have been permanently denied. Please enable them in Settings to use this app.',
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            child: Text('Settings'),
            onPressed: () {
              Navigator.of(context).pop();
              permissionService.openAppSettings();
            },
          ),
        ],
      ),
    );
  }
}
