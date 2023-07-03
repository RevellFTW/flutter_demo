import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:intl/intl.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

final db = FirebaseFirestore.instance;
final FirebaseAuth _auth = FirebaseAuth.instance;

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

class MyHomePage extends StatelessWidget {
  MyHomePage({Key? key}) : super(key: key);

  Future<String?> _authUser(LoginData data) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: data.name,
        password: data.password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        return 'Wrong password provided for that user.';
      }
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> _registerUser(SignupData data) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: data.name.toString(),
        password: data.password.toString(),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        return 'The account already exists for that email.';
      }
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ápoló alkalmazás'),
        centerTitle: true,
      ),
      body: FlutterLogin(
        title: 'Ápoló alkalmazás',
        onLogin: _authUser,
        onSignup: _registerUser,
        onRecoverPassword: ((p0) => null),
        onSubmitAnimationCompleted: () {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => const PatientSelectionScreen(),
          ));
        },
      ),
    );
  }
}

class PatientSelectionScreen extends StatelessWidget {
  const PatientSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Válasszon pácienst'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Autó Géza'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TodoListScreen(patientId: 'Géza'),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Drift Elek'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TodoListScreen(patientId: 'Elek'),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Monza Ferenc'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TodoListScreen(patientId: 'Ferenc'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  final String patientId;

  const TodoListScreen({Key? key, required this.patientId}) : super(key: key);

  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  FirebaseMessaging messaging = FirebaseMessaging.instance;
  String? fcmToken;

  void retrieveFCMToken() async {
    String? token = await messaging.getToken();
    fcmToken = token;
    print('FCM Token: $fcmToken');
  }

  Stopwatch _stopwatch = Stopwatch();
  late Timer _timer;
  Duration _elapsedTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    retrieveFCMToken();
    _startTimer();
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _stopwatch.start();
    _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      setState(() {
        _elapsedTime = _stopwatch.elapsed;
      });
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Elvégzett feladatok: ${widget.patientId}'),
      ),
      body: Column(
        children: [
          TimeTrackerWidget(duration: _elapsedTime),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: db.collection('todos').snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return Center(
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
                      return SizedBox.shrink();
                    }

                    return ListTile(
                      title: Text(task['taskName']),
                      subtitle: Text(task['taskDescription']),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          db
                              .collection('todos')
                              .doc(documentSnapshot.id)
                              .delete();
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return AddTaskWidget();
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class AddTaskWidget extends StatefulWidget {
  @override
  _AddTaskWidgetState createState() => _AddTaskWidgetState();
}

class _AddTaskWidgetState extends State<AddTaskWidget> {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  String? taskName;
  String? taskDescription;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Add Task',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Task Name',
            ),
            onChanged: (value) {
              setState(() {
                taskName = value;
              });
            },
          ),
          const SizedBox(height: 10),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Task Description',
            ),
            onChanged: (value) {
              setState(() {
                taskDescription = value;
              });
            },
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (taskName != null && taskDescription != null) {
                db.collection('todos').add({
                  'taskName': taskName,
                  'taskDescription': taskDescription,
                });

                Navigator.pop(context);
              }
            },
            child: Text('Feladat megadása'),
          ),
        ],
      ),
    );
  }
}

class TimeTrackerWidget extends StatelessWidget {
  final Duration duration;

  const TimeTrackerWidget({required this.duration});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey,
      padding: EdgeInsets.all(16),
      child: Text(
        _formatDuration(duration),
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
