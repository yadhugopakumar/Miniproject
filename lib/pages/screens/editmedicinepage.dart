import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../Hivemodel/medicine.dart';

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
  late TextEditingController _nameController;
  late TextEditingController _dosageController;
  late TextEditingController _stockController;
  DateTime? _selectedDate;
  int? _timesPerDay;
  late List<TimeOfDay?> _doseTimes;
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.medicine.name);
    _dosageController = TextEditingController(text: widget.medicine.dosage);
    _stockController =
        TextEditingController(text: widget.medicine.quantityLeft.toString());
    _selectedDate = widget.medicine.expiryDate;
    _timesPerDay = widget.medicine.dailyIntakeTimes.length;
    _doseTimes = widget.medicine.dailyIntakeTimes.map((t) {
      final parts = t.split(":");
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }).toList();

    //  Ensure _doseTimes has at least 4 slots
    _doseTimes = List<TimeOfDay?>.from(_doseTimes)..length = 4;
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
    bool allTimesSelected = _timesPerDay != null &&
        List.generate(_timesPerDay!, (i) => _doseTimes[i])
            .every((t) => t != null);

    if (_nameController.text.trim().isNotEmpty &&
        _dosageController.text.trim().isNotEmpty &&
        _stockController.text.trim().isNotEmpty &&
        _selectedDate != null &&
        _timesPerDay != null &&
        allTimesSelected) {
      final box = await Hive.openBox<Medicine>('medicinesBox');
      int addedQuantity = int.parse(_stockController.text.trim());

      final updatedMedicine = Medicine(
        name: _nameController.text.trim(),
        dosage: _dosageController.text.trim(),
        expiryDate: _selectedDate!,
        dailyIntakeTimes: _doseTimes
            .take(_timesPerDay!)
            .map((t) =>
                "${t!.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}")
            .toList(),
        quantityLeft: widget.medicine.quantityLeft + addedQuantity,
        totalQuantity: widget.medicine.totalQuantity + addedQuantity,
        refillThreshold: widget.medicine.refillThreshold,
      );

      box.put(widget.medicineKey, updatedMedicine);

// After saving updatedMedicine:
      // for (int i = 0; i < 4; i++) {
      //   await flutterLocalNotificationsPlugin
      //       .cancel(widget.medicineKey.hashCode + i);
      // }

      for (int i = 0; i < _timesPerDay!; i++) {
        final time = _doseTimes[i]!;
        DateTime scheduledDateTime = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
          time.hour,
          time.minute,
        );

        // If time is in the past today, schedule for tomorrow
        if (scheduledDateTime.isBefore(DateTime.now())) {
          scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
        }
        // await scheduleMedicineNotification(
        //   id: widget.medicineKey.hashCode + i, // unique id for each dose
        //   title: 'Time to take ${_nameController.text.trim()}',
        //   body: 'Dosage: ${_dosageController.text.trim()}',
        //   dateTime: scheduledDateTime,
        // );
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Medicine Updated',
            style: TextStyle(color: Colors.black),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color.fromARGB(255, 198, 252, 200),
          margin: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        ),
      );

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill all fields!',
            style: TextStyle(color: Colors.black),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color.fromARGB(255, 198, 252, 200),
          margin: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        ),
      );
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
              // Stock Quantity
              TextField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Add Quantity(new stock)',
                  prefixIcon: Icon(Icons.inventory_2, color: mainGreen),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
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
                  child: const Text(
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
