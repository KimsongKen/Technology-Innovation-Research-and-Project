class TriageSession {
  TriageSession({
    required this.chiefComplaint,
    required this.onset,
    required this.isWorsening,
    required this.isRapidlyWorsening,
    required this.medications,
    required this.allergies,
    required this.painLocation,
  });

  String chiefComplaint;
  String onset;
  bool isWorsening;
  bool isRapidlyWorsening;
  String medications;
  String allergies;
  List<String> painLocation;
}
