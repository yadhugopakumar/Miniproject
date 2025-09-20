import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../Hivemodel/alarm_model.dart';
import '../../Hivemodel/medicine.dart';
import '../../reminder/services/alarm_service.dart';
import '../../utils/customsnackbar.dart';

class EditMedicinePage extends StatefulWidget {
  final Medicine medicine;
  final dynamic medicineKey;

  const EditMedicinePage({
    super.key,
    required this.medicine,
    required this.medicineKey,
  });

  @override
  State<EditMedicinePage> createState() => _EditMedicinePageState();
}

class _EditMedicinePageState extends State<EditMedicinePage> {
  bool _isediting = false;

  late TextEditingController _nameController;
  late TextEditingController _dosageController;
  late TextEditingController _stockController;
  late TextEditingController _thresholdController;
  late TextEditingController _instructionsController;

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

  DateTime? _selectedDate;
  int? _timesPerDay;
  late List<TimeOfDay?> _doseTimes;
  @override
  void initState() {
    super.initState();

    // Prefill text fields
    _nameController = TextEditingController(text: widget.medicine.name);
    _dosageController = TextEditingController(text: widget.medicine.dosage);
    _stockController =
        TextEditingController(text: widget.medicine.totalQuantity.toString());
    _thresholdController =
        TextEditingController(text: widget.medicine.refillThreshold.toString());
    _instructionsController =
        TextEditingController(text: widget.medicine.instructions ?? "");

    // Prefill expiry date
    _selectedDate = widget.medicine.expiryDate;

    // Prefill times per day
    _timesPerDay = widget.medicine.dailyIntakeTimes.length;

    // Convert stored intake times ("HH:mm") → TimeOfDay
    _doseTimes = widget.medicine.dailyIntakeTimes.map((t) {
      final parts = t.split(":");
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }).toList();

    // Ensure exactly 4 slots for UI consistency
    _doseTimes = List<TimeOfDay?>.from(_doseTimes)..length = 4;

    // Optional: load alarm details (if you want extra prefill from alarmsBox)
    final alarmBox = Hive.box<AlarmModel>('alarms');
    final relatedAlarms = alarmBox.values
        .where((a) => a.medicineName == widget.medicine.name)
        .toList();

    if (relatedAlarms.isNotEmpty) {
      _isRepeating = relatedAlarms.first.isRepeating;
      _selectedDays = relatedAlarms.first.selectedDays;
      _enableReminder = relatedAlarms.first.isActive;
    }
  }

  Future<void> _pickTime(BuildContext context, int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _doseTimes[index] ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF166D5B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _doseTimes[index] = picked;
      });
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF166D5B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveChanges() async {
    setState(() => _isediting = true);

    bool allTimesSelected = _timesPerDay != null &&
        List.generate(_timesPerDay!, (i) => _doseTimes[i])
            .every((t) => t != null);

    if (_nameController.text.trim().isEmpty ||
        _dosageController.text.trim().isEmpty ||
        _stockController.text.trim().isEmpty ||
        _thresholdController.text.trim().isEmpty ||
        _selectedDate == null ||
        _timesPerDay == null ||
        !allTimesSelected) {
      AppSnackbar.show(context,
          message: "Please fill all fields", success: false);
      setState(() => _isediting = false);
      return;
    }

    try {
      // Format new times
      final doseTimes = _doseTimes
          .take(_timesPerDay!)
          .map((t) =>
              "${t!.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}")
          .toList();

      // ✅ Update existing medicine object
      final med = widget.medicine;
      med.name = _nameController.text.trim();
      med.dosage = _dosageController.text.trim();
      med.expiryDate = _selectedDate!;
      med.dailyIntakeTimes = doseTimes;
      med.totalQuantity = int.parse(_stockController.text.trim());
      med.quantityLeft = int.parse(_stockController.text.trim());
      med.refillThreshold = int.parse(_thresholdController.text.trim());
      med.instructions = _instructionsController.text.trim();

      await med.save(); // saves the same Hive object

      // ✅ Update alarms
      final alarmBox = Hive.box<AlarmModel>('alarms');

      // Remove old alarms for this medicine
      final oldAlarms = alarmBox.values
          .where((alarm) => alarm.medicineName == med.name)
          .toList();

      for (var alarm in oldAlarms) {
        await AlarmService.deleteAlarm(alarm.id);
        await alarmBox.delete(alarm.id);
      }

      // Add new alarms
      for (var i = 0; i < doseTimes.length; i++) {
        final parts = doseTimes[i].split(":");
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        final alarmId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

        final newAlarm = AlarmModel(
          id: alarmId,
          medicineName: med.name,
          dosage: med.dosage,
          title: med.name,
          description: med.instructions?.isNotEmpty == true
              ? med.instructions!
              : "Time to take the medicine - ${med.name}",
          hour: hour,
          minute: minute,
          isRepeating: true,
          isActive: true,
          selectedDays: List.from(_selectedDays),
        );

        await AlarmService.saveAlarm(newAlarm);
      }

      // ✅ Sync with Supabase
      await Supabase.instance.client.from('medicine').update({
        'name': med.name,
        'dosage': med.dosage,
        'expiry_date': med.expiryDate.toIso8601String(),
        'daily_intake_times': med.dailyIntakeTimes,
        'total_quantity': med.totalQuantity,
        'quantity_left': med.quantityLeft,
        'refill_threshold': med.refillThreshold,
      }).eq('id', widget.medicineKey);

      AppSnackbar.show(context,
          message: "Medicine & Alarms Updated", success: true);
      Navigator.pop(context);
    } catch (e) {
      print(e);
      AppSnackbar.show(context,
          message: "Failed to Update: $e", success: false);
    } finally {
      setState(() => _isediting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color mainGreen = const Color(0xFF166D5B);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Edit Medicine',
          style: TextStyle(
              fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[700],
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Medicine Name
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Medicine Name',
                  prefixIcon: Icon(Icons.medical_services, color: mainGreen),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 18),
              // Dosage
              TextField(
                controller: _dosageController,
                decoration: InputDecoration(
                  labelText: 'Dosage (e.g. 500mg)',
                  prefixIcon:
                      Icon(Icons.format_list_numbered, color: mainGreen),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 18),
              // Number of times per day
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Times per day",
                  style: TextStyle(
                      color: mainGreen,
                      fontWeight: FontWeight.w600,
                      fontSize: 16),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) {
                  int value = index + 1;
                  return ChoiceChip(
                    label: Text("$value"),
                    selected: _timesPerDay == value,
                    onSelected: (selected) {
                      setState(() {
                        _timesPerDay = value;
                      });
                    },
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
              const SizedBox(height: 18),
              // Time pickers for each dose
              if (_timesPerDay != null)
                Column(
                  children: List.generate(_timesPerDay!, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: InkWell(
                        onTap: () => _pickTime(context, i),
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Time for dose ${i + 1}',
                            prefixIcon:
                                Icon(Icons.access_time, color: mainGreen),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            _doseTimes[i] == null
                                ? 'Select time'
                                : _doseTimes[i]!.format(context),
                            style: TextStyle(
                              fontSize: 16,
                              color: _doseTimes[i] == null
                                  ? Colors.grey
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              // Till Date
              InkWell(
                onTap: () => _pickDate(context),
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Till Date',
                    prefixIcon: Icon(Icons.date_range, color: mainGreen),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _selectedDate == null
                        ? 'Select date'
                        : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedDate == null ? Colors.grey : Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _thresholdController,
                decoration: InputDecoration(
                  labelText: 'Refill Threshold',
                  prefixIcon: Icon(Icons.warning, color: mainGreen),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),

              // Stock Quantity
              TextField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Total Quantity',
                  prefixIcon: Icon(Icons.inventory_2, color: mainGreen),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
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
                  const Text('Repeat on:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
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
              const SizedBox(height: 32),
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isediting
                      ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)
                      : const Text(
                          "Save Changes",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.1,
                          ),
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
