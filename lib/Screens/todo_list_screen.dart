import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../Models/patient.dart';
import '../Widgets/add_task_widget.dart';
import '../Widgets/time_tracker_widget.dart';
import '../firebase_options.dart';

class TodoListScreen extends StatefulWidget {
  final Patient patient;
  final String? coordinate;

  const TodoListScreen({Key? key, required this.patient, this.coordinate})
      : super(key: key);

  @override
  TodoListScreenState createState() => TodoListScreenState();
}

class TodoListScreenState extends State<TodoListScreen> {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  String? mtoken = "";
  final Stopwatch _stopwatch = Stopwatch();
  late Timer _timer;
  Duration _elapsedTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    requestPermission();
    getToken();
    _startTimer();
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
        .doc(widget.patient.id)
        .set({
      "token": token,
    });
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
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
        title: Text('Elvégzett feladatok: ${widget.patient.name}'),
      ),
      body: Column(
        children: [
          Expanded(
            //alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
              child: Text(
                'City: ${widget.coordinate}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          TimeTrackerWidget(duration: _elapsedTime),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Object?>>(
              stream: db
                  .collection('tasks')
                  .where("patientID", isEqualTo: widget.patient.id)
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot<Object?>> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                // Filter out non-collection fields from the snapshot data
                List<QueryDocumentSnapshot> dayCollections = snapshot.data!.docs
                    .where((doc) => doc is CollectionReference)
                    .toList();

                if (dayCollections.isEmpty) {
                  return const Center(
                    child: Text('No data available'),
                  );
                }

                return ListView.builder(
                  itemCount: dayCollections.length,
                  itemBuilder: (BuildContext context, int index) {
                    String date = dayCollections[index].id;
                    CollectionReference dayCollection =
                        dayCollections[index] as CollectionReference;

                    return StreamBuilder<QuerySnapshot<Object?>>(
                      stream: dayCollection.snapshots(),
                      builder: (BuildContext context,
                          AsyncSnapshot<QuerySnapshot<Object?>> tasksSnapshot) {
                        if (!tasksSnapshot.hasData) {
                          return const SizedBox.shrink();
                        }

                        List<QueryDocumentSnapshot<Object?>> taskDocuments =
                            tasksSnapshot.data!.docs;

                        // Convert task documents to Map<String, dynamic> list
                        List<Map<String, dynamic>> tasks = taskDocuments
                            .map((doc) => doc.data() as Map<String, dynamic>)
                            .toList();

                        return ExpansionTile(
                          title: Text(date),
                          children: tasks.map((task) {
                            return ListTile(
                              title: Text(task['taskName']),
                              subtitle: Text(task['taskDescription']),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  // Remove the task document from the day's collection
                                  dayCollection.doc(task['taskId']).delete();
                                },
                              ),
                            );
                          }).toList(),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          // Modify patient attributes
          ListTile(
            title: Text('Name: ${widget.patient.name}'),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  String updatedName = widget.patient.name;
                  return AlertDialog(
                    title: Text('Edit Name'),
                    content: TextField(
                      onChanged: (value) {
                        updatedName = value;
                      },
                      controller: TextEditingController(text: updatedName),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          // Update patient's name in the database
                          await FirebaseFirestore.instance
                              .collection('patients')
                              .doc(widget.patient.id)
                              .update({'name': updatedName});
                          // Update patient's name in the UI
                          setState(() {
                            widget.patient.name = updatedName;
                          });
                          Navigator.pop(context);
                        },
                        child: Text('Save'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          ListTile(
            title: Text('Age: ${widget.patient.age}'),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  String updatedAge = widget.patient.age;
                  return AlertDialog(
                    title: Text('Edit age'),
                    content: TextField(
                      onChanged: (value) {
                        updatedAge = value;
                      },
                      controller: TextEditingController(text: updatedAge),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          // Update patient's name in the database
                          await FirebaseFirestore.instance
                              .collection('patients')
                              .doc(widget.patient.id)
                              .update({'age': updatedAge});
                          // Update patient's name in the UI
                          setState(() {
                            widget.patient.age = updatedAge;
                          });
                          Navigator.pop(context);
                        },
                        child: Text('Save'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          ListTile(
            title: Text('Medical state: ${widget.patient.medicalState}'),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  String updatedState = widget.patient.medicalState;
                  return AlertDialog(
                    title: const Text('Edit State'),
                    content: StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DropdownButton<String>(
                              value: updatedState,
                              onChanged: (newValue) {
                                setState(() {
                                  updatedState = newValue!;
                                });
                              },
                              items: <String>[
                                'Critical',
                                'Bad',
                                'Stable',
                                // Add more options as needed
                              ].map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                            SizedBox(height: 16.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    // Update patient's medicalState in the database
                                    await FirebaseFirestore.instance
                                        .collection('patients')
                                        .doc(widget.patient.id)
                                        .update({'medicalState': updatedState});
                                    // Update patient's medicalState in the UI
                                    setState(() {
                                      widget.patient.medicalState =
                                          updatedState;
                                    });
                                    Navigator.pop(context);
                                  },
                                  child: Text('Save'),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
          //create one more ListTile for Map<String,dynamic> allergies
        ],
      ),

      //this is the plus button

      floatingActionButton: FractionallySizedBox(
        widthFactor: 0.2, // Adjust the width factor as needed
        child: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return AddTaskWidget(patientId: widget.patient.id);
              },
            );
          },
          mini: MediaQuery.of(context).size.width <
              600, // Set mini to true for smaller screens
          backgroundColor: Colors.blue, // Customize the background color
          foregroundColor: Colors.white, // Customize the icon color
          elevation: 4.0, // Customize the elevation
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(8.0), // Customize the border radius
          ),
          heroTag: null,
          child:
              const Icon(Icons.add), // Set heroTag to null to avoid conflicts
        ),
      ),
    );
  }
}
