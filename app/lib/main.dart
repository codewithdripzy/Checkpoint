import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/contact_hash.dart';
import 'providers/nearby_provider.dart';
import 'screens/home_screen.dart';
import 'services/background_service.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Background Service
  try {
    await CheckpointBackgroundService.initializeService();
  } catch (e, st) {
    debugPrint('Background service initialization failed: $e');
    debugPrintStack(stackTrace: st);
  }

  // Initialize Hive
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(ContactHashAdapter());
  }

  // Run the app with providers
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NearbyProvider()),
      ],
      child: const CheckpointApp(),
    ),
  );
}

class CheckpointApp extends StatelessWidget {
  const CheckpointApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Checkpoint',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme(context),
      home: const HomeScreen(),
    );
  }
}
