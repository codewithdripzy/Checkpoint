import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'ble_service.dart';
import '../models/contact_hash.dart';
import '../providers/nearby_provider.dart';

class CheckpointBackgroundService {
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    try {
      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onStart,
          autoStart: false,
          isForegroundMode: true,
          initialNotificationTitle: 'Checkpoint Radar',
          initialNotificationContent: 'Scanning for nearby contacts...',
          foregroundServiceTypes: [AndroidForegroundType.connectedDevice],
        ),
        iosConfiguration: IosConfiguration(
          autoStart: false,
          onForeground: onStart,
          onBackground: onIosBackground,
        ),
      );
    } catch (e, st) {
      debugPrint('Background service configure failed: $e');
      debugPrintStack(stackTrace: st);
      rethrow;
    }
  }

  static Future<void> startService() async {
    final service = FlutterBackgroundService();
    try {
      await service.startService();
    } catch (e, st) {
      debugPrint('Background service startService failed: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  static Future<void> stopService() async {
    final service = FlutterBackgroundService();
    try {
      service.invoke('stopService');
    } catch (e, st) {
      debugPrint('Background service stopService failed: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    try {
      DartPluginRegistrant.ensureInitialized();

      // Re-initialize Hive in background isolate
      await Hive.initFlutter();
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(ContactHashAdapter());
      }

      final bleService = BleService();
      final nearbyProviderForBackground = NearbyProvider();

      // Start BLE logic in background
      await bleService.startDiscovery(
        nearbyProviderForBackground,
        requestPermissions: false,
      );

      // Listener for when the radar finds someone while in background
      nearbyProviderForBackground.addListener(() {
        if (service is AndroidServiceInstance) {
          final count = nearbyProviderForBackground.discoveredContacts.length;
          if (count > 0) {
            service.setAsForegroundService();
            // We use the notification update to 'pop' a change to the user
            service.invoke('update', {
              "contacts": nearbyProviderForBackground.discoveredContacts
                  .map((c) => {
                        "hash": c.hash,
                        "name": c.name,
                        "lastSeen": c.lastSeen.toIso8601String(),
                        "latitude": c.latitude,
                        "longitude": c.longitude,
                      })
                  .toList(),
            });
          }
        }
      });

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

        // Broadcast discovered contacts back to the main UI
        service.invoke('update', {
          "contacts": nearbyProviderForBackground.discoveredContacts
                  .map((c) => {
                        "hash": c.hash,
                        "name": c.name,
                        "lastSeen": c.lastSeen.toIso8601String(),
                        "latitude": c.latitude,
                        "longitude": c.longitude,
                      })
              .toList(),
        });
      });
    } catch (e, st) {
      debugPrint('Background service start failed: $e');
      debugPrintStack(stackTrace: st);
      service.stopSelf();
    }
  }
}
