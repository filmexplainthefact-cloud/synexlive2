import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Initialize primary Firebase (dgsell - Auth + Streaming)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize secondary Firebase (k-upl-6a0db - Gaming)
  try {
    await Firebase.initializeApp(
      name: 'gaming',
      options: GamingFirebaseOptions.android,
    );
  } catch (e) {
    debugPrint('Gaming Firebase init: $e');
  }

  await NotificationService.initialize();
  runApp(const SynexApp());
}

class SynexApp extends StatelessWidget {
  const SynexApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthService())],
      child: MaterialApp(
        title: 'Synex',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
