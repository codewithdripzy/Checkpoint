import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'contact_service.dart';
import '../providers/nearby_provider.dart';

class BleService {
  static const String serviceUuid = '0000C3E7-0000-1000-8000-00805F9B34FB';
  
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  Future<void> startDiscovery(NearbyProvider provider) async {
    // 1. Start Advertising (Peripheral Role)
    // In a real device, we'd broadcast the user's OWN hash here
    final userHash = 'user_unique_hash_123'; // This would be the user's phone hash
    
    final advertiseData = AdvertiseData(
      serviceUuid: serviceUuid,
      localName: 'Checkpoint-Node',
    );

    await FlutterBlePeripheral().start(advertiseData: advertiseData);

    // 2. Start Scanning (Central Role)
    if (await FlutterBluePlus.isSupported == false) return;

    // Listen to scan results
    _scanSubscription = FlutterBluePlus.onScanResults.listen((results) async {
      for (ScanResult r in results) {
        if (r.advertisementData.serviceUuids.contains(serviceUuid)) {
          // Found a Checkpoint device!
          // In a real implementation, we'd extract the hash from the manufacturer data
          // For now, we'll try to match a simulated hash
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
  }

  void stopDiscovery() {
    _scanSubscription?.cancel();
    FlutterBluePlus.stopScan();
    FlutterBlePeripheral().stop();
  }
}
