// lib/models/extracted_medicine.dart
class ExtractedMedicine {
  final String name;
  final String dosage;
  final String duration;
  final String instructions;
  final List<String> dailyIntakeTimes; // "HH:mm" strings

  ExtractedMedicine({
    this.name = "",
    this.dosage = "",
    this.duration = "As prescribed",
    this.instructions = "As prescribed",
    this.dailyIntakeTimes = const [],
  });

  factory ExtractedMedicine.fromJson(Map<String, dynamic> json) {
    return ExtractedMedicine(
      name: (json['name'] ?? "").toString(),
      dosage: (json['dosage'] ?? "").toString(),
      duration: (json['duration'] ?? "12/12/26").toString(),
      instructions: (json['instructions'] ?? "After food").toString(),
      dailyIntakeTimes: (json['dailyIntakeTimes'] is List)
          ? List<String>.from(json['dailyIntakeTimes'].map((e) => e.toString()))
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        "name": name,
        "dosage": dosage,
        "duration": duration,
        "instructions": instructions,
        "dailyIntakeTimes": dailyIntakeTimes,
      };

  @override
  String toString() =>
      "$name | $dosage | ${dailyIntakeTimes.join(", ")} | $duration | $instructions";
}
