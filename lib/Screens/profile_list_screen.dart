import 'package:flutter/material.dart';

import '../Models/caretaker.dart';
import '../Models/patient.dart';
import 'care_taker_list_screen.dart';
import 'patient_selection_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../main.dart';

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
        name: doc.get('name'),
        email: doc.id,
      );
    }).toList();
    caretakersFromDb.forEach((caretaker) async {
      List<Patient> patients = await db
          .collection('patients')
          //refactor this to use caretaker id instead of email
          .where('caretaker', isEqualTo: caretaker.email)
          .get()
          //get name field of the document
          .then((value) => value.docs.map((doc) {
                return Patient(
                  id: doc.id,
                  name: doc.get('name'),
                  email: doc.get('email'),
                  age: doc.get('age'),
                  medicalState: doc.get('medicalState'),
                  allergies: doc.get('allergies'),
                );
              }).toList());
      caretaker.clients = patients;
    });
    return caretakersFromDb;
  }
}
