import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:intl/intl.dart';
import '../main.dart';

// ignore: must_be_immutable
class AddTaskWidget extends StatefulWidget {
  String token = "";
  final String patientId;

  AddTaskWidget({super.key, required this.patientId});
  @override
  // ignore: library_private_types_in_public_api
  AddTaskWidgetState createState() => AddTaskWidgetState();
}

class AddTaskWidgetState extends State<AddTaskWidget> {
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
                var now = DateTime.now();
                var formatter = DateFormat('yyyy-MM-dd');
                String formattedDate = formatter.format(now);
                db.collection('tasks').add({
                  'date': formattedDate,
                  'patientID': widget.patientId,
                  'taskName': selectedValue,
                  'taskDescription': taskDescription,
                }).then((_) {
                  db
                      .collection('patients')
                      .doc(widget.patientId.toString())
                      .update({'caretaker': currentUserID});
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
