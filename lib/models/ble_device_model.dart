import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../constants/ble_constants.dart';

/// Model untuk merepresentasikan perangkat BLE
///
/// Kelas ini membungkus BluetoothDevice dari flutter_blue_plus
/// dan menyediakan interface yang lebih user-friendly untuk UI
class BLEDeviceModel {
  /// Instance BluetoothDevice asli dari flutter_blue_plus
  final BluetoothDevice device;

  /// Nama perangkat yang ditampilkan ke user
  final String name;

  /// MAC address atau identifier unik perangkat
  final String id;

  /// Signal strength (RSSI) saat ditemukan
  final int? rssi;

  /// Constructor utama
  const BLEDeviceModel({
    required this.device,
    required this.name,
    required this.id,
    this.rssi,
  });

  /// Factory constructor untuk membuat BLEDeviceModel dari BluetoothDevice
  ///
  /// [device] - BluetoothDevice dari flutter_blue_plus
  /// [rssi] - Signal strength (opsional)
  ///
  /// Method ini akan:
  /// 1. Extract nama perangkat (fallback ke "Unknown Device")
  /// 2. Extract ID/MAC address
  /// 3. Create instance BLEDeviceModel
  factory BLEDeviceModel.fromBluetoothDevice(
    BluetoothDevice device, {
    int? rssi,
  }) {
    return BLEDeviceModel(
      device: device,
      name: _extractDeviceName(device),
      id: device.remoteId.toString(),
      rssi: rssi,
    );
  }

  /// Extract nama perangkat dengan fallback
  static String _extractDeviceName(BluetoothDevice device) {
    // Coba ambil nama dari platformName
    if (device.platformName.isNotEmpty) {
      return device.platformName;
    }

    // Fallback default ke "Unknown Device" jika nama kosong
    return "Unknown Device";
  }

  /// Apakah perangkat ini adalah ESP32 target
  bool get isTargetESP32 => name.contains(BLEConstants.targetDeviceName);

  /// String representasi untuk debugging
  @override
  String toString() {
    return 'BLEDeviceModel(name: $name, id: $id, rssi: $rssi)';
  }

  /// Equality comparison berdasarkan device ID
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BLEDeviceModel && other.id == id;
  }

  /// Hash code berdasarkan device ID
  @override
  int get hashCode => id.hashCode;
}

/// Enum untuk status koneksi BLE
///
/// Merepresentasikan berbagai state dalam proses koneksi BLE
enum BLEConnectionStatus {
  /// Tidak terhubung ke perangkat manapun
  disconnected,

  /// Sedang dalam proses menghubungkan
  connecting,

  /// Berhasil terhubung ke perangkat
  connected,
}

/// State class untuk mengelola status koneksi BLE
///
/// Menggunakan pattern sealed class untuk type safety
/// dan memastikan semua kemungkinan state ter-handle
class BLEConnectionState {
  /// Status koneksi saat ini
  final BLEConnectionStatus status;

  /// Perangkat yang terkait dengan state ini (jika ada)
  final BLEDeviceModel? device;

  /// Pesan tambahan (untuk error atau info)
  final String? message;

  const BLEConnectionState._({
    required this.status,
    this.device,
    this.message,
  });

  /// Factory untuk state disconnected
  factory BLEConnectionState.disconnected({String? message}) {
    return BLEConnectionState._(
      status: BLEConnectionStatus.disconnected,
      message: message,
    );
  }

  /// Factory untuk state connecting
  factory BLEConnectionState.connecting(BLEDeviceModel device) {
    return BLEConnectionState._(
      status: BLEConnectionStatus.connecting,
      device: device,
    );
  }

  /// Factory untuk state connected
  factory BLEConnectionState.connected(BLEDeviceModel device) {
    return BLEConnectionState._(
      status: BLEConnectionStatus.connected,
      device: device,
    );
  }

  /// Apakah sedang dalam proses koneksi
  bool get isConnecting => status == BLEConnectionStatus.connecting;

  /// Apakah sudah terhubung
  bool get isConnected => status == BLEConnectionStatus.connected;

  /// Apakah tidak terhubung
  bool get isDisconnected => status == BLEConnectionStatus.disconnected;

  /// String representasi untuk UI
  String get displayText {
    switch (status) {
      case BLEConnectionStatus.disconnected:
        return message ?? 'Tidak Terhubung';
      case BLEConnectionStatus.connecting:
        return 'Menghubungkan ke ${device?.name ?? 'perangkat'}...';
      case BLEConnectionStatus.connected:
        return 'Terhubung ke ${device?.name ?? 'perangkat'}';
    }
  }

  @override
  String toString() {
    return 'BLEConnectionState(status: $status, device: ${device?.name}, message: $message)';
  }
}
