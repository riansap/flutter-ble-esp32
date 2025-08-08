import 'dart:async';
import '../services/esp32_ble_service.dart';
import '../services/bluetooth_permission_service.dart';
import '../models/ble_device_model.dart';

/// Controller utama untuk mengelola BLE operations
///
/// Kelas ini bertindak sebagai layer antara UI dan services, mengelola:
/// - State management untuk BLE operations
/// - Koordinasi antara permission service dan BLE service
/// - Stream management untuk real-time updates
/// - Business logic untuk aplikasi BLE
class BLEController {
  // === SERVICES ===
  final ESP32BLEService _bleService = ESP32BLEService();
  final BluetoothPermissionService _permissionService =
      BluetoothPermissionService();

  // === STATE VARIABLES ===
  /// Status LED saat ini (true = ON, false = OFF)
  bool _ledStatus = false;

  /// Daftar perangkat ESP32 yang ditemukan saat scanning
  List<BLEDeviceModel> _foundDevices = [];

  /// Status koneksi saat ini
  BLEConnectionState _connectionState = BLEConnectionState.disconnected();

  // === STREAM CONTROLLERS ===
  /// Stream untuk status LED
  final StreamController<bool> _ledStatusController =
      StreamController<bool>.broadcast();

  /// Stream untuk daftar perangkat yang ditemukan
  final StreamController<List<BLEDeviceModel>> _devicesController =
      StreamController<List<BLEDeviceModel>>.broadcast();

  /// Stream untuk status koneksi
  final StreamController<BLEConnectionState> _connectionStateController =
      StreamController<BLEConnectionState>.broadcast();

  /// Stream untuk pesan/notifikasi ke user
  final StreamController<String> _messageController =
      StreamController<String>.broadcast();

  // === GETTERS ===
  /// Status LED saat ini
  bool get ledStatus => _ledStatus;

  /// Daftar perangkat yang ditemukan
  List<BLEDeviceModel> get foundDevices => _foundDevices;

  /// Status koneksi saat ini
  BLEConnectionState get connectionState => _connectionState;

  /// Apakah sedang terhubung ke perangkat
  bool get isConnected => _bleService.isConnected;

  /// Apakah sedang melakukan scanning
  bool get isScanning => _bleService.isScanning;

  // === STREAMS ===
  /// Stream untuk monitoring status LED
  Stream<bool> get ledStatusStream => _ledStatusController.stream;

  /// Stream untuk monitoring daftar perangkat
  Stream<List<BLEDeviceModel>> get devicesStream => _devicesController.stream;

  /// Stream untuk monitoring status koneksi
  Stream<BLEConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  /// Stream untuk pesan/notifikasi
  Stream<String> get messageStream => _messageController.stream;

  /// Stream untuk status scanning
  Stream<bool> get scanningStream => _bleService.scanningStream;

  // === CONSTRUCTOR ===
  BLEController() {
    _initializeStreamListeners();
  }

  // === INITIALIZATION ===

  /// Inisialisasi listeners untuk semua streams dari services
  ///
  /// Method ini menghubungkan streams dari services ke controller streams
  /// dan mengelola state updates berdasarkan events dari services
  void _initializeStreamListeners() {
    _setupDeviceStreamListener();
    _setupConnectionStreamListener();
    _setupLEDStatusStreamListener();
    _setupErrorStreamListener();
  }

  /// Setup listener untuk stream perangkat yang ditemukan
  void _setupDeviceStreamListener() {
    _bleService.devicesStream.listen((devices) {
      // Convert BluetoothDevice ke BLEDeviceModel
      _foundDevices = devices
          .map((device) => BLEDeviceModel.fromBluetoothDevice(device))
          .toList();

      // Trigger UI untuk update daftar perangkat
      _devicesController.add(_foundDevices);
    });
  }

  /// Setup listener untuk status koneksi
  void _setupConnectionStreamListener() {
    _bleService.connectionStream.listen((connected) {
      if (connected) {
        _handleConnectionEstablished();
      } else {
        _handleConnectionLost();
      }

      // Trigger UI untuk update status koneksi
      _connectionStateController.add(_connectionState);
    });
  }

  /// Setup listener untuk status LED real-time dari ESP32
  void _setupLEDStatusStreamListener() {
    _bleService.ledStatusStream.listen((status) {
      _updateLEDStatus(status);
    });
  }

  /// Setup listener untuk error messages dari services
  void _setupErrorStreamListener() {
    _bleService.errorStream.listen((error) {
      _notifyUser(error);
    });
  }

  // === BLUETOOTH SETUP ===

  /// Inisialisasi Bluetooth (permissions + enable)
  ///
  /// Method ini harus dipanggil sebelum melakukan operasi BLE lainnya.
  /// Akan meminta izin dan mengaktifkan Bluetooth jika diperlukan.
  ///
  /// Returns: true jika inisialisasi berhasil
  Future<bool> initializeBluetooth() async {
    try {
      // Cek apakah Bluetooth didukung
      final isSupported = await _permissionService.isBluetoothSupported();
      if (!isSupported) {
        _notifyUser('Bluetooth tidak didukung pada perangkat ini');
        return false;
      }

      // Cek dan request permissions
      final hasPermissions = await _permissionService.checkAllPermissions();
      if (!hasPermissions) {
        _notifyUser('Meminta izin Bluetooth...');
        final permissionsGranted =
            await _permissionService.requestAllPermissions();
        if (!permissionsGranted) {
          _notifyUser('Izin Bluetooth diperlukan untuk melanjutkan');
          return false;
        }
      }

      // Cek dan request enable Bluetooth
      final isEnabled = await _permissionService.isBluetoothEnabled();
      if (!isEnabled) {
        _notifyUser('Bluetooth tidak aktif, meminta aktivasi...');
        final bluetoothEnabled =
            await _permissionService.requestBluetoothEnable();
        if (!bluetoothEnabled) {
          _notifyUser('Bluetooth harus diaktifkan untuk melanjutkan');
          return false;
        }
      }

      _notifyUser('Bluetooth siap digunakan');
      return true;
    } catch (e) {
      final errorMessage = _getBluetoothErrorMessage(e.toString());
      _notifyUser(errorMessage);
      return false;
    }
  }

  /// Matikan bluetooth jika sedang aktif
  Future<void> turnOffBluetooth() async {
    try {
      // Cek Bluetooth lalu matikan jika enabled
      final isEnabled = await _permissionService.isBluetoothEnabled();
      if (isEnabled) {
        await _permissionService.openBluetoothSettings();
      }
    } catch (e) {
      _notifyUser('Error saat menonaktifkan Bluetooth: $e');
    }
  }

  /// Get pesan error yang user-friendly untuk Bluetooth
  String _getBluetoothErrorMessage(String error) {
    if (error.toLowerCase().contains('bluetooth') &&
        error.toLowerCase().contains('not') &&
        error.toLowerCase().contains('enabled')) {
      return 'Bluetooth tidak aktif. Silakan aktifkan Bluetooth dan coba lagi.';
    } else if (error.toLowerCase().contains('permission')) {
      return 'Izin Bluetooth diperlukan. Silakan berikan izin dan coba lagi.';
    } else if (error.toLowerCase().contains('not supported')) {
      return 'Bluetooth tidak didukung pada perangkat ini.';
    } else {
      return 'Error inisialisasi Bluetooth: $error';
    }
  }

  /// Check status Bluetooth secara real-time
  Future<Map<String, dynamic>> getBluetoothStatus() async {
    return await _permissionService.getBluetoothStatus();
  }

  /// Stream untuk monitoring Bluetooth state
  Stream<bool> get bluetoothStateStream =>
      _permissionService.bluetoothStateStream;

  // === SCANNING OPERATIONS ===

  /// Memulai scanning untuk mencari perangkat ESP32
  ///
  /// Proses:
  /// 1. Inisialisasi Bluetooth jika belum
  /// 2. Clear daftar perangkat sebelumnya
  /// 3. Mulai scanning menggunakan BLE service
  /// 4. Update UI melalui streams
  Future<void> startScan() async {
    try {
      // Pastikan Bluetooth sudah siap
      final initialized = await initializeBluetooth();
      if (!initialized) {
        _notifyUser('Gagal inisialisasi Bluetooth');
        return;
      }

      // Clear hasil scan sebelumnya
      _clearFoundDevices();

      // Mulai scanning
      await _bleService.startScan();
      _notifyUser('Memulai pencarian perangkat ESP32...');
    } catch (e) {
      _notifyUser('Error saat scanning: $e');
    }
  }

  /// Refresh daftar perangkat (alias untuk startScan)
  Future<void> refreshDevices() async {
    // Clear devices hanya saat refresh
    _clearFoundDevices();
    await startScan();
  }

  /// Menghentikan scanning
  Future<void> stopScan() async {
    try {
      await _bleService.stopScan();
      _notifyUser('Scanning dihentikan');
    } catch (e) {
      _notifyUser('Error saat menghentikan scan: $e');
    }
  }

  // === CONNECTION OPERATIONS ===

  /// Menghubungkan ke perangkat ESP32
  ///
  /// [deviceModel] - Model perangkat yang akan dihubungkan
  ///
  /// Proses:
  /// 1. Update status ke "connecting"
  /// 2. Attempt koneksi melalui BLE service
  /// 3. Jika berhasil: enable notifications dan sync LED status
  /// 4. Update UI dengan hasil koneksi
  ///
  /// Returns: true jika koneksi berhasil
  Future<bool> connectToDevice(BLEDeviceModel deviceModel) async {
    try {
      // Update status ke connecting
      _updateConnectionState(
        BLEConnectionState.connecting(deviceModel),
      );

      // Trigger UI untuk update status koneksi
      _notifyUser('Menghubungkan ke ${deviceModel.name}...');

      // Attempt koneksi melalui service BLE ke device
      final success = await _bleService.connectToDevice(deviceModel.device);

      if (success) {
        await _handleSuccessfulConnection(deviceModel);
        return true;
      } else {
        await _handleFailedConnection(deviceModel);
        return false;
      }
    } catch (e) {
      await _handleConnectionError(deviceModel, e);
      return false;
    }
  }

  /// Memutuskan koneksi dari perangkat
  Future<void> disconnect() async {
    try {
      await _bleService.disconnect();
      _notifyUser('Koneksi terputus');
    } catch (e) {
      _notifyUser('Error saat disconnect: $e');
    }
  }

  // === LED CONTROL OPERATIONS ===

  /// Toggle status LED (ON/OFF)
  ///
  /// Method ini akan membalik status LED saat ini.
  /// Jika LED menyala, akan dimatikan. Jika mati, akan dinyalakan.
  Future<void> toggleLED() async {
    final newStatus = !_ledStatus;
    await _setLEDWithFeedback(newStatus);
  }

  /// Set status LED secara spesifik
  ///
  /// [status] - true untuk menyalakan, false untuk mematikan
  Future<void> setLED(bool status) async {
    await _setLEDWithFeedback(status);
  }

  /// Refresh status LED dari ESP32
  ///
  /// Method ini akan membaca status LED terbaru dari ESP32
  /// dan update local state sesuai dengan kondisi aktual di ESP32
  Future<void> refreshLEDStatus() async {
    try {
      final status = await _bleService.readLEDStatus();
      if (status != null) {
        _updateLEDStatus(status);
        _notifyUser('Status LED diperbarui: ${status ? 'ON' : 'OFF'}');
      } else {
        _notifyUser('Gagal membaca status LED');
      }
    } catch (e) {
      _notifyUser('Error refresh LED status: $e');
    }
  }

  // === PRIVATE HELPER METHODS ===

  /// Handle koneksi yang berhasil
  Future<void> _handleSuccessfulConnection(BLEDeviceModel deviceModel) async {
    // Enable notifications untuk real-time updates
    await _bleService.enableNotifications();

    // Sync status LED awal
    await _syncInitialLEDStatus();

    _notifyUser('Terhubung ke ${deviceModel.name}');
  }

  /// Handle koneksi yang gagal
  Future<void> _handleFailedConnection(BLEDeviceModel deviceModel) async {
    _updateConnectionState(BLEConnectionState.disconnected());
    _notifyUser('Gagal terhubung ke ${deviceModel.name}');
  }

  /// Handle error saat koneksi
  Future<void> _handleConnectionError(
      BLEDeviceModel deviceModel, dynamic error) async {
    _updateConnectionState(BLEConnectionState.disconnected());
    _notifyUser('Error koneksi ke ${deviceModel.name}: $error');
  }

  /// Handle saat koneksi berhasil terbentuk
  void _handleConnectionEstablished() {
    final device = _bleService.connectedDevice;
    if (device != null) {
      _connectionState = BLEConnectionState.connected(
        BLEDeviceModel.fromBluetoothDevice(device),
      );
    }
  }

  /// Handle saat koneksi terputus
  void _handleConnectionLost() {
    _connectionState = BLEConnectionState.disconnected();

    // Reset LED status karena tidak terhubung
    _updateLEDStatus(false);
  }

  /// Set LED dengan feedback ke user
  Future<void> _setLEDWithFeedback(bool status) async {
    if (!isConnected) {
      _notifyUser('Tidak terhubung ke ESP32');
      return;
    }

    try {
      final success = await _bleService.sendLEDCommand(status);

      if (success) {
        // Update local state (akan di-override oleh notification dari ESP32)
        _updateLEDStatus(status);
        _notifyUser('LED ${status ? 'ON' : 'OFF'}');
      } else {
        _notifyUser('Gagal mengubah status LED');
      }
    } catch (e) {
      _notifyUser('Error LED control: $e');
    }
  }

  /// Sync status LED awal setelah koneksi
  Future<void> _syncInitialLEDStatus() async {
    try {
      final status = await _bleService.readLEDStatus();
      if (status != null) {
        _updateLEDStatus(status);
      }
    } catch (e) {
      // Silent fail untuk initial sync
    }
  }

  /// Update status LED dan notify streams
  void _updateLEDStatus(bool status) {
    _ledStatus = status;
    _ledStatusController.add(_ledStatus);
  }

  /// Update status koneksi dan notify streams
  void _updateConnectionState(BLEConnectionState state) {
    _connectionState = state;
    _connectionStateController.add(_connectionState);
  }

  /// Clear daftar perangkat yang ditemukan
  void _clearFoundDevices() {
    _foundDevices.clear();
    _devicesController.add(_foundDevices);
  }

  /// Kirim notifikasi ke user melalui message stream
  void _notifyUser(String message) {
    _messageController.add(message);
  }

  // === CLEANUP ===

  /// Cleanup semua resources
  ///
  /// Method ini harus dipanggil saat controller tidak digunakan lagi
  /// untuk mencegah memory leaks dan resource conflicts
  void dispose() {
    // Dispose BLE service
    _bleService.dispose();

    // Close semua stream controllers
    _ledStatusController.close();
    _devicesController.close();
    _connectionStateController.close();
    _messageController.close();
  }
}
