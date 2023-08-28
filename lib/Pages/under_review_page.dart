import 'package:flutter/material.dart';

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
