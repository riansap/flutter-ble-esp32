/// Konstanta untuk konfigurasi BLE dalam aplikasi
class BLEConstants {
  // === CONSTRUCTOR ===
  BLEConstants._();

  // === DEVICE CONFIGURATION ===
  /// Nama perangkat ESP32 yang dicari
  static const String targetDeviceName = "ESP32 Audioteq Control";

  /// Alternatif nama perangkat (untuk fallback)
  static const List<String> alternativeDeviceNames = [
    "ESP32 Audioteq Control",
    "ESP32_Audioteq",
    "Audioteq_ESP32",
  ];

  // === SERVICE & CHARACTERISTIC UUIDs ===
  /// Service UUID untuk komunikasi dengan ESP32 (sesuaikan dengan UUID kode di kode Arduino/ESP32)
  static const String serviceUUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";

  /// Characteristic UUID untuk LED control (sesuaikan dengan UUID kode Arduino/ESP32)
  static const String ledCharacteristicUUID =
      "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  /// Characteristic UUID untuk sensor data (future use)
  // static const String sensorCharacteristicUUID =
  //     "11111111-2222-3333-4444-555555555555";

  // === TIMEOUT CONFIGURATIONS ===
  /// Timeout untuk operasi koneksi
  static const Duration connectionTimeout = Duration(seconds: 30);

  /// Timeout untuk operasi scanning
  static const Duration scanTimeout = Duration(seconds: 15);

  /// Timeout untuk operasi read/write
  static const Duration operationTimeout = Duration(seconds: 10);

  /// Interval untuk retry operations
  static const Duration retryInterval = Duration(seconds: 2);

  /// Maximum retry attempts
  static const int maxRetryAttempts = 3;

  // === COMMUNICATION PROTOCOL ===
  /// Command untuk menyalakan LED
  static const List<int> ledOnCommand = [1];

  /// Command untuk mematikan LED
  static const List<int> ledOffCommand = [0];

  /// Command untuk request status
  static const List<int> statusRequestCommand = [255];

  // === SCANNING CONFIGURATION ===
  /// Minimum RSSI untuk device yang diterima
  static const int minimumRSSI = -80;

  /// Interval untuk refresh scan results
  static const Duration scanRefreshInterval = Duration(seconds: 2);

  // === UI CONFIGURATION ===
  /// Durasi untuk menampilkan snackbar
  static const Duration snackbarDuration = Duration(seconds: 3);

  /// Durasi untuk loading indicators
  static const Duration loadingIndicatorDuration = Duration(milliseconds: 500);

  // === ERROR MESSAGES ===
  static const String errorBluetoothNotSupported =
      'Bluetooth tidak didukung pada perangkat ini';
  static const String errorBluetoothNotEnabled = 'Bluetooth tidak aktif';
  static const String errorPermissionDenied = 'Permission Bluetooth ditolak';
  static const String errorDeviceNotFound = 'Perangkat ESP32 tidak ditemukan';
  static const String errorConnectionFailed = 'Gagal terhubung ke perangkat';
  static const String errorServiceNotFound = 'Service BLE tidak ditemukan';
  static const String errorCharacteristicNotFound =
      'Characteristic BLE tidak ditemukan';
  static const String errorCommunicationFailed =
      'Gagal berkomunikasi dengan ESP32';

  // === SUCCESS MESSAGES ===
  static const String successBluetoothEnabled = 'Bluetooth berhasil diaktifkan';
  static const String successPermissionGranted =
      'Permission Bluetooth diberikan';
  static const String successDeviceConnected = 'Berhasil terhubung ke ESP32';
  static const String successLEDControlled = 'LED berhasil dikontrol';

  // === VALIDATION METHODS ===

  /// Validasi apakah nama perangkat adalah target ESP32
  static bool isTargetDevice(String deviceName) {
    return alternativeDeviceNames
        .any((name) => deviceName.toLowerCase().contains(name.toLowerCase()));
  }

  /// Validasi UUID format
  static bool isValidUUID(String uuid) {
    final uuidRegex = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    return uuidRegex.hasMatch(uuid);
  }

  /// Validasi RSSI value
  static bool isValidRSSI(int rssi) {
    return rssi >= -100 && rssi <= 0;
  }

  /// Mendapatkan pesan error yang lebih mudah dipahami user
  static String getUserFriendlyError(String technicalError) {
    if (technicalError.toLowerCase().contains('permission')) {
      return errorPermissionDenied;
    } else if (technicalError.toLowerCase().contains('bluetooth')) {
      return errorBluetoothNotEnabled;
    } else if (technicalError.toLowerCase().contains('connection')) {
      return errorConnectionFailed;
    } else if (technicalError.toLowerCase().contains('service')) {
      return errorServiceNotFound;
    } else if (technicalError.toLowerCase().contains('characteristic')) {
      return errorCharacteristicNotFound;
    } else {
      return errorCommunicationFailed;
    }
  }
}
