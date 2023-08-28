import 'package:flutter/material.dart';
import '../Models/patient.dart';
import '../main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:location/location.dart';

import 'todo_list_screen.dart';

class PatientSelectionScreen extends StatelessWidget {
  const PatientSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Válasszon pácienst'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Patient>>(
        future: fetchPatientsFromDatabase(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator(); // Loading indicator
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Text('No patients found.');
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final patient = snapshot.data![index];
                return ListTile(
                  title: Text(patient.name),
                  onTap: () {
                    _requestLocationPermission(patient, context);
                  },
                );
              },
            );
          }
        },
      ),
    );
  }

  void _requestLocationPermission(Patient patient, BuildContext context) async {
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
          patient: patient,
          coordinate: coordinate,
        ),
      ),
    );
  }

  Future<List<Patient>> fetchPatientsFromDatabase() async {
    List<Patient> patientsFromDb = [];

    QuerySnapshot querySnapshot = await db.collection('patients').get();

    patientsFromDb = querySnapshot.docs.map((doc) {
      return Patient(
        id: doc.id,
        name: doc.get('name'),
        email: doc.get('email'),
        age: doc.get('age'),
        medicalState: doc.get('medicalState'),
        allergies: doc.get('allergies'),
      );
    }).toList();

    return patientsFromDb;
  }
}
