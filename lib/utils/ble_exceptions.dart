/// Base class untuk semua BLE-related exceptions
abstract class BLEException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const BLEException(this.message, {this.code, this.originalError});

  @override
  String toString() {
    if (code != null) {
      return 'BLEException [$code]: $message';
    }
    return 'BLEException: $message';
  }
}

/// Exception untuk masalah permissions
class BLEPermissionException extends BLEException {
  const BLEPermissionException(String message,
      {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

/// Exception untuk masalah koneksi
class BLEConnectionException extends BLEException {
  const BLEConnectionException(String message,
      {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

/// Exception untuk masalah scanning
class BLEScanException extends BLEException {
  const BLEScanException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

/// Exception untuk masalah komunikasi data
class BLEDataException extends BLEException {
  const BLEDataException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

/// Exception untuk timeout operations
class BLETimeoutException extends BLEException {
  final Duration timeout;

  const BLETimeoutException(String message, this.timeout,
      {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);

  @override
  String toString() {
    return 'BLETimeoutException: $message (timeout: ${timeout.inSeconds}s)';
  }
}

/// Exception untuk device tidak ditemukan
class BLEDeviceNotFoundException extends BLEException {
  final String deviceName;

  const BLEDeviceNotFoundException(this.deviceName,
      {String? code, dynamic originalError})
      : super('Device "$deviceName" not found',
            code: code, originalError: originalError);
}

/// Exception untuk service/characteristic tidak ditemukan
class BLEServiceNotFoundException extends BLEException {
  final String serviceUUID;
  final String? characteristicUUID;

  const BLEServiceNotFoundException(
    this.serviceUUID, {
    this.characteristicUUID,
    String? code,
    dynamic originalError,
  }) : super(
          characteristicUUID != null
              ? 'Characteristic "$characteristicUUID" not found in service "$serviceUUID"'
              : 'Service "$serviceUUID" not found',
          code: code,
          originalError: originalError,
        );
}
