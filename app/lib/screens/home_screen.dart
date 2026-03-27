import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/nearby_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/radar_animation.dart';
import '../services/ble_service.dart';
import '../services/contact_service.dart';
import '../services/background_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BleService _bleService = BleService();

  @override
  void initState() {
    super.initState();
    _syncContacts();
  }

  Future<void> _syncContacts() async {
    await ContactService.syncContacts();
  }

  Future<void> _toggleScanning(BuildContext context) async {
    final provider = context.read<NearbyProvider>();
    final isCurrentlyScanning = provider.isScanning;

    if (!isCurrentlyScanning) {
      final started = await _bleService.startDiscovery(provider);
      provider.setScanning(started);
      if (started) {
        await CheckpointBackgroundService.startService();
      }
    } else {
      _bleService.stopDiscovery();
      provider.setScanning(false);
      await CheckpointBackgroundService.stopService();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'CHECKPOINT',
          style: TextStyle(
            letterSpacing: 4,
            fontWeight: FontWeight.w900,
            color: AppTheme.primaryNeon,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 500,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryNeon.withValues(alpha: 0.15),
                    AppTheme.secondaryNeon.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Column(
            children: [
              const SizedBox(height: 120),

              // Radar Area
              Expanded(
                flex: 3,
                child: Center(
                  child: RadarAnimation(),
                ),
              ),

              // Nearby List
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark.withValues(alpha: 0.95),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(40)),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryNeon.withValues(alpha: 0.10),
                        blurRadius: 30,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        'NEARBY CONTACTS',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Consumer<NearbyProvider>(
                          builder: (context, provider, child) {
                            if (provider.discoveredContacts.isEmpty) {
                              return Center(
                                child: Text(
                                  provider.isScanning
                                      ? 'Scanning for connections...'
                                      : 'Radar offline. Start scan to find contacts.',
                                  textAlign: TextAlign.center,
                                  style:
                                      TextStyle(color: AppTheme.textSecondary),
                                ),
                              );
                            }
                            return ListView.builder(
                              itemCount: provider.discoveredContacts.length,
                              itemBuilder: (context, index) {
                                final contact =
                                    provider.discoveredContacts[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Card(
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: AppTheme.primaryNeon
                                            .withValues(alpha: 0.1),
                                        child: Text(
                                          contact.name[0],
                                          style: TextStyle(
                                              color: AppTheme.primaryNeon),
                                        ),
                                      ),
                                      title: Text(
                                        contact.name,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(
                                        'Passed just now',
                                        style: TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 12),
                                      ),
                                      trailing: Icon(Icons.arrow_forward_ios,
                                          size: 14,
                                          color: AppTheme.textSecondary),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () async {
          final messenger = ScaffoldMessenger.of(context);
          final provider = context.read<NearbyProvider>();
          final wasScanning = provider.isScanning;
          await _toggleScanning(context);
          final isScanning = provider.isScanning;

          if (!wasScanning && !isScanning && mounted) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text(
                  'Unable to start radar. Ensure Bluetooth is ON and permissions are granted.',
                ),
              ),
            );
          }
        },
        backgroundColor: AppTheme.secondaryNeon,
        child: Icon(
          context.watch<NearbyProvider>().isScanning ? Icons.stop : Icons.radar,
          color: AppTheme.primaryNeon,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        height: 60,
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
                icon: Icon(Icons.history, color: AppTheme.textSecondary),
                onPressed: () {}),
            const SizedBox(width: 40),
            IconButton(
                icon: Icon(Icons.settings, color: AppTheme.textSecondary),
                onPressed: () {}),
          ],
        ),
      ),
    );
  }
}
