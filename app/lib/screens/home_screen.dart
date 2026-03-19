import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/nearby_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/radar_animation.dart';
import '../services/ble_service.dart';
import '../services/contact_service.dart';

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

  void _toggleScanning(BuildContext context) {
    final provider = context.read<NearbyProvider>();
    final isCurrentlyScanning = provider.isScanning;

    provider.setScanning(!isCurrentlyScanning);

    if (!isCurrentlyScanning) {
      _bleService.startDiscovery(provider);
    } else {
      _bleService.stopDiscovery();
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
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryNeon.withAlpha(5),
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
                    color: AppTheme.cardDark.withOpacity(0.8),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(40)),
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
                                            .withOpacity(0.1),
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
      floatingActionButton: FloatingActionButton.large(
        onPressed: () => _toggleScanning(context),
        backgroundColor: AppTheme.primaryNeon,
        child: Icon(
          context.watch<NearbyProvider>().isScanning ? Icons.stop : Icons.radar,
          color: Colors.black,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        height: 60,
        color: AppTheme.backgroundDark,
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
