import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'contact_service.dart';
import '../models/contact_hash.dart';
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

    // ── 3. Advertising
    try {
      // Try to get current position for v2 map features
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 3),
        ).timeout(const Duration(seconds: 3));
      } catch (_) {}

      final myHash = await ContactService.getMyHash();
      Uint8List? payloadBytes;
      
      if (myHash != null) {
        final hashFull = hexToBytes(myHash);
        final builder = BytesBuilder();
        
        // Use 10 bytes for hash to save space for GPS
        builder.add(hashFull.sublist(0, 10));

        if (pos != null) {
          final bdata = ByteData(8);
          bdata.setFloat32(0, pos.latitude);
          bdata.setFloat32(4, pos.longitude);
          builder.add(bdata.buffer.asUint8List());
        }
        payloadBytes = builder.toBytes();
      }

      final advertiseData = AdvertiseData(
        serviceUuid: serviceUuid,
        localName: 'Checkpoint-Node',
        serviceData: payloadBytes, 
      );
      await FlutterBlePeripheral().start(advertiseData: advertiseData);
      debugPrint('[BLE] Advertising started (identity=${myHash != null}, gps=${pos != null})');
    } catch (e) {
      debugPrint('[BLE] Advertising failed: $e');
    }

    // ── 4. Scan subscription
    try {
      _scanSubscription =
          FlutterBluePlus.onScanResults.listen((results) async {
        final expectedGuid = Guid(serviceUuid);
        for (final r in results) {
          final bool isCheckpoint =
              r.advertisementData.serviceUuids.contains(expectedGuid) ||
              r.advertisementData.serviceData.containsKey(expectedGuid);

          if (isCheckpoint) {
            final String deviceId = r.device.remoteId.toString();
            String displayName = r.advertisementData.advName;

            // Try to resolve matching identity if hash is present
            final discoveredData = r.advertisementData.serviceData[expectedGuid];
            double? lat;
            double? lon;

            if (discoveredData != null && discoveredData.length >= 10) {
              final hashPart = Uint8List.fromList(discoveredData.sublist(0, 10));
              final String foundHashHex = bytesToHex(hashPart);
              
              // Extract Lat/Lon if present (starting at byte 10)
              if (discoveredData.length >= 18) {
                try {
                  final bdata = ByteData.sublistView(Uint8List.fromList(discoveredData), 10, 18);
                  lat = bdata.getFloat32(0);
                  lon = bdata.getFloat32(4);
                } catch (_) {}
              }

              // Search in local contact list
              final contact = await _resolveContact(foundHashHex);
              if (contact != null) {
                displayName = contact.name;
              }
            }
            if (displayName.isEmpty) {
              try {
                displayName = r.device.platformName;
              } catch (_) {}
            }
            if (displayName.isEmpty) displayName = 'Checkpoint User';

            provider.addFoundContact(ContactHash(
              hash: deviceId,
              name: displayName,
              lastSeen: DateTime.now(),
              latitude: lat,
              longitude: lon,
            ));
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
      // Pre-flight check: is GPS turned off system-wide?
      if (Platform.isAndroid) {
        final locEnabled = await Permission.location.serviceStatus.isEnabled;
        if (!locEnabled) {
          return (BleStartResult.locationOff, null);
        }
      }

      await FlutterBluePlus.startScan(
        timeout: null, // Continuous scanning
      );
      debugPrint('[BLE] Scan started successfully');
      return (BleStartResult.success, null);
    } catch (e, st) {
      debugPrint('[BLE] startScan threw: $e');
      debugPrintStack(stackTrace: st);
      stopDiscovery();
      
      String errorMsg = e.toString();
      // Catch platform exceptions related to location services being disabled
      if (errorMsg.toLowerCase().contains('location')) {
        return (BleStartResult.locationOff, null);
      }

      return (BleStartResult.error, errorMsg);
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

  // ─────────────────────────────────────────────────────────────
  // Identity Helpers
  // ─────────────────────────────────────────────────────────────

  Future<ContactHash?> _resolveContact(String incomingHash) async {
    // We try to match the incoming hash (potentially truncated)
    // against our local hashed_contacts box.
    try {
      final box = await ContactService.getHashedContactsBox();
      for (var key in box.keys) {
        if (key.toString().startsWith(incomingHash)) {
          return box.get(key);
        }
      }
    } catch (e) {
      debugPrint('[BLE] _resolveContact error: $e');
    }
    return null;
  }

  Uint8List hexToBytes(String hex) {
    return Uint8List.fromList(
        List.generate(hex.length ~/ 2, (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16)));
  }

  String bytesToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}

enum BleStartResult {
  success,
  permissionDenied,
  bluetoothOff,
  locationOff,
  error,
}
