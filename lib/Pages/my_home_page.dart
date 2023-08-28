import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../Screens/patient_selection_screen.dart';
import '../Screens/patient_task_screen.dart';
import '../Screens/profile_list_screen.dart';
import '../firebase_options.dart';
import 'under_review_page.dart';
import '../main.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class MyHomePage extends StatelessWidget {
  MyHomePage({Key? key}) : super(key: key);
  bool _isApproved = false;
  final FirebaseFirestore db = FirebaseFirestore.instance;
  Future<String?> _authUser(LoginData data) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: data.name,
        password: data.password,
      );
      var userId = data.name;
      var user = await db.collection('users').doc(userId).get();
      var approved = user.data()!['approved'];
      if (!approved) {
        _isApproved = false;
        return 'A felhasználó nem lett még jóváhagyva.';
      } else {
        if (user.data()!['accountType'] == 'client') {
          FirebaseMessaging messaging = FirebaseMessaging.instance;
          const vapidKey =
              "BAtT0PRD3_LdaR9i1eIt-MHS8IsHs97Ib_Uva8mS9uQshRAWk_1txhuRdNTa4eLqheq218J__iIjeWHsZAq0sE8";
          String? token;
          if (DefaultFirebaseOptions.currentPlatform ==
              DefaultFirebaseOptions.web) {
            token = await messaging.getToken(
              vapidKey: vapidKey,
            );
          } else {
            token = (await messaging.getToken())!;
          }
          user.reference.update({'token': token});
          isClient = true;
        } else {
          isClient = false;
        }
        currentUser = user;
        currentUserID = userId;
        _isApproved = true;
        return null;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'Nem található felhasználó ezzel az e-mail címmel.';
      } else if (e.code == 'wrong-password') {
        return 'Helytelen jelszó.';
      } else if (e.code == 'invalid-email') {
        return 'Helytelen e-mail cím.';
      } else if (e.code == 'user-disabled') {
        return 'A felhasználói fiók letiltva.';
      } else if (e.code == 'too-many-requests') {
        return 'Túl sok sikertelen bejelentkezési kísérlet. Kérlek próbáld újra később.';
      }
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> _registerUser(SignupData data) async {
    try {
      var clientName = data.additionalSignupData!['clientName'];
      Map<String, dynamic> additionalData = {
        'accountType': 'client',
        'clientName': clientName,
        'approved': false,
        'token': null,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(data.name.toString())
          .set(additionalData);

      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return 'A megadott jelszó túl gyenge.';
      } else if (e.code == 'email-already-in-use') {
        return 'Létezik már felhasználó ilyen e-mail címmel.';
      }
      return e.message;
    } catch (e) {
      return e.toString();
      //todo handle already used e-mail address;
    }
  }

  @override
  Widget build(BuildContext context) {
    var keyName = "clientName";
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ápoló alkalmazás'),
        centerTitle: true,
      ),
      body: FlutterLogin(
        title: 'Ápoló alkalmazás',
        onLogin: _authUser,
        onSignup: _registerUser,
        additionalSignupFields: [
          UserFormField(
            keyName: keyName,
            displayName: "Név",
            defaultValue: "Jane Doe",
            fieldValidator: (value) {
              if (value == null || value.isEmpty) {
                return 'Kérlek add meg a neved';
              }
              return null;
            },
          ),
        ],
        onRecoverPassword: ((p0) => null),
        onSubmitAnimationCompleted: () async {
          if (_isApproved) {
            switch (currentUser!.data()!['accountType']) {
              case 'caretaker':
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (context) => const PatientSelectionScreen(),
                ));
                break;
              case 'back-office':
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (context) => const ProfileListScreen(),
                ));
                break;
              //default is client
              default:
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (context) => PatientTaskScreen(
                      patientId: currentUser!.data()!['clientName']),
                ));
            }
          } else {
            Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (context) => const UnderReviewPage(),
            ));
          }
        },
        messages: LoginMessages(
          userHint: 'Felhasználónév',
          passwordHint: 'Jelszó',
          confirmPasswordHint: 'Jelszó megerősítése',
          loginButton: 'Bejelentkezés',
          signupButton: 'Regisztráció',
          forgotPasswordButton: 'Elfelejtett jelszó',
          recoverPasswordButton: 'Jelszó visszaállítása',
          goBackButton: 'Vissza',
          confirmPasswordError: 'A jelszavak nem egyeznek',
          recoverPasswordIntro: 'Jelszó visszaállítás',
          recoverPasswordDescription:
              'Az e-mail címedre küldünk egy linket a jelszó visszaállításához',
          recoverPasswordSuccess: 'Jelszó visszaállítása sikeres',
        ),
        theme: LoginTheme(
          accentColor: Colors.white,
          primaryColor: Colors.blue,
          errorColor: Colors.red,
          titleStyle: const TextStyle(
              color: Colors.white,
              fontFamily: 'OpenSans',
              letterSpacing: 4,
              fontWeight: FontWeight.bold,
              fontSize: 28),
          textFieldStyle: const TextStyle(
              color: Colors.blue, fontFamily: 'OpenSans', fontSize: 16),
          buttonStyle: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          cardTheme: const CardTheme(
              elevation: 5,
              margin:
                  EdgeInsets.only(top: 15, bottom: 15, left: 20, right: 20)),
        ),
      ),
    );
  }
}
