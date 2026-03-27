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
  // Permission helpers
  // ─────────────────────────────────────────────────────────────
  Future<bool> _hasBleRuntimePermissions() async {
    if (!Platform.isAndroid) return true;

    final scan = await Permission.bluetoothScan.status;
    final connect = await Permission.bluetoothConnect.status;
    final advertise = await Permission.bluetoothAdvertise.status;

    debugPrint('[BLE] scan=$scan  connect=$connect  advertise=$advertise');

    if (scan.isGranted && connect.isGranted && advertise.isGranted) return true;

    // Android 11 and below: location is the BLE gate
    final location = await Permission.location.status;
    debugPrint('[BLE] location=$location');
    return location.isGranted;
  }

  Future<bool> _requestBleRuntimePermissions() async {
    if (!Platform.isAndroid) return true;

    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.location,
    ].request();

    debugPrint('[BLE] Permission results after request: $statuses');
    return _hasBleRuntimePermissions();
  }

  // ─────────────────────────────────────────────────────────────
  // Bluetooth adapter readiness
  // ─────────────────────────────────────────────────────────────
  Future<bool> _ensureBluetoothReady() async {
    if (!Platform.isAndroid) return true;

    try {
      if (await FlutterBluePlus.isSupported == false) {
        debugPrint('[BLE] Bluetooth not supported on this device');
        return false;
      }
    } catch (e) {
      debugPrint('[BLE] isSupported check failed: $e');
      // Proceed anyway — some devices throw here but BT still works
    }

    try {
      final currentState = FlutterBluePlus.adapterStateNow;
      debugPrint('[BLE] Adapter state now: $currentState');

      // If already on, return immediately — don't wait for stream
      if (currentState == BluetoothAdapterState.on) return true;

      // Try to request the user turn BT on, but don't crash if it fails
      try {
        await FlutterBluePlus.turnOn(timeout: 10);
      } catch (e) {
        debugPrint('[BLE] turnOn error (non-fatal): $e');
      }

      // Wait up to 10 s for the adapter to come on
      final state = await FlutterBluePlus.adapterState
          .where((s) => s == BluetoothAdapterState.on)
          .first
          .timeout(const Duration(seconds: 10));

      debugPrint('[BLE] Adapter state after wait: $state');
      return state == BluetoothAdapterState.on;
    } catch (e) {
      debugPrint('[BLE] _ensureBluetoothReady error: $e');
      // Last resort: trust adapterStateNow directly
      final fallback = FlutterBluePlus.adapterStateNow;
      debugPrint('[BLE] Fallback state check: $fallback');
      return fallback == BluetoothAdapterState.on;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Start discovery
  // ─────────────────────────────────────────────────────────────
  Future<(BleStartResult, String?)> startDiscoveryWithResult(
    NearbyProvider provider,
  ) async {
    // ── 1. Permissions
    try {
      var granted = await _hasBleRuntimePermissions();
      debugPrint('[BLE] Permissions granted initially: $granted');

      if (!granted) {
        granted = await _requestBleRuntimePermissions();
        debugPrint('[BLE] Permissions granted after request: $granted');
      }

      if (!granted) {
        debugPrint('[BLE] Returning permissionDenied');
        return (BleStartResult.permissionDenied, null);
      }
    } catch (e) {
      debugPrint('[BLE] Permission check threw: $e');
      return (BleStartResult.permissionDenied, e.toString());
    }

    // ── 2. Bluetooth adapter
    try {
      final bluetoothReady = await _ensureBluetoothReady();
      if (!bluetoothReady) {
        debugPrint('[BLE] Adapter not ready → returning bluetoothOff');
        return (BleStartResult.bluetoothOff, null);
      }
    } catch (e) {
      debugPrint('[BLE] Adapter check threw: $e');
      return (BleStartResult.bluetoothOff, e.toString());
    }

    // ── 3. Advertising (non-fatal — many devices don't support peripheral mode)
    try {
      final advertiseData = AdvertiseData(
        serviceUuid: serviceUuid,
        localName: 'Checkpoint-Node',
      );
      await FlutterBlePeripheral().start(advertiseData: advertiseData);
      debugPrint('[BLE] Advertising started');
    } catch (e) {
      // Log but continue — the device may not support peripheral mode.
      // Scanning can still work to find other advertising nodes.
      debugPrint('[BLE] Advertising failed (non-fatal, continuing): $e');
    }

    // ── 4. Scan subscription
    try {
      _scanSubscription =
          FlutterBluePlus.onScanResults.listen((results) async {
        final expectedServiceGuid = Guid(serviceUuid);
        for (final r in results) {
          if (r.advertisementData.serviceUuids.contains(expectedServiceGuid)) {
            const foundHash = 'simulated_contact_hash_abc';
            final contact = await ContactService.findContactByHash(foundHash);
            if (contact != null) {
              provider.addFoundContact(contact);
            }
          }
        }
      });
    } catch (e) {
      debugPrint('[BLE] onScanResults listener setup failed: $e');
      stopDiscovery();
      return (BleStartResult.error, e.toString());
    }

    // ── 5. Start scan
    try {
      await FlutterBluePlus.startScan(
        withServices: [Guid(serviceUuid)],
        timeout: const Duration(seconds: 30),
      );
      debugPrint('[BLE] Scan started successfully');
      return (BleStartResult.success, null);
    } catch (e, st) {
      debugPrint('[BLE] startScan threw: $e');
      debugPrintStack(stackTrace: st);
      stopDiscovery();
      return (BleStartResult.error, e.toString());
    }
  }

  /// Legacy wrapper — returns true only on success.
  Future<bool> startDiscovery(
    NearbyProvider provider, {
    bool requestPermissions = true,
  }) async {
    final result = await startDiscoveryWithResult(provider);
    return result.$1 == BleStartResult.success;
  }

  void stopDiscovery() {
    _scanSubscription?.cancel();
    _scanSubscription = null;
    try {
      FlutterBluePlus.stopScan();
    } catch (_) {}
    try {
      FlutterBlePeripheral().stop();
    } catch (_) {}
  }
}

enum BleStartResult {
  success,
  permissionDenied,
  bluetoothOff,
  error,
}
