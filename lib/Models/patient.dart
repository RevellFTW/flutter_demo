class Patient {
  String id = "";
  String name;
  final String email;
  String age;
  String medicalState;
  Map<String, dynamic> allergies = {};

  Patient(
      {required this.name,
      required this.email,
      required this.age,
      required this.medicalState,
      required this.allergies,
      required this.id});
}
