import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'ble_service.dart';
import '../models/contact_hash.dart';
import '../providers/nearby_provider.dart';

class CheckpointBackgroundService {
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'checkpoint_background',
        initialNotificationTitle: 'Checkpoint Radar',
        initialNotificationContent: 'Scanning for nearby contacts...',
        foregroundServiceTypes: [AndroidForegroundType.connectedDevice],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    // Re-initialize Hive in background isolate
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ContactHashAdapter());
    }

    final bleService = BleService();
    final nearbyProviderForBackground = NearbyProvider();

    // Start BLE logic in background
    bleService.startDiscovery(nearbyProviderForBackground);

    service.on('stopService').listen((event) {
      bleService.stopDiscovery();
      service.stopSelf();
    });

    // Periodic update or keep-alive
    Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          service.setAsForegroundService();
          // Updated method in recent versions of flutter_background_service
          // or just rely on the initial config if this fails.
        }
      }
      
      // We could broadcast discovered contacts back to the main UI here
      service.invoke('update', {
        "count": nearbyProviderForBackground.discoveredContacts.length,
      });
    });
  }
}
