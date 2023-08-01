import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:location/location.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

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
final FirebaseAuth _auth = FirebaseAuth.instance;
final messaging = FirebaseMessaging.instance;
String applicationToken = '';
DocumentSnapshot<Map<String, dynamic>>? currentUser;
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

// ignore: must_be_immutable
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
              _requestLocationPermission("Géza", context);
            },
          ),
          ListTile(
            title: const Text('Drift Elek'),
            onTap: () {
              _requestLocationPermission("Elek", context);
            },
          ),
          ListTile(
            title: const Text('Monza Ferenc'),
            onTap: () {
              _requestLocationPermission("Ferenc", context);
            },
          ),
        ],
      ),
    );
  }

  void _requestLocationPermission(
      String patientId, BuildContext context) async {
    Location location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;
    LocationData locationData;

    // Check if location services are enabled
    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        // Handle case when location services are not enabled
        return;
      }
    }

    // Check if the app has permission to access location
    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        // Handle case when permission is not granted
        return;
      }
    }

    // Get the current location
    locationData = await location.getLocation();
    double latitude = locationData.latitude!;
    double longitude = locationData.longitude!;

    String coordinate = "$latitude,$longitude";

    // Get city name based on coordinates

    // Pass the city name to the TodoListScreen
    // ignore: use_build_context_synchronously
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TodoListScreen(
          patientId: patientId,
          coordinate: coordinate,
        ),
      ),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  final String patientId;
  final String? coordinate;

  const TodoListScreen({Key? key, required this.patientId, this.coordinate})
      : super(key: key);

  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
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
        .doc(widget.patientId)
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
        title: Text('Elvégzett feladatok: ${widget.patientId}'),
      ),
      body: Column(
        children: [
          Align(
            alignment: Alignment.bottomLeft,
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
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          db
                              .collection('todos')
                              .doc(widget.patientId.toString())
                              .collection('tasks')
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
      //this is the plus button

      floatingActionButton: FractionallySizedBox(
        widthFactor: 0.2, // Adjust the width factor as needed
        child: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return AddTaskWidget(patientId: widget.patientId);
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

class AddTaskWidget extends StatefulWidget {
  String token = "";
  final String patientId;

  AddTaskWidget({super.key, required this.patientId});
  @override
  // ignore: library_private_types_in_public_api
  _AddTaskWidgetState createState() => _AddTaskWidgetState();
}

class _AddTaskWidgetState extends State<AddTaskWidget> {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  String? taskDescription;

  final List<String> items = [
    'Bevásárlás',
    'Mosás',
    'Séta',
    'Egyedi',
  ];
  String? selectedValue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButton2<String>(
            isExpanded: true,
            hint: Text(
              'Válasszon tevékenységet',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).hintColor,
              ),
            ),
            items: items
                .map((String item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ))
                .toList(),
            value: selectedValue,
            onChanged: (String? value) {
              setState(() {
                selectedValue = value;
              });
            },
            buttonStyleData: const ButtonStyleData(
              padding: EdgeInsets.symmetric(horizontal: 16),
              height: 40,
              width: 140,
            ),
            menuItemStyleData: const MenuItemStyleData(
              height: 40,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Részletek',
            ),
            onChanged: (value) {
              setState(() {
                taskDescription = value;
              });
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              if (selectedValue != null && taskDescription != null) {
                db
                    .collection('todos')
                    .doc(widget.patientId.toString())
                    .collection('tasks')
                    .add({
                  'taskName': selectedValue,
                  'taskDescription': taskDescription,
                }).then((_) {
                  db
                      .collection('todos')
                      .doc(widget.patientId.toString())
                      .update(
                          {'caretaker': currentUser!.data()!['clientName']});
                  sendNotification(selectedValue!, taskDescription);
                  Navigator.pop(context);
                }).catchError((error) => print('Add failed: $error'));
              }
            },
            child: const Text('Feladat megadása'),
          ),
        ],
      ),
    ));
  }

  void sendNotification(String taskName, String? taskDescription) async {
    var dbUser = await db
        .collection('users')
        .where('clientName', isEqualTo: widget.patientId)
        .get()
        .then((value) => value.docs.first);
    var token = dbUser.data()['token'];
    String serverKey =
        'AAAAXj5_Moc:APA91bEAt0jcbmGF9EGhpwAufWuKqr3bHqtdZ_xm_UQi5KGSog586k0Md_2soKYBJKJ9Ov2W9MewDjLj9R1S-2AKL8wZSVcWTQhaPPu-QfJRbtco6qsLXAbiwE1H0s25osBNvhbYbmm2';
    Map<String, dynamic> notification = {
      'title': taskName,
      'body': taskDescription,
    };

    // Prepare the request headers and payload
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'key=$serverKey',
    };

    Map<String, dynamic> payload = {
      'to': token,
      'notification': notification,
      'android': {
        'priority': 'high',
        'notification': {
          'sound': 'default',
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
      },
    };

    // Send the POST request to FCM REST API
    await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: headers,
      body: json.encode(payload),
    );
  }
}

class TimeTrackerWidget extends StatelessWidget {
  final Duration duration;

  const TimeTrackerWidget({super.key, required this.duration});

  String _formatDuration(Duration duration) {
    String formattedDuration = '';

    if (duration.inHours > 0) {
      formattedDuration += '${duration.inHours}ó ';
    }

    if (duration.inMinutes > 0) {
      formattedDuration += '${duration.inMinutes.remainder(60)}p ';
    }

    formattedDuration += '${duration.inSeconds.remainder(60)}mp';

    return formattedDuration.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        color: Colors.grey[200],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _formatDuration(duration),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class UnderReviewPage extends StatelessWidget {
  const UnderReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Regisztráció elbírálás alatt'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'A regisztrációd elbírálás alatt áll, vagy nem lett még szerep hozzárendelve a fiókhoz.',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            Text(
              'Amint elfogadásra került a regisztrációd, be tudsz jelentkezni.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileListScreen extends StatelessWidget {
  const ProfileListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adatlapok'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Páciensek'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PatientSelectionScreen(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Ápolók'),
            onTap: () async {
              var caretakers = await fetchCaretakersFromDb();

              // ignore: use_build_context_synchronously
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CaretakerListScreen(caretakers: caretakers),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<List<Caretaker>> fetchCaretakersFromDb() async {
    List<Caretaker> caretakersFromDb = [];

    QuerySnapshot querySnapshot = await db
        .collection('users')
        .where('accountType', isEqualTo: 'caretaker')
        .get();

    caretakersFromDb = querySnapshot.docs.map((doc) {
      return Caretaker(
        name: doc.get('clientName'),
        email: doc.id,
      );
    }).toList();
    caretakersFromDb.forEach((caretaker) async {
      List<String> clientsNames = await db
          .collection('todos')
          .where('caretaker', isEqualTo: caretaker.name)
          .get()
          .then((value) => value.docs.map((doc) => doc.id).toList());
      var clients = await db
          .collection('users')
          .where('clientName', whereIn: clientsNames)
          .get()
          .then((value) => value.docs.map((doc) {
                return Patient(
                  name: doc.get('clientName'),
                  email: doc.id,
                  age: doc.get('age'),
                  medicalState: doc.get('medicalState'),
                  allergies: doc.get('allergies'),
                );
              }).toList());
      caretaker.clients = clients;
    });
    return caretakersFromDb;
  }
}

class CaretakerListScreen extends StatelessWidget {
  final List<Caretaker> caretakers;

  const CaretakerListScreen({super.key, required this.caretakers});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caretakers'),
      ),
      body: ListView.builder(
        itemCount: caretakers.length,
        itemBuilder: (context, index) {
          final caretaker = caretakers[index];
          return ListTile(
            title: Text(caretaker.name),
            subtitle: Text(caretaker.email),
            onTap: () {
              // Handle caretaker profile navigation here
              // For example, you can navigate to a CaretakerProfileScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CaretakerProfileScreen(
                    caretaker: caretaker,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class CaretakerProfileScreen extends StatefulWidget {
  final Caretaker caretaker;

  const CaretakerProfileScreen({Key? key, required this.caretaker})
      : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _CaretakerProfileScreenState createState() => _CaretakerProfileScreenState();
}

class _CaretakerProfileScreenState extends State<CaretakerProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.caretaker.name);
    _emailController = TextEditingController(text: widget.caretaker.email);
    _passwordController =
        TextEditingController(text: widget.caretaker.password);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caretaker Profile'),
      ),
      body: ListView(
        children: <Widget>[
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
            ),
          ),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
            ),
          ),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
            ),
            obscureText: true,
          ),
          for (var client in widget.caretaker.clients)
            ListTile(
              title: Text(client.name),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    widget.caretaker.clients.remove(client);
                    db.collection('todos').doc(client.name).set({
                      "caretaker": '',
                    });
                  });
                },
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    var clientController =
                        TextEditingController(text: client.name);
                    return AlertDialog(
                      title: const Text('Edit Client Name'),
                      content: TextField(
                        controller: clientController,
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: const Text('OK'),
                          onPressed: () {
                            //put code here to modify patient's name if needed
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

class PatientTaskScreen extends StatefulWidget {
  final String patientId;

  const PatientTaskScreen({Key? key, required this.patientId})
      : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _PatientTaskScreenState createState() => _PatientTaskScreenState();
}

class _PatientTaskScreenState extends State<PatientTaskScreen> {
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
    //this is the plus button
  }
}

// #region Models
class Patient {
  String name;
  final String email;
  int age;
  String medicalState;
  List<String> allergies = [];

  Patient(
      {required this.name,
      required this.email,
      required this.age,
      required this.medicalState,
      required this.allergies});
}

class Caretaker {
  final String name;
  final String email;
  String password = "";
  List<Patient> clients = [];

  Caretaker({required this.name, required this.email, password, clients});
}
// #endregion