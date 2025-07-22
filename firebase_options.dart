// from flutterfire cli.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Holds default Firebase options for your app.
///
/// Usage example:
/// import 'firebase_options.dart';
/// await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
class DefaultFirebaseOptions {
  // Returns the right FirebaseOptions for the current platform
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'No Firebase config for Linux. Run FlutterFire CLI to set it up.',
        );
      default:
        throw UnsupportedError(
          'This platform is not supported by DefaultFirebaseOptions.',
        );
    }
  }

  // Web config
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA2JDUBAyVUMrmpa33egRKxw8fDNgjeUxw',
    appId: '1:268585278631:web:8fb0421287ba5eb8f54f82',
    messagingSenderId: '268585278631',
    projectId: 'bank-samp',
    authDomain: 'bank-samp.firebaseapp.com',
    storageBucket: 'bank-samp.firebasestorage.app',
    measurementId: 'G-914B0BS77S',
  );

  // Android config
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDM7LnR0aGfnyM1U5kmCTZQsRQvrSNVS_s',
    appId: '1:268585278631:android:708ac2357727bb4ef54f82',
    messagingSenderId: '268585278631',
    projectId: 'bank-samp',
    storageBucket: 'bank-samp.firebasestorage.app',
  );

  // iOS config
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBql-CWFG82CNAUSlQ7-y2q_LZO4D5_TNE',
    appId: '1:268585278631:ios:0143e19907c45712f54f82',
    messagingSenderId: '268585278631',
    projectId: 'bank-samp',
    storageBucket: 'bank-samp.firebasestorage.app',
    iosClientId: '268585278631-bso21sl451nkk37t9qbu2rstql00brk5.apps.googleusercontent.com',
    iosBundleId: 'com.example.flutterApplication1',
  );

  // macOS config
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBql-CWFG82CNAUSlQ7-y2q_LZO4D5_TNE',
    appId: '1:268585278631:ios:0143e19907c45712f54f82',
    messagingSenderId: '268585278631',
    projectId: 'bank-samp',
    storageBucket: 'bank-samp.firebasestorage.app',
    iosClientId: '268585278631-bso21sl451nkk37t9qbu2rstql00brk5.apps.googleusercontent.com',
    iosBundleId: 'com.example.flutterApplication1',
  );

  // Windows config
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA2JDUBAyVUMrmpa33egRKxw8fDNgjeUxw',
    appId: '1:268585278631:web:1e5563dddc62d2c3f54f82',
    messagingSenderId: '268585278631',
    projectId: 'bank-samp',
    authDomain: 'bank-samp.firebaseapp.com',
    storageBucket: 'bank-samp.firebasestorage.app',
    measurementId: 'G-Z388VYG714',
  );
}
