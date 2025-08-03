import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import '../../Hivemodel/medicine.dart';
import '../../services/hive_services.dart';
import '../../utils/date_utils.dart';

class AddMedicinePage extends StatefulWidget {
  const AddMedicinePage({super.key});

  @override
  State<AddMedicinePage> createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _quantityController = TextEditingController();
  final _thresholdController = TextEditingController();

  DateTime? _selectedDate;
  int? _timesPerDay;
  List<TimeOfDay?> _doseTimes = [null, null, null, null];

  String? _intValidator(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return 'Enter $fieldName';
    if (int.tryParse(value) == null) return '$fieldName must be an integer';
    return null;
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime(BuildContext context, int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _doseTimes[index] ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _doseTimes[index] = picked);
  }

  Future<void> _saveMedicine() async {
    bool allTimesSelected = _timesPerDay != null &&
        List.generate(_timesPerDay!, (i) => _doseTimes[i])
            .every((t) => t != null);

    if (_formKey.currentState!.validate() &&
        _selectedDate != null &&
        _timesPerDay != null &&
        allTimesSelected) {
      final intakeTimes = List.generate(
        _timesPerDay!,
        (i) => timeOfDayToString(_doseTimes[i]!),
      );

      final name = _nameController.text.trim();
      final dosage = _dosageController.text.trim();

      final medicineBox = Hive.box<Medicine>(medicinesBox);
      final alreadyExists = medicineBox.values.any(
        (med) =>
            med.name.toLowerCase() == name.toLowerCase() &&
            med.dosage == dosage,
      );

      if (alreadyExists) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Duplicate Medicine"),
            content: Text("Medicine \"$name\" already exists."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
        return; // Stop here
      }

      final medicine = Medicine(
        name: name,
        dosage: _dosageController.text.trim(),
        expiryDate: _selectedDate!,
        dailyIntakeTimes: intakeTimes,
        totalQuantity: int.parse(_quantityController.text),
        quantityLeft: int.parse(_quantityController.text),
        refillThreshold: int.parse(_thresholdController.text),
      );

      medicineBox.add(medicine);

      for (final timeStr in medicine.dailyIntakeTimes) {
        final parts = timeStr.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        DateTime scheduledTime = DateTime.now();
        if (DateTime.now().isAfter(DateTime(
          scheduledTime.year,
          scheduledTime.month,
          scheduledTime.day,
          hour,
          minute,
        ))) {
          scheduledTime = scheduledTime.add(const Duration(days: 1));
        }

        scheduledTime = DateTime(
          scheduledTime.year,
          scheduledTime.month,
          scheduledTime.day,
          hour,
          minute,
        );

        // Schedule notification here if needed
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.green[50],
          title: const Text("Success"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("Medicine \"$name\" added successfully."),
              const Icon(Icons.check_circle,
                  color: Color.fromARGB(255, 50, 160, 52), size: 62),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // go back
              },
              child: const Text(
                "OK",
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Error"),
          content:
              const Text("Please fill all fields and select proper timings."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mainGreen = const Color(0xFF166D5B);

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('New Medicine', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Medicine Name',
                  prefixIcon: Icon(Icons.medical_services, color: mainGreen),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Enter medicine name'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dosageController,
                decoration: InputDecoration(
                  labelText: 'Dosage (e.g. 500mg)',
                  prefixIcon:
                      Icon(Icons.format_list_numbered, color: mainGreen),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => _intValidator(v, "dosage"),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Total Quantity',
                  prefixIcon: Icon(Icons.numbers, color: mainGreen),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => _intValidator(v, "dosage"),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _thresholdController,
                decoration: InputDecoration(
                  labelText: 'Refill Threshold',
                  prefixIcon: Icon(Icons.warning, color: mainGreen),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => _intValidator(v, "dosage"),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) {
                  final value = index + 1;
                  return ChoiceChip(
                    label: Text("$value"),
                    selected: _timesPerDay == value,
                    onSelected: (_) => setState(() => _timesPerDay = value),
                    selectedColor: Colors.green[700],
                    labelStyle: TextStyle(
                      color: _timesPerDay == value ? Colors.white : mainGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    backgroundColor: Colors.green[50],
                  );
                }),
              ),
              const SizedBox(height: 16),
              if (_timesPerDay != null)
                Column(
                  children: List.generate(_timesPerDay!, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _pickTime(context, i),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Time for dose ${i + 1}',
                            prefixIcon:
                                Icon(Icons.access_time, color: mainGreen),
                          ),
                          child: Text(
                            _doseTimes[i] == null
                                ? 'Select time'
                                : _doseTimes[i]!.format(context),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _pickDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Expiry Date',
                    prefixIcon: Icon(Icons.date_range, color: mainGreen),
                  ),
                  child: Text(
                    _selectedDate == null
                        ? 'Select date'
                        : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveMedicine,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Save",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
