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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final BleService _bleService = BleService();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
    _syncContacts();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _syncContacts() async {
    await ContactService.syncContacts();
  }

  Future<void> _toggleScanning(BuildContext context) async {
    final provider = context.read<NearbyProvider>();
    final messenger = ScaffoldMessenger.of(context); // capture before async gap
    final isCurrentlyScanning = provider.isScanning;

    if (!isCurrentlyScanning) {
      final resultRecord = await _bleService.startDiscoveryWithResult(provider);
      final result = resultRecord.$1;
      final errorMsg = resultRecord.$2;

      if (result == BleStartResult.success) {
        provider.setScanning(true);
        await CheckpointBackgroundService.startService();
      } else if (mounted) {
        final message = switch (result) {
          BleStartResult.permissionDenied =>
            'Bluetooth permissions are required. Please grant them in Settings.',
          BleStartResult.bluetoothOff =>
            'Please turn on Bluetooth and try again.',
          _ =>
            errorMsg != null ? 'Failed: $errorMsg' : 'Failed to start scanning. Check logcat for details.',
        };
        messenger.showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } else {
      _bleService.stopDiscovery();
      provider.setScanning(false);
      await CheckpointBackgroundService.stopService();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isScanning = context.watch<NearbyProvider>().isScanning;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.midnight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Miniature icon logo inline with title
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppTheme.royalBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.wifi_tethering,
                  color: AppTheme.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'CHECKPOINT',
              style: TextStyle(
                letterSpacing: 4,
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: AppTheme.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history_rounded,
                color: AppTheme.offWhite.withValues(alpha: 0.65), size: 22),
            tooltip: 'History',
            onPressed: () {},
          ),
          // IconButton(
          //   icon: Icon(Icons.settings_rounded,
          //       color: AppTheme.offWhite.withValues(alpha: 0.65), size: 22),
          //   tooltip: 'Settings',
          //   onPressed: () {},
          // ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _StatusBadge(isScanning: isScanning),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // ── Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.deepBlue,
                    AppTheme.midnight,
                    AppTheme.midnight,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),

            // ── Ambient glow behind radar
            Positioned(
              top: MediaQuery.of(context).size.height * 0.12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 340,
                  height: 340,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.royalBlue.withValues(alpha: 0.22),
                        AppTheme.amber.withValues(alpha: 0.06),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // ── Main content
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // ── Radar area
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: RadarAnimation(),
                    ),
                  ),

                  // ── Scan button
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: _ScanButton(
                      isScanning: isScanning,
                      onTap: () => _toggleScanning(context),
                    ),
                  ),

                  // ── Nearby panel
                  Expanded(
                    flex: 4,
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.surfaceBlue.withValues(alpha: 0.98),
                            AppTheme.deepBlue.withValues(alpha: 0.95),
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20)),
                        border: Border(
                          top: BorderSide(
                              color: AppTheme.borderBlue.withValues(alpha: 0.6),
                              width: 1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.royalBlue.withValues(alpha: 0.25),
                            blurRadius: 40,
                            offset: const Offset(0, -10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Drag handle
                          // Center(
                          //   child: Padding(
                          //     padding: const EdgeInsets.only(top: 12, bottom: 8),
                          //     child: Container(
                          //       width: 36,
                          //       height: 4,
                          //       decoration: BoxDecoration(
                          //         color: AppTheme.borderBlue,
                          //         borderRadius: BorderRadius.circular(2),
                          //       ),
                          //     ),
                          //   ),
                          // ),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'NEARBY CONTACTS',
                                  style: TextStyle(
                                    color: AppTheme.amber,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2.5,
                                  ),
                                ),
                                Consumer<NearbyProvider>(
                                  builder: (_, p, __) => Text(
                                    '${p.discoveredContacts.length} found',
                                    style: TextStyle(
                                      color: AppTheme.offWhite
                                          .withValues(alpha: 0.5),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          Expanded(
                            child: Consumer<NearbyProvider>(
                              builder: (context, provider, child) {
                                if (provider.discoveredContacts.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isScanning
                                              ? Icons.sensors
                                              : Icons.sensors_off,
                                          color: AppTheme.borderBlue,
                                          size: 40,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          isScanning
                                              ? 'Scanning for connections...'
                                              : 'Radar offline.\nStart scan to detect contacts.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: AppTheme.offWhite
                                                .withValues(alpha: 0.45),
                                            fontSize: 14,
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  itemCount: provider.discoveredContacts.length,
                                  itemBuilder: (context, index) {
                                    final contact =
                                        provider.discoveredContacts[index];
                                    return _ContactTile(contact: contact);
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
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status badge (top-right)
class _StatusBadge extends StatelessWidget {
  final bool isScanning;
  const _StatusBadge({required this.isScanning});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isScanning
            ? AppTheme.amber.withValues(alpha: 0.15)
            : AppTheme.borderBlue.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isScanning
              ? AppTheme.amber.withValues(alpha: 0.5)
              : AppTheme.borderBlue,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isScanning ? AppTheme.amber : AppTheme.borderBlue,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isScanning ? 'LIVE' : 'IDLE',
            style: TextStyle(
              color: isScanning ? AppTheme.amber : AppTheme.offWhite,
              fontSize: 7.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Centered scan/stop button
class _ScanButton extends StatelessWidget {
  final bool isScanning;
  final VoidCallback onTap;
  const _ScanButton({required this.isScanning, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutBack,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        decoration: BoxDecoration(
          gradient: isScanning
              ? LinearGradient(
                  colors: [
                    AppTheme.amber,
                    AppTheme.amberLight,
                  ],
                )
              : LinearGradient(
                  colors: [
                    AppTheme.royalBlue,
                    AppTheme.deepBlue,
                  ],
                ),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: isScanning
                  ? AppTheme.amber.withValues(alpha: 0.40)
                  : AppTheme.royalBlue.withValues(alpha: 0.40),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isScanning ? Icons.stop_rounded : Icons.radar_rounded,
              color: isScanning ? AppTheme.midnight : AppTheme.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isScanning ? 'Stop Radar' : 'Start Radar',
              style: TextStyle(
                color: isScanning ? AppTheme.midnight : AppTheme.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Contact tile card
class _ContactTile extends StatelessWidget {
  final dynamic contact;
  const _ContactTile({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.royalBlue.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.borderBlue.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppTheme.royalBlue, AppTheme.deepBlue],
              ),
              border: Border.all(
                  color: AppTheme.amber.withValues(alpha: 0.6), width: 1.5),
            ),
            child: Center(
              child: Text(
                contact.name[0].toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Passed just now',
                  style: TextStyle(
                    color: AppTheme.offWhite.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.royalBlue.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_forward_ios,
                size: 12, color: AppTheme.offWhite),
          ),
        ],
      ),
    );
  }
}
