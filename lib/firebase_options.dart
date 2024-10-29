import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
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
        return web;
      case TargetPlatform.windows:
        return web;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD6JO1Kcuaj_9WyJtkKu5EXDAC5a1vlNCc',
    appId: '1:624708243551:web:031699491d1c9a288ecbea',
    messagingSenderId: '624708243551',
    projectId: 'restaurantapp-456c0',
    authDomain: 'restaurantapp-456c0.firebaseapp.com',
    storageBucket: 'restaurantapp-456c0.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCKiDJpTl-fvf1CuG8qdkMzdZf3unZ18pc',
    appId: '1:624708243551:android:031699491d1c9a288ecbea',
    messagingSenderId: '624708243551',
    projectId: 'restaurantapp-456c0',
    storageBucket: 'restaurantapp-456c0.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD6JO1Kcuaj_9WyJtkKu5EXDAC5a1vlNCc',
    appId: '1:624708243551:ios:031699491d1c9a288ecbea',
    messagingSenderId: '624708243551',
    projectId: 'restaurantapp-456c0',
    storageBucket: 'restaurantapp-456c0.appspot.com',
    iosClientId: 'com.Shardey.bitebook',
    iosBundleId: 'com.Shardey.bitebook',
  );
}
