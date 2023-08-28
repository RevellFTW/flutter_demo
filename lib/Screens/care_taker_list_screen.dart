import 'package:flutter/material.dart';
import 'package:todoapp/Models/caretaker.dart';
import 'caretaker_profile_screen.dart';

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
