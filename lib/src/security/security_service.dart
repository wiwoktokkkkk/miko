import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Hasil pemeriksaan integritas perangkat dan keamanan jaringan.
class SecurityStatus {
  const SecurityStatus._({required this.isSecure, required this.reason});

  const SecurityStatus.secure() : this._(isSecure: true, reason: 'secure');

  const SecurityStatus.blocked(String reason)
    : this._(isSecure: false, reason: reason);

  final bool isSecure;
  final String reason;

  String get title => switch (reason) {
    'root' => 'Perangkat root terdeteksi',
    'vpn' => 'VPN atau perekam jaringan terdeteksi',
    'proxy' => 'Proxy jaringan terdeteksi',
    'analyzer' => 'Aplikasi perekam trafik terdeteksi',
    'instrumentation' => 'Modifikasi proses terdeteksi',
    'debugger' => 'Debugger terdeteksi',
    'emulator' => 'Lingkungan virtual terdeteksi',
    'signature' => 'Integritas aplikasi tidak valid',
    _ => 'Pemeriksaan keamanan gagal',
  };

  String get message => switch (reason) {
    'root' =>
      'Miko tidak dapat digunakan pada perangkat yang di-root. Hapus root, Magisk, KernelSU, APatch, Xposed, atau modul sejenis lalu mulai ulang perangkat.',
    'vpn' =>
      'Mode keamanan ketat sedang aktif. Matikan semua VPN, HTTP Canary, AdGuard, Blokada, firewall lokal, atau aplikasi perekam jaringan lalu periksa lagi.',
    'proxy' =>
      'Hapus proxy HTTP/HTTPS dari pengaturan Wi-Fi atau jaringan, lalu periksa kembali.',
    'analyzer' =>
      'Hapus atau nonaktifkan HTTP Canary dan aplikasi perekam trafik lain sebelum menggunakan Miko.',
    'instrumentation' =>
      'Frida, Xposed, Substrate, atau alat modifikasi proses terdeteksi. Miko dihentikan untuk melindungi koneksi.',
    'debugger' =>
      'Miko tidak dapat berjalan ketika debugger atau tracer terhubung.',
    'emulator' =>
      'Build release Miko hanya dapat digunakan pada perangkat Android fisik.',
    'signature' =>
      'APK telah dimodifikasi atau ditandatangani ulang. Pasang APK resmi dari GitHub Release Miko.',
    _ =>
      'Komponen keamanan Android tidak dapat diverifikasi. Tutup lalu buka kembali aplikasi.',
  };

  @override
  bool operator ==(Object other) =>
      other is SecurityStatus &&
      other.isSecure == isSecure &&
      other.reason == reason;

  @override
  int get hashCode => Object.hash(isSecure, reason);
}

class SecurityException implements Exception {
  const SecurityException(this.status);

  final SecurityStatus status;

  @override
  String toString() => status.title;
}

/// Penghubung pemeriksaan keamanan Dart dengan implementasi native Android.
class SecurityService extends ChangeNotifier {
  SecurityService._();

  static final SecurityService instance = SecurityService._();
  static const MethodChannel _channel = MethodChannel(
    'com.miko.pochq/security',
  );

  SecurityStatus _status = const SecurityStatus.secure();
  SecurityStatus get status => _status;

  DateTime? _lastCheck;
  Future<SecurityStatus>? _inFlight;

  /// Memeriksa ulang root, signature, debugger, VPN, dan proxy.
  Future<SecurityStatus> refresh({bool force = true}) async {
    // Proteksi native saat ini ditujukan untuk APK Android. Test Flutter di
    // Linux dan target lain tetap dapat berjalan tanpa MethodChannel Android.
    if (kIsWeb || !Platform.isAndroid) {
      return _update(const SecurityStatus.secure());
    }

    final now = DateTime.now();
    if (!force &&
        _lastCheck != null &&
        now.difference(_lastCheck!) < const Duration(seconds: 2)) {
      return _status;
    }

    final pending = _inFlight;
    if (pending != null) return pending;

    final future = _checkNative();
    _inFlight = future;
    try {
      return await future;
    } finally {
      if (identical(_inFlight, future)) _inFlight = null;
    }
  }

  Future<SecurityStatus> _checkNative() async {
    SecurityStatus next;
    try {
      final result = await _channel.invokeMapMethod<String, Object?>(
        'checkSecurity',
      );
      final secure = result?['secure'] == true;
      final reason = result?['reason'] as String? ?? 'unavailable';
      next = secure
          ? const SecurityStatus.secure()
          : SecurityStatus.blocked(reason);
    } on PlatformException {
      next = const SecurityStatus.blocked('unavailable');
    } on MissingPluginException {
      next = const SecurityStatus.blocked('unavailable');
    } catch (_) {
      next = const SecurityStatus.blocked('unavailable');
    }
    _lastCheck = DateTime.now();
    return _update(next);
  }

  SecurityStatus _update(SecurityStatus next) {
    if (_status != next) {
      _status = next;
      notifyListeners();
    }
    return _status;
  }

  /// Dipanggil sebelum setiap request agar trafik tidak dimulai ketika kondisi
  /// keamanan berubah setelah aplikasi dibuka.
  Future<void> ensureNetworkAllowed() async {
    final current = await refresh(force: false);
    if (!current.isSecure) throw SecurityException(current);
  }
}
