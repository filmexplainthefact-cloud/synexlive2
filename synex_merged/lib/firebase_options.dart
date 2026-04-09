// Synex Live Firebase (Auth + Streaming)
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return android;
      case TargetPlatform.iOS: return ios;
      default: throw UnsupportedError('Unsupported platform');
    }
  }
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDjN72zb90c8GzasTiFx-wZHKk_XbL2XPw',
    appId: '1:93914740482:android:d41f8492e8db7f071e741b',
    messagingSenderId: '93914740482',
    projectId: 'dgsell',
    storageBucket: 'dgsell.firebasestorage.app',
  );
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDjN72zb90c8GzasTiFx-wZHKk_XbL2XPw',
    appId: '1:93914740482:android:d41f8492e8db7f071e741b',
    messagingSenderId: '93914740482',
    projectId: 'dgsell',
    storageBucket: 'dgsell.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDjN72zb90c8GzasTiFx-wZHKk_XbL2XPw',
    appId: '1:93914740482:android:d41f8492e8db7f071e741b',
    messagingSenderId: '93914740482',
    projectId: 'dgsell',
    storageBucket: 'dgsell.firebasestorage.app',
    iosBundleId: 'com.synex.synexLive',
  );
}

// Synex Gaming Firebase (Tournaments + Store + Spin)
class GamingFirebaseOptions {
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA_zA-siOL72nHKCCMW9zk891HDWkbeOgs',
    appId: '1:1024864441721:android:gaming',
    messagingSenderId: '1024864441721',
    projectId: 'k-upl-6a0db',
    storageBucket: 'k-upl-6a0db.firebasestorage.app',
    databaseURL: 'https://k-upl-6a0db-default-rtdb.firebaseio.com',
  );
}
