// lib/models/extracted_medicine_storage.dart
import 'extractedmedicine.dart';

class ExtractedMedicineStorage {
  static List<ExtractedMedicine> _extractedMedicines = [];

  static void setExtractedMedicines(List<ExtractedMedicine> medicines) {
    _extractedMedicines = medicines;
  }

  static List<ExtractedMedicine> getExtractedMedicines() {
    return _extractedMedicines;
  }

  static void clearExtractedMedicines() {
    _extractedMedicines.clear();
  }

  static bool hasExtractedMedicines() {
    return _extractedMedicines.isNotEmpty;
  }
}
