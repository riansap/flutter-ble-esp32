import 'dart:io';
import 'package:app_settings/app_settings.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service untuk mengelola permissions dan setup Bluetooth
///
/// Service ini bertanggung jawab untuk:
/// - Meminta dan mengelola permissions yang diperlukan untuk BLE
/// - Mengaktifkan Bluetooth jika belum aktif
/// - Menyediakan status permissions dan Bluetooth
/// - Handle platform-specific requirements (Android/iOS)
class BluetoothPermissionService {
  // === PERMISSION CHECKING METHODS ===

  /// Cek apakah semua permissions yang diperlukan sudah diberikan
  ///
  /// Returns: true jika semua permissions sudah granted
  ///
  /// Permissions yang dicek:
  /// - Android: BLUETOOTH_SCAN, BLUETOOTH_CONNECT, ACCESS_FINE_LOCATION
  /// - iOS: Bluetooth permissions (handled automatically by system)
  Future<bool> checkAllPermissions() async {
    if (Platform.isAndroid) {
      return await _checkAndroidPermissions();
    } else if (Platform.isIOS) {
      return await _checkiOSPermissions();
    }
    return true;
  }

  /// Cek permissions khusus Android
  Future<bool> _checkAndroidPermissions() async {
    if (await _isAndroid12OrHigher()) {
      final bluetoothScan = await Permission.bluetoothScan.status;
      final bluetoothConnect = await Permission.bluetoothConnect.status;
      final bluetoothAdvertise = await Permission.bluetoothAdvertise.status;

      return bluetoothScan.isGranted &&
          bluetoothConnect.isGranted &&
          bluetoothAdvertise.isGranted;
    } else {
      final bluetooth = await Permission.bluetooth.status;
      final location = await Permission.locationWhenInUse.status;

      return bluetooth.isGranted && location.isGranted;
    }
  }

  /// Cek permissions khusus iOS
  Future<bool> _checkiOSPermissions() async {
    return await isBluetoothSupported();
  }

  /// Cek apakah device mendukung Bluetooth
  Future<bool> isBluetoothSupported() async {
    try {
      return await FlutterBluePlus.isSupported;
    } catch (e) {
      return false;
    }
  }

  /// Cek apakah Bluetooth sedang aktif
  Future<bool> isBluetoothEnabled() async {
    try {
      final adapterState = await FlutterBluePlus.adapterState.first;
      return adapterState == BluetoothAdapterState.on;
    } catch (e) {
      return false;
    }
  }

  // === PERMISSION REQUEST METHODS ===

  /// Meminta semua permissions yang diperlukan
  ///
  /// Returns: true jika semua permissions diberikan
  ///
  /// Method ini akan:
  /// 1. Cek platform (Android/iOS)
  /// 2. Request permissions yang sesuai
  /// 3. Handle permission denied scenarios
  /// 4. Provide user guidance jika diperlukan
  Future<bool> requestAllPermissions() async {
    if (Platform.isAndroid) {
      return await _requestAndroidPermissions();
    } else if (Platform.isIOS) {
      return await _requestiOSPermissions();
    }
    return true;
  }

  /// Request permissions khusus Android
  Future<bool> _requestAndroidPermissions() async {
    try {
      if (await _isAndroid12OrHigher()) {
        final permissions = [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.bluetoothAdvertise,
        ];

        final statuses = await permissions.request();
        return statuses.values.every((status) => status.isGranted);
      } else {
        final permissions = [
          Permission.bluetooth,
          Permission.locationWhenInUse,
        ];

        final statuses = await permissions.request();
        return statuses.values.every((status) => status.isGranted);
      }
    } catch (e) {
      return false;
    }
  }

  /// Request permissions khusus iOS
  Future<bool> _requestiOSPermissions() async {
    return await isBluetoothSupported();
  }

  /// Cek apakah Android versi 12 atau lebih tinggi
  Future<bool> _isAndroid12OrHigher() async {
    if (!Platform.isAndroid) return false;
    return true; // Simplified for now
  }

  // === BLUETOOTH ACTIVATION METHODS ===

  /// Meminta user untuk mengaktifkan Bluetooth
  ///
  /// Returns: true jika Bluetooth berhasil diaktifkan
  ///
  /// Method ini akan:
  /// 1. Cek status Bluetooth saat ini
  /// 2. Request aktivasi jika belum aktif
  /// 3. Wait sampai Bluetooth aktif atau timeout
  /// 4. Return status akhir
  Future<bool> requestBluetoothEnable() async {
    try {
      if (await isBluetoothEnabled()) {
        return true;
      }

      await FlutterBluePlus.turnOn();
      return await _waitForBluetoothEnabled();
    } catch (e) {
      return false;
    }
  }

  Future<void> openBluetoothSettings() async {
    AppSettings();
  }

  /// Wait sampai Bluetooth aktif dengan timeout
  Future<bool> _waitForBluetoothEnabled() async {
    const timeout = Duration(seconds: 10);
    const checkInterval = Duration(milliseconds: 500);

    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < timeout) {
      if (await isBluetoothEnabled()) {
        return true;
      }
      await Future.delayed(checkInterval);
    }

    return false;
  }

  // === MAIN SETUP METHOD ===

  /// Setup lengkap Bluetooth: izin + aktivasi
  ///
  /// Ini adalah method utama yang harus dipanggil sebelum menggunakan BLE.
  /// Akan meminta izin terlebih dahulu, kemudian mengaktifkan Bluetooth.
  ///
  /// Returns: true jika setup berhasil, false jika gagal
  ///
  /// Proses setup:
  /// 1. Cek dukungan Bluetooth pada device
  /// 2. Cek dan request permissions yang diperlukan
  /// 3. Cek dan request aktivasi Bluetooth
  /// 4. Verify setup berhasil
  Future<bool> setupBluetooth() async {
    try {
      if (!await isBluetoothSupported()) {
        return false;
      }

      final hasPermissions = await checkAllPermissions();
      if (!hasPermissions) {
        final permissionsGranted = await requestAllPermissions();
        if (!permissionsGranted) {
          return false;
        }
      }

      if (!await isBluetoothEnabled()) {
        final bluetoothEnabled = await requestBluetoothEnable();
        if (!bluetoothEnabled) {
          return false;
        }
      }

      return await _verifyBluetoothSetup();
    } catch (e) {
      return false;
    }
  }

  /// Verify bahwa setup Bluetooth berhasil
  Future<bool> _verifyBluetoothSetup() async {
    final supported = await isBluetoothSupported();
    final enabled = await isBluetoothEnabled();
    final hasPermissions = await checkAllPermissions();

    return supported && enabled && hasPermissions;
  }

  // === STATUS METHODS ===

  /// Get status lengkap Bluetooth dan permissions
  ///
  /// Returns: Map dengan informasi detail status
  Future<Map<String, dynamic>> getBluetoothStatus() async {
    return {
      'supported': await isBluetoothSupported(),
      'enabled': await isBluetoothEnabled(),
      'hasPermissions': await checkAllPermissions(),
      'platform': Platform.operatingSystem,
      'isAndroid12Plus': Platform.isAndroid && await _isAndroid12OrHigher(),
    };
  }

  /// Get daftar permissions yang diperlukan untuk platform saat ini
  List<String> getRequiredPermissions() {
    if (Platform.isAndroid) {
      return [
        'Bluetooth Scan',
        'Bluetooth Connect',
        'Bluetooth Advertise',
        'Location (untuk Android < 12)',
      ];
    } else if (Platform.isIOS) {
      return [
        'Bluetooth (handled by system)',
      ];
    } else {
      return ['No permissions required'];
    }
  }

  /// Cek apakah ada permissions yang permanently denied
  Future<bool> hasPermissionsPermanentlyDenied() async {
    if (!Platform.isAndroid) return false;

    try {
      if (await _isAndroid12OrHigher()) {
        final bluetoothScan = await Permission.bluetoothScan.status;
        final bluetoothConnect = await Permission.bluetoothConnect.status;
        final bluetoothAdvertise = await Permission.bluetoothAdvertise.status;

        return bluetoothScan.isPermanentlyDenied ||
            bluetoothConnect.isPermanentlyDenied ||
            bluetoothAdvertise.isPermanentlyDenied;
      } else {
        final bluetooth = await Permission.bluetooth.status;
        final location = await Permission.locationWhenInUse.status;

        return bluetooth.isPermanentlyDenied || location.isPermanentlyDenied;
      }
    } catch (e) {
      return false;
    }
  }

  // === UTILITY METHODS ===

  /// Buka settings aplikasi untuk mengatur permissions manual
  Future<void> openAppSettings() async {
    await openAppSettings();
  }

  /// Get pesan user-friendly untuk status permissions
  String getPermissionStatusMessage(bool hasPermissions) {
    if (hasPermissions) {
      return 'Semua permissions telah diberikan';
    } else {
      return 'Beberapa permissions diperlukan untuk menggunakan Bluetooth';
    }
  }

  /// Get pesan user-friendly untuk status Bluetooth
  String getBluetoothStatusMessage(bool isEnabled) {
    if (isEnabled) {
      return 'Bluetooth aktif dan siap digunakan';
    } else {
      return 'Bluetooth perlu diaktifkan untuk melanjutkan';
    }
  }

  /// Stream untuk monitoring status Bluetooth
  Stream<bool> get bluetoothStateStream {
    return FlutterBluePlus.adapterState
        .map((state) => state == BluetoothAdapterState.on);
  }
}
