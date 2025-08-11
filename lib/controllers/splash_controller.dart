import 'dart:async';
import '../services/bluetooth_permission_service.dart';

enum InitializationState {
  initial,
  checkingSupport,
  checkingPermissions,
  requestingPermissions,
  checkingBluetooth,
  enablingBluetooth,
  completed,
  error
}

class SplashController {
  final BluetoothPermissionService _permissionService =
      BluetoothPermissionService();

  final StreamController<InitializationState> _stateController =
      StreamController<InitializationState>.broadcast();
  final StreamController<String> _messageController =
      StreamController<String>.broadcast();

  Stream<InitializationState> get stateStream => _stateController.stream;
  Stream<String> get messageStream => _messageController.stream;

  bool _isInitializing = false;

  Future<bool> initializeApp() async {
    if (_isInitializing) return false;
    _isInitializing = true;

    try {
      // Check Bluetooth Support
      _updateState(
          InitializationState.checkingSupport, 'Checking Bluetooth support...');
      final isSupported = await _permissionService.isBluetoothSupported();
      if (!isSupported) {
        _handleError('Bluetooth is not supported on this device');
        return false;
      }

      // Check Permissions
      _updateState(InitializationState.checkingPermissions,
          'Checking Bluetooth permissions...');
      final hasPermissions = await _permissionService.checkAllPermissions();
      if (!hasPermissions) {
        _updateState(InitializationState.requestingPermissions,
            'Requesting Bluetooth permissions...');
        final permissionsGranted =
            await _permissionService.requestAllPermissions();
        if (!permissionsGranted) {
          _handleError('Bluetooth permissions are required');
          return false;
        }
      }

      // Check Bluetooth Status
      _updateState(InitializationState.checkingBluetooth,
          'Checking Bluetooth status...');
      final isEnabled = await _permissionService.isBluetoothEnabled();
      if (!isEnabled) {
        _updateState(
            InitializationState.enablingBluetooth, 'Enabling Bluetooth...');
        final bluetoothEnabled =
            await _permissionService.requestBluetoothEnable();
        if (!bluetoothEnabled) {
          _handleError('Bluetooth must be enabled');
          return false;
        }
      }

      _updateState(InitializationState.completed, 'Initialization complete');
      return true;
    } catch (e) {
      _handleError('Initialization failed: $e');
      return false;
    } finally {
      _isInitializing = false;
    }
  }

  void _updateState(InitializationState state, String message) {
    _stateController.add(state);
    _messageController.add(message);
  }

  void _handleError(String message) {
    _updateState(InitializationState.error, message);
  }

  void dispose() {
    _stateController.close();
    _messageController.close();
  }
}
