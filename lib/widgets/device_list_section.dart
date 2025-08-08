import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/ble_controller.dart';
import '../models/ble_device_model.dart';
import '../constants/app_colors.dart';
import 'device_item.dart';

class DeviceListSection extends StatelessWidget {
  final BLEController controller;

  const DeviceListSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(16),
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
            _buildDeviceListHeader(),
            Expanded(child: _buildDeviceList()),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceListHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSectionTitle('Perangkat ESP32'),
          _buildScanButton(),
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

  Widget _buildScanButton() {
    return StreamBuilder<bool>(
      stream: controller.scanningStream,
      initialData: controller.isScanning,
      builder: (context, snapshot) {
        final isScanning = snapshot.data ?? false;

        return CupertinoButton(
          onPressed: isScanning ? controller.stopScan : controller.startScan,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.primaryMedium,
          borderRadius: BorderRadius.circular(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isScanning) ...[
                CupertinoActivityIndicator(
                  radius: 8,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                isScanning ? 'Stop' : 'Scan',
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

  Widget _buildDeviceList() {
    return StreamBuilder<List<BLEDeviceModel>>(
      stream: controller.devicesStream,
      initialData: controller.foundDevices,
      builder: (context, snapshot) {
        final devices = snapshot.data ?? [];

        if (devices.isEmpty) {
          return _buildEmptyDeviceList();
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: devices.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) => DeviceItem(
            device: devices[index],
            controller: controller,
          ),
        );
      },
    );
  }

  Widget _buildEmptyDeviceList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.bluetooth,
            size: 48,
            color: AppColors.disabled,
          ),
          SizedBox(height: 16),
          Text(
            'Tidak ada perangkat ditemukan',
            style: GoogleFonts.robotoMono(
              textStyle: TextStyle(
                color: AppColors.disabled,
                fontSize: 16,
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tekan tombol Scan untuk mencari',
            style: GoogleFonts.robotoMono(
              textStyle: TextStyle(
                color: AppColors.disabled,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
