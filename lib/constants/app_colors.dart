import 'package:flutter/material.dart';

/// Konstanta warna untuk aplikasi ESP32 BLE Controller
///
/// Kelas ini menyediakan palet warna yang konsisten untuk seluruh aplikasi.
/// Menggunakan Brutalist Design color system dengan kontras tinggi dan warna bold.
class AppColors {
  // === CONSTRUCTOR ===
  AppColors._();

  // === PRIMARY COLORS ===
  /// Warna utama aplikasi - hitam pekat
  static const Color primaryDark = Color(0xFF000000);

  /// Warna utama medium - abu gelap
  static const Color primaryMedium = Color(0xFF121212);

  /// Warna utama terang - abu medium
  static const Color primaryLight = Color(0xFF333333);

  /// Warna utama sangat terang - abu terang
  static const Color primaryVeryLight = Color(0xFFE0E0E0);

  // === SEMANTIC COLORS ===
  /// Warna untuk status sukses/berhasil - hijau neon
  static const Color success = Color(0xFF39FF14);

  /// Warna untuk status error/gagal - merah brutal
  static const Color error = Color(0xFFFF1B1B);

  /// Warna untuk status warning/peringatan - kuning neon
  static const Color warning = Color(0xFFFFFF00);

  /// Warna untuk informasi - ungu brutal
  static const Color info = Color(0xFF9D00FF);

  // === NEUTRAL COLORS ===
  /// Warna putih murni
  static const Color white = Color(0xFFFFFFFF);

  /// Warna hitam murni
  static const Color black = Color(0xFF000000);

  /// Warna abu-abu gelap untuk teks utama
  static const Color textDark = Color(0xFF000000);

  /// Warna abu-abu medium untuk teks sekunder
  static const Color textMedium = Color(0xFF333333);

  /// Warna abu-abu terang untuk teks disabled
  static const Color textLight = Color(0xFF666666);

  /// Warna untuk elemen yang disabled
  static const Color disabled = Color(0xFF999999);

  // === BACKGROUND COLORS ===
  /// Warna background utama scaffold - putih stark
  static const Color scaffoldBackground = Color(0xFFFFFFFF);

  /// Warna background card/container - putih murni
  static const Color cardBackground = Color(0xFFFFFFFF);

  /// Warna background untuk section - abu sangat terang
  static const Color sectionBackground = Color(0xFFF0F0F0);

  // === ACCENT COLORS ===
  /// Warna aksen untuk highlight - magenta brutal
  static const Color accent = Color(0xFFFF00FF);

  /// Warna untuk divider/separator - hitam tegas
  static const Color divider = Color(0xFF000000);

  /// Warna untuk border - hitam bold
  static const Color border = Color(0xFF000000);

  // === BLUETOOTH SPECIFIC COLORS ===
  /// Warna untuk status Bluetooth connected
  static const Color bluetoothConnected = success;

  /// Warna untuk status Bluetooth connecting
  static const Color bluetoothConnecting = warning;

  /// Warna untuk status Bluetooth disconnected
  static const Color bluetoothDisconnected = error;

  /// Warna untuk LED ON - hijau neon
  static const Color ledOn = Color(0xFF00FF00);

  /// Warna untuk LED OFF - abu gelap
  static const Color ledOff = Color(0xFF333333);

  // === GREY COLORS ===
  static const Color grey100 = Color(0xFFE0E0E0);
  static const Color grey300 = Color(0xFF999999);
  static const Color grey600 = Color(0xFF333333);

  // === GRADIENT COLORS ===
  /// Gradient utama aplikasi - hitam ke abu
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [black, primaryLight],
  );

  /// Gradient untuk status sukses - hijau neon ke hijau gelap
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success, Color(0xFF00AA00)],
  );

  /// Gradient untuk status error - merah brutal ke merah gelap
  static const LinearGradient errorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [error, Color(0xFFAA0000)],
  );

  // === SHADOW COLORS ===
  /// Warna shadow untuk elevation - hitam tegas
  static Color shadowColor = black.withOpacity(0.8);

  /// Warna shadow untuk card - hitam bold
  static Color cardShadow = black.withOpacity(0.3);

  // === UTILITY METHODS ===

  /// Mendapatkan warna berdasarkan status koneksi
  static Color getConnectionStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'connected':
        return bluetoothConnected;
      case 'connecting':
        return bluetoothConnecting;
      case 'disconnected':
      default:
        return bluetoothDisconnected;
    }
  }

  /// Mendapatkan warna berdasarkan status LED
  static Color getLEDStatusColor(bool isOn) {
    return isOn ? ledOn : ledOff;
  }

  /// Mendapatkan warna dengan opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  /// Mendapatkan warna yang lebih gelap
  static Color darken(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  /// Mendapatkan warna yang lebih terang
  static Color lighten(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    final hslLight =
        hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return hslLight.toColor();
  }
}
