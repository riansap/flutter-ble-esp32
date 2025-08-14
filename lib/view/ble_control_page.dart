import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/ble_controller.dart';
import '../constants/app_colors.dart';
import '../services/bluetooth_permission_service.dart';
import '../widgets/connection_status_indicator.dart';
import '../widgets/status_section.dart';
import '../widgets/control_section.dart';
import '../widgets/device_list_section.dart';
import 'detail_app_page.dart';

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
        setState(
          () {
            _lastMessage = message;
          },
        );
        _showSnackBar(message);
      }
    });
  }

  void _autoInitializeBluetooth() async {
    setState(() => _isLoading = true);

    try {
      final success = await _controller.initializeBluetooth();
      if (!success) {
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConnectionStatusIndicator(controller: _controller),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (context) => const DetailAppPage(),
              ),
            ),
            child: const Icon(
              CupertinoIcons.info_circle,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingView();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StatusSection(controller: _controller),
              ControlSection(controller: _controller),
              DeviceListSection(
                controller: _controller,
              ),
            ],
          ),
        );
      },
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

    // Gunakan modal popup sebagai pengganti snackbar
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        message: Text(message,
            textAlign: TextAlign.center,
            style: GoogleFonts.robotoMono(
              textStyle: TextStyle(
                color: AppColors.primaryDark,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            )),
        actions: [
          CupertinoActionSheetAction(
            child: Text('OK',
                textAlign: TextAlign.center,
                style: GoogleFonts.robotoMono(
                  textStyle: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                )),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }
}
