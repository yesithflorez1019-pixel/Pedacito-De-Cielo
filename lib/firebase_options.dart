
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

///  [FirebaseOptions] 

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
        return macos;
      case TargetPlatform.windows:
        return windows;
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
    apiKey: 'AIzaSyBf_--Jfwj3_xq_Woyh15h0XKTU0HeZr1M',
    appId: '1:1053420085133:web:889ac5c0f5fc9d1b59e7c4',
    messagingSenderId: '1053420085133',
    projectId: 'pedacito-de-cielo-e1867',
    authDomain: 'pedacito-de-cielo-e1867.firebaseapp.com',
    storageBucket: 'pedacito-de-cielo-e1867.firebasestorage.app',
    measurementId: 'G-9L57LPFJY7',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCC0ybfvR4yZI1naFloJEjTulMEr_h_t9E',
    appId: '1:1053420085133:android:773224644ca3971959e7c4',
    messagingSenderId: '1053420085133',
    projectId: 'pedacito-de-cielo-e1867',
    storageBucket: 'pedacito-de-cielo-e1867.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyABA-3SH_ED2MOirCKyF6iNG5yMsIYyjFQ',
    appId: '1:1053420085133:ios:e98bc8ec6b49039659e7c4',
    messagingSenderId: '1053420085133',
    projectId: 'pedacito-de-cielo-e1867',
    storageBucket: 'pedacito-de-cielo-e1867.firebasestorage.app',
    iosBundleId: 'com.example.postresApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyABA-3SH_ED2MOirCKyF6iNG5yMsIYyjFQ',
    appId: '1:1053420085133:ios:e98bc8ec6b49039659e7c4',
    messagingSenderId: '1053420085133',
    projectId: 'pedacito-de-cielo-e1867',
    storageBucket: 'pedacito-de-cielo-e1867.firebasestorage.app',
    iosBundleId: 'com.example.postresApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBf_--Jfwj3_xq_Woyh15h0XKTU0HeZr1M',
    appId: '1:1053420085133:web:833db765eccbbcb659e7c4',
    messagingSenderId: '1053420085133',
    projectId: 'pedacito-de-cielo-e1867',
    authDomain: 'pedacito-de-cielo-e1867.firebaseapp.com',
    storageBucket: 'pedacito-de-cielo-e1867.firebasestorage.app',
    measurementId: 'G-PEYRECX1VR',
  );
}
