import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';

class PatientTaskScreen extends StatefulWidget {
  final String patientId;

  const PatientTaskScreen({Key? key, required this.patientId})
      : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  PatientTaskScreenState createState() => PatientTaskScreenState();
}

class PatientTaskScreenState extends State<PatientTaskScreen> {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  String? mtoken = "";

  @override
  void initState() {
    super.initState();
    requestPermission();
    getToken();
  }

  void getToken() async {
    await FirebaseMessaging.instance.getToken().then((token) {
      setState(() {
        mtoken = token;
      });
      saveToken(mtoken!);
    });
  }

  void requestPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    const vapidKey =
        "BAtT0PRD3_LdaR9i1eIt-MHS8IsHs97Ib_Uva8mS9uQshRAWk_1txhuRdNTa4eLqheq218J__iIjeWHsZAq0sE8";
    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (DefaultFirebaseOptions.currentPlatform == DefaultFirebaseOptions.web) {
      await messaging.getToken(
        vapidKey: vapidKey,
      );
    } else {
      await messaging.getToken();
    }
  }

  void saveToken(String token) async {
    await FirebaseFirestore.instance
        .collection("UserTokens")
        .doc(widget.patientId)
        .set({
      "token": token,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Elvégzett feladatok: ${widget.patientId}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: db
                  .collection('todos')
                  .doc(widget.patientId.toString())
                  .collection('tasks')
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (BuildContext context, int index) {
                    DocumentSnapshot documentSnapshot =
                        snapshot.data!.docs[index];
                    Map<String, dynamic>? task =
                        documentSnapshot.data() as Map<String, dynamic>?;
                    if (task == null) {
                      return const SizedBox.shrink();
                    }
                    return ListTile(
                      title: Text(task['taskName']),
                      subtitle: Text(task['taskDescription']),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
