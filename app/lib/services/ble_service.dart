import 'dart:io';
import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:permission_handler/permission_handler.dart';
import 'contact_service.dart';
import '../providers/nearby_provider.dart';

class BleService {
  static const String serviceUuid = '0000C3E7-0000-1000-8000-00805F9B34FB';

  StreamSubscription<List<ScanResult>>? _scanSubscription;

  Future<bool> _hasBleRuntimePermissions() async {
    if (!Platform.isAndroid) return true;

    // Android 11 and below rely on location for BLE scan.
    final legacyLocation = await Permission.location.status;
    if (legacyLocation.isGranted) return true;

    // Android 12+ uses these dedicated Bluetooth runtime permissions.
    final scan = await Permission.bluetoothScan.status;
    final connect = await Permission.bluetoothConnect.status;
    final advertise = await Permission.bluetoothAdvertise.status;
    return scan.isGranted && connect.isGranted && advertise.isGranted;
  }

  Future<bool> _requestBleRuntimePermissions() async {
    if (!Platform.isAndroid) return true;

    await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
    ].request();

    return _hasBleRuntimePermissions();
  }

  Future<bool> startDiscovery(
    NearbyProvider provider, {
    bool requestPermissions = true,
  }) async {
    try {
      var granted = await _hasBleRuntimePermissions();
      if (!granted && requestPermissions) {
        granted = await _requestBleRuntimePermissions();
      }
      if (!granted) return false;

      // 1. Start Advertising (Peripheral Role)
      final advertiseData = AdvertiseData(
        serviceUuid: serviceUuid,
        localName: 'Checkpoint-Node',
      );

      await FlutterBlePeripheral().start(advertiseData: advertiseData);

      // 2. Start Scanning (Central Role)
      if (await FlutterBluePlus.isSupported == false) return false;

      // Listen to scan results
      _scanSubscription = FlutterBluePlus.onScanResults.listen((results) async {
        final expectedServiceGuid = Guid(serviceUuid);
        for (ScanResult r in results) {
          if (r.advertisementData.serviceUuids.contains(expectedServiceGuid)) {
            // Found a Checkpoint device!
            // In a real implementation, we'd extract the hash from the manufacturer data.
            final foundHash = 'simulated_contact_hash_abc';

            final contact = await ContactService.findContactByHash(foundHash);
            if (contact != null) {
              provider.addFoundContact(contact);
            }
          }
        }
      });

      // Start scanning
      await FlutterBluePlus.startScan(
        withServices: [Guid(serviceUuid)],
        timeout: const Duration(seconds: 15),
      );
      return true;
    } catch (_) {
      // Ignore BLE startup failures to avoid app-level crash on unsupported states/devices.
      stopDiscovery();
      return false;
    }
  }

  void stopDiscovery() {
    _scanSubscription?.cancel();
    FlutterBluePlus.stopScan();
    FlutterBlePeripheral().stop();
  }
}
