import 'package:flutter/material.dart';
import '../Models/caretaker.dart';
import '../main.dart';

class CaretakerProfileScreen extends StatefulWidget {
  final Caretaker caretaker;

  const CaretakerProfileScreen({Key? key, required this.caretaker})
      : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  CaretakerProfileScreenState createState() => CaretakerProfileScreenState();
}

class CaretakerProfileScreenState extends State<CaretakerProfileScreen> {
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
