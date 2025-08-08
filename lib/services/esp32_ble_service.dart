import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../constants/ble_constants.dart';

/// Service untuk mengelola komunikasi BLE dengan ESP32
///
/// Service ini bertanggung jawab untuk:
/// - Scanning dan discovery perangkat ESP32
/// - Koneksi dan disconnection management
/// - Komunikasi data dengan ESP32 (LED control, status reading)
/// - Real-time notifications dari ESP32
/// - Error handling dan recovery
class ESP32BLEService {
  /// Timeout untuk operasi koneksi
  static const Duration connectionTimeout = Duration(seconds: 30);

  /// Timeout untuk operasi scanning
  static const Duration scanTimeout = Duration(seconds: 15);

  // === STATE VARIABLES ===
  /// Perangkat yang sedang terhubung
  BluetoothDevice? _connectedDevice;

  /// Characteristic untuk komunikasi
  BluetoothCharacteristic? _targetCharacteristic;

  /// Status scanning
  bool _isScanning = false;

  /// Status koneksi
  bool _isConnected = false;

  /// Subscription untuk monitoring koneksi
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  /// Subscription untuk scan results
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  /// Subscription untuk notifications
  StreamSubscription<List<int>>? _notificationSubscription;

  // === STREAM CONTROLLERS ===
  /// Stream untuk perangkat yang ditemukan saat scanning
  final StreamController<List<BluetoothDevice>> _devicesController =
      StreamController<List<BluetoothDevice>>.broadcast();

  /// Stream untuk status koneksi
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  /// Stream untuk status scanning
  final StreamController<bool> _scanningController =
      StreamController<bool>.broadcast();

  /// Stream untuk status LED real-time dari ESP32
  final StreamController<bool> _ledStatusController =
      StreamController<bool>.broadcast();

  /// Stream untuk error messages
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  // === GETTERS ===
  /// Perangkat yang sedang terhubung
  BluetoothDevice? get connectedDevice => _connectedDevice;

  /// Apakah sedang terhubung ke perangkat
  bool get isConnected => _isConnected;

  /// Apakah sedang melakukan scanning
  bool get isScanning => _isScanning;

  // === STREAMS ===
  /// Stream untuk monitoring perangkat yang ditemukan
  Stream<List<BluetoothDevice>> get devicesStream => _devicesController.stream;

  /// Stream untuk monitoring status koneksi
  Stream<bool> get connectionStream => _connectionController.stream;

  /// Stream untuk monitoring status scanning
  Stream<bool> get scanningStream => _scanningController.stream;

  /// Stream untuk status LED real-time dari ESP32
  Stream<bool> get ledStatusStream => _ledStatusController.stream;

  /// Stream untuk error messages
  Stream<String> get errorStream => _errorController.stream;

  // === SCANNING METHODS ===

  /// Memulai scanning untuk mencari perangkat ESP32
  ///
  /// [timeout] - Durasi maksimal scanning (default: 15 detik)
  ///
  /// Method ini akan:
  /// 1. Menghentikan scan sebelumnya jika ada
  /// 2. Memulai scan baru
  /// 3. Filter hanya perangkat dengan nama yang sesuai
  /// 4. Update stream dengan perangkat yang ditemukan
  Future<void> startScan({Duration timeout = scanTimeout}) async {
    try {
      if (_isScanning) {
        await _stopCurrentScan();
      }

      _updateScanningState(true);

      // Mulai dengan connected device jika ada
      if (_connectedDevice != null) {
        _devicesController.add([_connectedDevice!]);
      }

      await FlutterBluePlus.startScan(timeout: timeout);

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        _processScanResults(results);
      });

      Timer(timeout, () async {
        await _stopCurrentScan();
      });
    } catch (e) {
      _handleError('Scan error: $e');
    }
  }

  /// Menghentikan scanning yang sedang berjalan
  Future<void> stopScan() async {
    await _stopCurrentScan();
  }

  /// Internal method untuk menghentikan scan
  Future<void> _stopCurrentScan() async {
    try {
      if (_isScanning) {
        await FlutterBluePlus.stopScan();
        await _scanSubscription?.cancel();
        _scanSubscription = null;
        _updateScanningState(false);
      }
    } catch (e) {
      _handleError('Error stopping scan: $e');
    }
  }

  /// Memproses hasil scan dan filter perangkat ESP32
  void _processScanResults(List<ScanResult> results) {
    Set<String> deviceIds = {};
    List<BluetoothDevice> allDevices = [];

    // Tambahkan connected device jika ada
    if (_connectedDevice != null) {
      deviceIds.add(_connectedDevice!.remoteId.toString());
      allDevices.add(_connectedDevice!);
    }

    // Tambahkan devices dari scan results
    for (ScanResult result in results) {
      if (result.device.platformName.isNotEmpty &&
          !deviceIds.contains(result.device.remoteId.toString())) {
        deviceIds.add(result.device.remoteId.toString());
        allDevices.add(result.device);
      }
    }

    _devicesController.add(List.from(allDevices));
  }

  /// Update status scanning dan notify listeners
  void _updateScanningState(bool scanning) {
    _isScanning = scanning;
    _scanningController.add(_isScanning);
  }

  // === CONNECTION METHODS ===

  /// Menghubungkan ke perangkat ESP32
  ///
  /// [device] - BluetoothDevice yang akan dihubungkan
  ///
  /// Returns: true jika koneksi berhasil, false jika gagal
  ///
  /// Proses koneksi:
  /// 1. Disconnect dari perangkat sebelumnya (jika ada)
  /// 2. Attempt koneksi ke perangkat target
  /// 3. Discover services dan characteristics
  /// 4. Setup notifications untuk real-time updates
  /// 5. Verify komunikasi dengan ESP32
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      // Step 1: Disconnect dari perangkat sebelumnya
      if (_isConnected) {
        await disconnect();
      }

      // Step 2: Attempt koneksi dengan timeout
      await device.connect(timeout: connectionTimeout);

      // Step 3: Discover services
      final services = await device.discoverServices();

      // Step 4: Cari service dan characteristic yang tepat
      final targetCharacteristic = _findTargetCharacteristic(services);
      if (targetCharacteristic == null) {
        await device.disconnect();
        _handleError('Service atau Characteristic tidak ditemukan');
        return false;
      }

      // Step 5: Setup koneksi berhasil
      _setupSuccessfulConnection(device, targetCharacteristic);

      // Step 6: Enable notifications untuk real-time updates
      await _enableNotifications();

      return true;
    } catch (e) {
      _handleError('Koneksi gagal: $e');
      return false;
    }
  }

  /// Mencari target characteristic dalam services
  BluetoothCharacteristic? _findTargetCharacteristic(
      List<BluetoothService> services) {
    for (BluetoothService service in services) {
      if (service.uuid.toString().toLowerCase() ==
          BLEConstants.serviceUUID.toLowerCase()) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.uuid.toString().toLowerCase() ==
              BLEConstants.ledCharacteristicUUID.toLowerCase()) {
            return characteristic;
          }
        }
      }
    }
    return null;
  }

  /// Setup koneksi yang berhasil
  void _setupSuccessfulConnection(
      BluetoothDevice device, BluetoothCharacteristic characteristic) {
    _connectedDevice = device;
    _targetCharacteristic = characteristic;
    _updateConnectionState(true);

    // Update device list untuk menampilkan connected device
    _updateDeviceListWithConnected();

    // Monitor status koneksi
    _setupConnectionMonitoring();
  }

  void _updateDeviceListWithConnected() {
    if (_connectedDevice != null) {
      // Trigger update device list dengan connected device
      final currentDevices =
          _devicesController.hasListener ? [] : <BluetoothDevice>[];
      final deviceIds =
          currentDevices.map((d) => d.remoteId.toString()).toSet();

      if (!deviceIds.contains(_connectedDevice!.remoteId.toString())) {
        currentDevices.add(_connectedDevice!);
        _devicesController.add(List.from(currentDevices));
      }
    }
  }

  /// Setup monitoring untuk status koneksi
  void _setupConnectionMonitoring() {
    _connectionSubscription = _connectedDevice!.connectionState.listen((state) {
      final isConnected = state == BluetoothConnectionState.connected;

      if (!isConnected && _isConnected) {
        // Koneksi terputus
        _handleDisconnection();
      }
    });
  }

  /// Enable notifications untuk real-time updates dari ESP32
  Future<void> enableNotifications() async {
    await _enableNotifications();
  }

  /// Internal method untuk enable notifications
  Future<void> _enableNotifications() async {
    if (!_isConnectionReady()) return;

    try {
      // Enable notifications
      await _targetCharacteristic!.setNotifyValue(true);

      // Listen untuk notifications dari ESP32
      _notificationSubscription =
          _targetCharacteristic!.lastValueStream.listen((data) {
        _processNotificationData(data);
      });
    } catch (e) {
      _handleError('Gagal enable notifications: $e');
    }
  }

  /// Memproses data notification dari ESP32
  void _processNotificationData(List<int> data) {
    if (data.isNotEmpty) {
      // Protocol: [1] = LED ON, [0] = LED OFF
      final ledStatus = data[0] == 1;
      _ledStatusController.add(ledStatus);
    }
  }

  /// Memutuskan koneksi dari perangkat
  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
      } catch (e) {
        _handleError('Error saat disconnect: $e');
      }
    }
    _handleDisconnection();
  }

  /// Handle saat koneksi terputus
  void _handleDisconnection() {
    // Cancel subscriptions
    _connectionSubscription?.cancel();
    _notificationSubscription?.cancel();

    // Reset state
    _connectedDevice = null;
    _targetCharacteristic = null;
    _updateConnectionState(false);
  }

  /// Update status koneksi dan notify listeners
  void _updateConnectionState(bool connected) {
    _isConnected = connected;
    _connectionController.add(_isConnected);
  }

  // === LED CONTROL METHODS ===

  /// Mengirim perintah LED ke ESP32
  ///
  /// [turnOn] - true untuk menyalakan LED, false untuk mematikan
  ///
  /// Returns: true jika perintah berhasil dikirim
  ///
  /// Protocol komunikasi:
  /// - [1] = LED ON
  /// - [0] = LED OFF
  Future<bool> sendLEDCommand(bool turnOn) async {
    if (!_isConnectionReady()) {
      _handleError('Tidak terhubung ke ESP32');
      return false;
    }

    try {
      // Protocol: [1] = ON, [0] = OFF (sesuai kode Arduino)
      List<int> command = turnOn ? [1] : [0];
      await _targetCharacteristic!.write(command);
      return true;
    } catch (e) {
      _handleError('Gagal mengirim perintah LED: $e');
      return false;
    }
  }

  /// Membaca status LED dari ESP32
  ///
  /// Returns: true jika LED menyala, false jika mati, null jika error
  ///
  /// Method ini membaca nilai characteristic untuk mendapatkan
  /// status LED terkini dari ESP32
  Future<bool?> readLEDStatus() async {
    if (!_isConnectionReady()) {
      _handleError('Tidak terhubung ke ESP32');
      return null;
    }

    try {
      final data = await _targetCharacteristic!.read();
      if (data.isNotEmpty) {
        // Protocol: [1] = LED ON, [0] = LED OFF
        return data[0] == 1;
      }
      return null;
    } catch (e) {
      _handleError('Gagal membaca status LED: $e');
      return null;
    }
  }

  /// Membaca data mentah dari characteristic
  ///
  /// Returns: Data dalam bentuk List<int>, null jika error
  Future<List<int>?> readCharacteristic() async {
    if (!_isConnectionReady()) {
      _handleError('Tidak terhubung ke ESP32');
      return null;
    }

    try {
      return await _targetCharacteristic!.read();
    } catch (e) {
      _handleError('Gagal membaca characteristic: $e');
      return null;
    }
  }

  /// Mengirim data custom ke ESP32
  ///
  /// [data] - Data yang akan dikirim dalam bentuk List<int>
  ///
  /// Returns: true jika berhasil dikirim
  Future<bool> sendCustomData(List<int> data) async {
    if (!_isConnectionReady()) {
      _handleError('Tidak terhubung ke ESP32');
      return false;
    }

    try {
      await _targetCharacteristic!.write(data);
      return true;
    } catch (e) {
      _handleError('Gagal mengirim data: $e');
      return false;
    }
  }

  // === UTILITY METHODS ===

  /// Cek apakah koneksi siap untuk komunikasi
  bool _isConnectionReady() {
    return _isConnected &&
        _connectedDevice != null &&
        _targetCharacteristic != null;
  }

  /// Handle error dan notify listeners
  void _handleError(String error) {
    _errorController.add(error);
  }

  /// Get informasi detail perangkat yang terhubung
  Map<String, dynamic> getConnectedDeviceInfo() {
    if (_connectedDevice == null) return {};

    return {
      'name': _connectedDevice!.platformName,
      'id': _connectedDevice!.remoteId.toString(),
      'isConnected': _isConnected,
      'hasCharacteristic': _targetCharacteristic != null,
    };
  }

  /// Test koneksi dengan ping ke ESP32
  Future<bool> testConnection() async {
    if (!_isConnectionReady()) return false;

    try {
      // Coba baca status LED sebagai test
      final status = await readLEDStatus();
      return status != null;
    } catch (e) {
      return false;
    }
  }

  // === CLEANUP ===

  /// Cleanup semua resources
  ///
  /// Method ini harus dipanggil saat service tidak digunakan lagi
  /// untuk mencegah memory leaks dan resource conflicts
  void dispose() {
    // Stop scanning jika masih berjalan
    _stopCurrentScan();

    // Disconnect jika masih terhubung
    if (_isConnected) {
      disconnect();
    }

    // Cancel semua subscriptions
    _connectionSubscription?.cancel();
    _scanSubscription?.cancel();
    _notificationSubscription?.cancel();

    // Close semua stream controllers
    _devicesController.close();
    _connectionController.close();
    _scanningController.close();
    _ledStatusController.close();
    _errorController.close();
  }
}
