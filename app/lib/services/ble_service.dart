import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:permission_handler/permission_handler.dart';
import 'contact_service.dart';
import '../providers/nearby_provider.dart';

class BleService {
  static const String serviceUuid = '0000C3E7-0000-1000-8000-00805F9B34FB';

  StreamSubscription<List<ScanResult>>? _scanSubscription;

  // ─────────────────────────────────────────────────────────────
  // Permission check
  // On Android 12+ (SDK 31+) we use the dedicated BT permissions.
  // On Android 11 and below we need ACCESS_FINE_LOCATION.
  // ─────────────────────────────────────────────────────────────
  Future<bool> _hasBleRuntimePermissions() async {
    if (!Platform.isAndroid) return true;

    final androidVersion = await _androidSdkVersion();

    if (androidVersion >= 31) {
      // Android 12+: need BLUETOOTH_SCAN, BLUETOOTH_CONNECT, BLUETOOTH_ADVERTISE
      final scan = await Permission.bluetoothScan.status;
      final connect = await Permission.bluetoothConnect.status;
      final advertise = await Permission.bluetoothAdvertise.status;
      debugPrint(
          '[BLE] scan=$scan connect=$connect advertise=$advertise');
      return scan.isGranted && connect.isGranted && advertise.isGranted;
    } else {
      // Android 11 and below: need fine location
      final location = await Permission.location.status;
      debugPrint('[BLE] location=$location');
      return location.isGranted;
    }
  }

  Future<bool> _requestBleRuntimePermissions() async {
    if (!Platform.isAndroid) return true;

    final androidVersion = await _androidSdkVersion();

    if (androidVersion >= 31) {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
      ].request();

      debugPrint('[BLE] After request: $statuses');
    } else {
      final statuses = await [
        Permission.location,
      ].request();

      debugPrint('[BLE] After request (legacy): $statuses');
    }

    return _hasBleRuntimePermissions();
  }

  /// Returns the Android SDK version (e.g. 33 for Android 13).
  /// Falls back to 31 (Android 12) if unparseable, so modern permission
  /// paths are taken by default.
  Future<int> _androidSdkVersion() async {
    try {
      // Platform.operatingSystemVersion on Android looks like:
      // "Linux version 5.15... (Android 13 / API level 33)"
      // We extract the API level from the OS version string.
      final osVersion = Platform.operatingSystemVersion;
      final match = RegExp(r'API level (\d+)').firstMatch(osVersion);
      if (match != null) {
        return int.tryParse(match.group(1) ?? '') ?? 31;
      }
      // Alternative: version string can be just "13" on some builds
      final versionMatch =
          RegExp(r'Android (\d+)').firstMatch(osVersion);
      if (versionMatch != null) {
        // Map major Android version to rough SDK:
        // Android 12 → SDK 31, Android 13 → SDK 33, Android 14 → SDK 34
        final major = int.tryParse(versionMatch.group(1) ?? '') ?? 12;
        return major >= 12 ? 31 : 28;
      }
      return 31; // Safe default → use modern BT permissions
    } catch (_) {
      return 31;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Bluetooth adapter readiness
  // ─────────────────────────────────────────────────────────────
  Future<bool> _ensureBluetoothReady() async {
    if (!Platform.isAndroid) return true;

    if (await FlutterBluePlus.isSupported == false) {
      debugPrint('[BLE] Bluetooth not supported on this device');
      return false;
    }

    try {
      final currentState = FlutterBluePlus.adapterStateNow;
      debugPrint('[BLE] Current adapter state: $currentState');

      if (currentState != BluetoothAdapterState.on) {
        // Request user to turn BT on
        await FlutterBluePlus.turnOn(timeout: 20);
      }

      final state = await FlutterBluePlus.adapterState
          .where((s) => s == BluetoothAdapterState.on)
          .first
          .timeout(const Duration(seconds: 20));

      debugPrint('[BLE] Adapter state after wait: $state');
      return state == BluetoothAdapterState.on;
    } catch (e) {
      debugPrint('[BLE] _ensureBluetoothReady error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Start discovery — returns false with a reason on failure
  // ─────────────────────────────────────────────────────────────
  Future<BleStartResult> startDiscoveryWithResult(
    NearbyProvider provider,
  ) async {
    try {
      // 1. Check/request permissions
      var granted = await _hasBleRuntimePermissions();
      debugPrint('[BLE] Permissions granted initially: $granted');

      if (!granted) {
        granted = await _requestBleRuntimePermissions();
        debugPrint('[BLE] Permissions granted after request: $granted');
      }

      if (!granted) {
        return BleStartResult.permissionDenied;
      }

      // 2. Ensure BT adapter is on
      final bluetoothReady = await _ensureBluetoothReady();
      if (!bluetoothReady) {
        return BleStartResult.bluetoothOff;
      }

      // 3. Start advertising
      final advertiseData = AdvertiseData(
        serviceUuid: serviceUuid,
        localName: 'Checkpoint-Node',
      );
      await FlutterBlePeripheral().start(advertiseData: advertiseData);

      // 4. Listen to scan results
      _scanSubscription =
          FlutterBluePlus.onScanResults.listen((results) async {
        final expectedServiceGuid = Guid(serviceUuid);
        for (ScanResult r in results) {
          if (r.advertisementData.serviceUuids
              .contains(expectedServiceGuid)) {
            const foundHash = 'simulated_contact_hash_abc';
            final contact = await ContactService.findContactByHash(foundHash);
            if (contact != null) {
              provider.addFoundContact(contact);
            }
          }
        }
      });

      // 5. Start scanning
      await FlutterBluePlus.startScan(
        withServices: [Guid(serviceUuid)],
      );

      return BleStartResult.success;
    } catch (e, st) {
      debugPrint('[BLE] startDiscovery error: $e');
      debugPrintStack(stackTrace: st);
      stopDiscovery();
      return BleStartResult.error;
    }
  }

  /// Legacy wrapper kept for backward compatibility with existing callers.
  /// Returns true only on success.
  Future<bool> startDiscovery(
    NearbyProvider provider, {
    bool requestPermissions = true,
  }) async {
    final result = await startDiscoveryWithResult(provider);
    return result == BleStartResult.success;
  }

  void stopDiscovery() {
    _scanSubscription?.cancel();
    _scanSubscription = null;
    FlutterBluePlus.stopScan();
    FlutterBlePeripheral().stop();
  }
}

enum BleStartResult {
  success,
  permissionDenied,
  bluetoothOff,
  error,
}
