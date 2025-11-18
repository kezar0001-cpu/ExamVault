import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration for all supported platforms.
///
/// The values included here are *placeholder* credentials that keep the
/// application from crashing when Firebase has not yet been configured. Replace
/// each value with the configuration that matches your own Firebase project or
/// run `flutterfire configure` to regenerate this file automatically.
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
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_WEB_API_KEY', defaultValue: 'demo-web-api-key'),
    appId: String.fromEnvironment('FIREBASE_WEB_APP_ID', defaultValue: '1:000000000000:web:demo'),
    messagingSenderId: String.fromEnvironment('FIREBASE_WEB_MESSAGING_SENDER_ID', defaultValue: '000000000000'),
    projectId: String.fromEnvironment('FIREBASE_WEB_PROJECT_ID', defaultValue: 'demo-project'),
    authDomain: String.fromEnvironment('FIREBASE_WEB_AUTH_DOMAIN', defaultValue: 'demo-project.firebaseapp.com'),
    storageBucket: String.fromEnvironment('FIREBASE_WEB_STORAGE_BUCKET', defaultValue: 'demo-project.appspot.com'),
    measurementId: String.fromEnvironment('FIREBASE_WEB_MEASUREMENT_ID', defaultValue: 'G-DEMO12345'),
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_ANDROID_API_KEY', defaultValue: 'demo-android-api-key'),
    appId: String.fromEnvironment('FIREBASE_ANDROID_APP_ID', defaultValue: '1:000000000000:android:demo'),
    messagingSenderId: String.fromEnvironment('FIREBASE_ANDROID_MESSAGING_SENDER_ID', defaultValue: '000000000000'),
    projectId: String.fromEnvironment('FIREBASE_ANDROID_PROJECT_ID', defaultValue: 'demo-project'),
    storageBucket: String.fromEnvironment('FIREBASE_ANDROID_STORAGE_BUCKET', defaultValue: 'demo-project.appspot.com'),
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_IOS_API_KEY', defaultValue: 'demo-ios-api-key'),
    appId: String.fromEnvironment('FIREBASE_IOS_APP_ID', defaultValue: '1:000000000000:ios:demo'),
    messagingSenderId: String.fromEnvironment('FIREBASE_IOS_MESSAGING_SENDER_ID', defaultValue: '000000000000'),
    projectId: String.fromEnvironment('FIREBASE_IOS_PROJECT_ID', defaultValue: 'demo-project'),
    storageBucket: String.fromEnvironment('FIREBASE_IOS_STORAGE_BUCKET', defaultValue: 'demo-project.appspot.com'),
    iosBundleId: String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID', defaultValue: 'com.example.examvault'),
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_MACOS_API_KEY', defaultValue: 'demo-macos-api-key'),
    appId: String.fromEnvironment('FIREBASE_MACOS_APP_ID', defaultValue: '1:000000000000:macos:demo'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MACOS_MESSAGING_SENDER_ID', defaultValue: '000000000000'),
    projectId: String.fromEnvironment('FIREBASE_MACOS_PROJECT_ID', defaultValue: 'demo-project'),
    storageBucket: String.fromEnvironment('FIREBASE_MACOS_STORAGE_BUCKET', defaultValue: 'demo-project.appspot.com'),
    iosBundleId: String.fromEnvironment('FIREBASE_MACOS_BUNDLE_ID', defaultValue: 'com.example.examvault'),
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_WINDOWS_API_KEY', defaultValue: 'demo-windows-api-key'),
    appId: String.fromEnvironment('FIREBASE_WINDOWS_APP_ID', defaultValue: '1:000000000000:windows:demo'),
    messagingSenderId:
        String.fromEnvironment('FIREBASE_WINDOWS_MESSAGING_SENDER_ID', defaultValue: '000000000000'),
    projectId: String.fromEnvironment('FIREBASE_WINDOWS_PROJECT_ID', defaultValue: 'demo-project'),
    storageBucket: String.fromEnvironment('FIREBASE_WINDOWS_STORAGE_BUCKET', defaultValue: 'demo-project.appspot.com'),
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_LINUX_API_KEY', defaultValue: 'demo-linux-api-key'),
    appId: String.fromEnvironment('FIREBASE_LINUX_APP_ID', defaultValue: '1:000000000000:linux:demo'),
    messagingSenderId: String.fromEnvironment('FIREBASE_LINUX_MESSAGING_SENDER_ID', defaultValue: '000000000000'),
    projectId: String.fromEnvironment('FIREBASE_LINUX_PROJECT_ID', defaultValue: 'demo-project'),
    storageBucket: String.fromEnvironment('FIREBASE_LINUX_STORAGE_BUCKET', defaultValue: 'demo-project.appspot.com'),
  );
}
