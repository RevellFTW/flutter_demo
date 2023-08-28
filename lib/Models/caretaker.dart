import 'package:todoapp/Models/patient.dart';

class Caretaker {
  final String name;
  final String email;
  String password = "";
  List<Patient> clients = [];

  Caretaker({required this.name, required this.email, password, clients});
}
