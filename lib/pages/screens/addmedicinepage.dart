import 'package:flutter/material.dart';

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
  final maincolor = Colors.green[800];

  DateTime? _selectedDate;
  int? _timesPerDay;
  List<TimeOfDay?> _doseTimes = [null, null, null, null];
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

  void _saveMedicine() {
    bool allTimesSelected = _timesPerDay != null &&
        List.generate(_timesPerDay!, (i) => _doseTimes[i])
            .every((t) => t != null);
    if (_formKey.currentState!.validate() &&
        _selectedDate != null &&
        _timesPerDay != null &&
        allTimesSelected) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('Medicine Saved!')),
      // );
      Navigator.pop(context);
      showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Success"),
        content: Column(mainAxisAlignment: MainAxisAlignment.center,mainAxisSize: MainAxisSize.min,
        children: [Text("New Medicine - ${_nameController.text.trim()} Added"),Icon(Icons.lens_blur,color: Colors.green,size: 30,)]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Ok"),
          ),
          
        ],
      ),
    );

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Medicine'),
        backgroundColor: Colors.green[800],
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
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
                  prefixIcon: Icon(Icons.medical_services, color: maincolor),
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
                      Icon(Icons.format_list_numbered, color: maincolor),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter dosage' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Total Quantity',
                  prefixIcon: Icon(Icons.numbers, color: maincolor),
                ),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter total quantity' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _thresholdController,
                decoration: InputDecoration(
                  labelText: 'Refill Threshold',
                  prefixIcon: Icon(Icons.warning, color: maincolor),
                ),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter refill threshold' : null,
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
                      color: _timesPerDay == value ? Colors.white : maincolor,
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
                                Icon(Icons.access_time, color: maincolor),
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
                    prefixIcon: Icon(Icons.date_range, color: maincolor),
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
