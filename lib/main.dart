import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'Pages/my_home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) {
    applicationToken = fcmToken;
    // Note: This callback is fired at each app startup and whenever a new
    // token is generated.
  });
  runApp(const MyApp());
}

final db = FirebaseFirestore.instance;
final messaging = FirebaseMessaging.instance;
String applicationToken = '';
DocumentSnapshot<Map<String, dynamic>>? currentUser;
String currentUserID = '';
bool isClient = false;

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}
