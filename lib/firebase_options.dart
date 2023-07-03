// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyAGQphhEYLJdKWEIMMpReE512er0MLBU_8',
    appId: '1:404775449223:web:e73ba3951713fe8e87be22',
    messagingSenderId: '404775449223',
    projectId: 'flutterproject-22248',
    authDomain: 'flutterproject-22248.firebaseapp.com',
    storageBucket: 'flutterproject-22248.appspot.com',
    measurementId: 'G-46872GSTY7',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBXzbOEhyaF_rmxZ_hEiVSrLTf_ky9IJx0',
    appId: '1:404775449223:android:ff6796d8738af5b587be22',
    messagingSenderId: '404775449223',
    projectId: 'flutterproject-22248',
    storageBucket: 'flutterproject-22248.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCgjQnrBsiIV3SPHmpc0SxvT_Tw3BqLmEg',
    appId: '1:404775449223:ios:49f5b89b1143e4db87be22',
    messagingSenderId: '404775449223',
    projectId: 'flutterproject-22248',
    storageBucket: 'flutterproject-22248.appspot.com',
    iosClientId: '404775449223-kp46k01i0mtp2dooej60aks7sls26m6p.apps.googleusercontent.com',
    iosBundleId: 'com.example.todoapp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCgjQnrBsiIV3SPHmpc0SxvT_Tw3BqLmEg',
    appId: '1:404775449223:ios:f79c664eeb201e6687be22',
    messagingSenderId: '404775449223',
    projectId: 'flutterproject-22248',
    storageBucket: 'flutterproject-22248.appspot.com',
    iosClientId: '404775449223-5fgbl4dck77emaarisikuh287qf3vpb2.apps.googleusercontent.com',
    iosBundleId: 'com.example.todoapp.RunnerTests',
  );
}
