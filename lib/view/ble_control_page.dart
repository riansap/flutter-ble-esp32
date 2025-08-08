import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/ble_controller.dart';
import '../constants/app_colors.dart';
import '../services/bluetooth_permission_service.dart';
import '../widgets/connection_status_indicator.dart';
import '../widgets/bluetooth_status_section.dart';
import '../widgets/status_section.dart';
import '../widgets/control_section.dart';
import '../widgets/device_list_section.dart';

/// Halaman utama untuk kontrol BLE ESP32
class BLEControlPage extends StatefulWidget {
  const BLEControlPage({super.key});

  @override
  State<BLEControlPage> createState() => _BLEControlPageState();
}

class _BLEControlPageState extends State<BLEControlPage> {
  late final BLEController _controller;
  late final BluetoothPermissionService _permissionService;
  bool _isLoading = false;
  String _lastMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _initializeServices() {
    _permissionService = BluetoothPermissionService();
    _controller = BLEController();
    _setupMessageListener();
    _autoInitializeBluetooth();
  }

  void _setupMessageListener() {
    _controller.messageStream.listen((message) {
      if (mounted) {
        setState(() {
          _lastMessage = message;
        });
        _showSnackBar(message);
      }
    });
  }

  void _autoInitializeBluetooth() async {
    setState(() => _isLoading = true);

    try {
      final success = await _controller.initializeBluetooth();
      if (!success) {
        // Show Bluetooth status section untuk troubleshooting
        _showBluetoothStatusDialog();
      }
    } catch (e) {
      _showSnackBar('Error inisialisasi: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showBluetoothStatusDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Bluetooth Setup Required'),
        content: Text(
          'Bluetooth needs to be enabled and permissions granted to use this app. Please check the Bluetooth status section.',
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            child: Text('Retry'),
            onPressed: () {
              Navigator.of(context).pop();
              _autoInitializeBluetooth();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: _buildNavigationBar(),
      child: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  CupertinoNavigationBar _buildNavigationBar() {
    return CupertinoNavigationBar(
      middle: Text(
        'ESP32 BLE Controller',
        style: GoogleFonts.robotoMono(
          textStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
      ),
      trailing: ConnectionStatusIndicator(controller: _controller),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingView();
    }

    return Column(
      children: [
        // BluetoothStatusSection(
        //   controller: _controller,
        //   permissionService: _permissionService,
        // ),
        StatusSection(controller: _controller),
        ControlSection(controller: _controller),
        DeviceListSection(controller: _controller),
      ],
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CupertinoActivityIndicator(radius: 20),
          SizedBox(height: 14),
          Text('Menginisialisasi Bluetooth...',
              textAlign: TextAlign.center,
              style: GoogleFonts.robotoMono(
                textStyle: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              )),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: GoogleFonts.robotoMono(
              textStyle: TextStyle(
                color: AppColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            )),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primaryDark,
      ),
    );
  }
}
