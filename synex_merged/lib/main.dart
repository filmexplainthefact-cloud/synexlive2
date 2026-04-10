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

  // Init primary Firebase (dgsell)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Init Gaming Firebase (k-upl-6a0db)
  bool gamingInitialized = false;
  for (final app in Firebase.apps) {
    if (app.name == 'gaming') { gamingInitialized = true; break; }
  }
  if (!gamingInitialized) {
    try {
      await Firebase.initializeApp(
        name: 'gaming',
        options: const FirebaseOptions(
          apiKey: 'AIzaSyA_zA-siOL72nHKCCMW9zk891HDWkbeOgs',
          appId: '1:1024864441721:android:gaming_app_id',
          messagingSenderId: '1024864441721',
          projectId: 'k-upl-6a0db',
          storageBucket: 'k-upl-6a0db.firebasestorage.app',
          databaseURL: 'https://k-upl-6a0db-default-rtdb.firebaseio.com',
        ),
      );
      debugPrint('Gaming Firebase initialized');
    } catch (e) {
      debugPrint('Gaming Firebase init error: $e');
    }
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
