import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import '../../Hivemodel/alarm_model.dart';
import '../../Hivemodel/medicine.dart';
import '../../Hivemodel/user_settings.dart';
import '../../reminder/services/alarm_service.dart';
import '../../services/hive_services.dart';
import '../../utils/customsnackbar.dart';
import '../../utils/date_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final _instructionsController = TextEditingController();
  bool _isloading = false;
  DateTime? _selectedDate;
  int? _timesPerDay;
  List<TimeOfDay?> _doseTimes = [null, null, null, null];
  bool _enableReminder = true; // toggle reminder on/off
  bool _isRepeating = true; // repeat daily
  List<bool> _selectedDays = List.filled(7, true);
  final List<String> _dayNames = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];

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
    setState(() => _isloading = true);

    try {
      // 1️⃣ Get local user settings
      final userBox = Hive.box<UserSettings>('settingsBox');
      final userSettings = userBox.get('user');
      if (userSettings == null) {
        setState(() => _isloading = false);
        AppSnackbar.show(context,
            message: "No user found. Please log in again.", success: false);
        return;
      }
      final childId = userSettings.childId;
      final parentId = userSettings.parentId;

      // 2️⃣ Validate form & selections
      bool allTimesSelected = _timesPerDay != null &&
          List.generate(_timesPerDay!, (i) => _doseTimes[i])
              .every((t) => t != null);

      if (!_formKey.currentState!.validate() ||
          _selectedDate == null ||
          _timesPerDay == null ||
          !allTimesSelected) {
        setState(() => _isloading = false);
        AppSnackbar.show(context,
            message: "Please fill all fields and select proper timings.",
            success: false);
        return;
      }

      // 3️⃣ Prepare medicine data
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
        setState(() => _isloading = false);
        AppSnackbar.show(context,
            message: "Medicine \"$name\" already exists.", success: false);
        return;
      }
      // 5️⃣ Save to Supabase
      final supabase = Supabase.instance.client;
      final response = await supabase.from('medicine').insert({
        'child_id': childId,
        'parent_id': parentId,
        'name': name,
        'dosage': dosage,
        'expiry_date': _selectedDate!.toIso8601String(),
        'daily_intake_times': intakeTimes,
        'total_quantity': int.parse(_quantityController.text),
        'quantity_left': int.parse(_quantityController.text),
        'refill_threshold': int.parse(_thresholdController.text),
        'created_at': DateTime.now().toIso8601String(),
        'instructions': _instructionsController.text.trim().isEmpty
            ? null
            : _instructionsController.text.trim(),
      }).select();

      if (response.isEmpty) {
        setState(() => _isloading = false);
        AppSnackbar.show(context,
            message: "Error saving to server.", success: false);
        return;
      }
      // 6️⃣ Create local Medicine object
      // Use the ID from Supabase response if needed

      final medicine = Medicine(
        id: response[0]['id'],
        name: name,
        dosage: dosage,
        expiryDate: _selectedDate!,
        dailyIntakeTimes: intakeTimes,
        totalQuantity: int.parse(_quantityController.text),
        quantityLeft: int.parse(_quantityController.text),
        refillThreshold: int.parse(_thresholdController.text),
        instructions: _instructionsController.text.trim().isEmpty
            ? null
            : _instructionsController.text.trim(),
      );
      // 4️⃣ Save to Hive first
      await medicineBox.add(medicine);

      if (_enableReminder) {
        for (int i = 0; i < _timesPerDay!; i++) {
          final doseTime = _doseTimes[i]!;
          final alarm = AlarmModel(
            id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
            medicineName: medicine.name,
            dosage: medicine.dosage,
            title: medicine.name,
            description: "Time to take the medicine - ${medicine.instructions}",
            hour: doseTime.hour,
            minute: doseTime.minute,
            isRepeating: _isRepeating,
            selectedDays: List.from(_selectedDays),
          );
          await AlarmService.saveAlarm(alarm); // schedules notification
         
        }
      }

      // 6️⃣ (Optional) Schedule notifications
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

        // TODO: Schedule notification here
      }

      // 7️⃣ Show success
      setState(() => _isloading = false);
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
    } on PostgrestException catch (e) {
      debugPrint("Supabase insert error: ${e.message}");
      AppSnackbar.show(context,
          message: "Error saving to server: ${e.message}", success: false);
      return;
    } catch (e, stack) {
      debugPrint("Unexpected error: $e\n$stack");
      setState(() => _isloading = false);
      AppSnackbar.show(context,
          message: "Unexpected error occurred.", success: false);
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
        centerTitle: true,
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
                  labelText: 'Dosage (e.g. 1pill)',
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _instructionsController,
                maxLines: 1,
                decoration: InputDecoration(
                  labelText: 'Instructions (optional)',
                  prefixIcon: Icon(Icons.edit_note_sharp, color: mainGreen),
                ),
                keyboardType: TextInputType.text,
              ),
              SwitchListTile(
  title: const Text('Enable Reminder'),
  value: _enableReminder,
  onChanged: (v) => setState(() => _enableReminder = v),
),

if (_enableReminder) ...[
  SwitchListTile(
    title: const Text('Repeat Daily'),
    value: _isRepeating,
    onChanged: (v) => setState(() => _isRepeating = v),
  ),
  if (_isRepeating) ...[
    const Text('Repeat on:', style: TextStyle(fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    Wrap(
      spacing: 8,
      children: List.generate(7, (i) {
        return FilterChip(
          label: Text(_dayNames[i]),
          selected: _selectedDays[i],
          onSelected: (s) => setState(() => _selectedDays[i] = s),
          selectedColor: Colors.green.shade200,
        );
      }),
    ),
  ],
],

              const SizedBox(height: 16),
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
                child: _isloading
                    ? const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2)
                    : const Text(
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
