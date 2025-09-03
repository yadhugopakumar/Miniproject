// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:medremind/reminder/services/alarm_service.dart';

// import '../Hivemodel/alarm_model.dart';

// class AddAlarmDialog extends StatefulWidget {
//   final VoidCallback onAlarmAdded;
//   const AddAlarmDialog({super.key, required this.onAlarmAdded});

//   @override
//   State<AddAlarmDialog> createState() => _AddAlarmDialogState();
// }

// class _AddAlarmDialogState extends State<AddAlarmDialog> {
//   TimeOfDay selectedTime = TimeOfDay.now();
//   final titleController = TextEditingController(text: 'Medication Reminder');
//   final descController =
//       TextEditingController(text: 'Time to take your medicine');
//   bool isRepeating = true;
//   List<bool> selectedDays = List.filled(7, true);
//   final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: const Text('Add Medication Reminder'),
//       content: SizedBox(
//         width: double.maxFinite,
//         child: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: titleController,
//                 decoration: const InputDecoration(
//                   labelText: 'Title',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 12),
//               TextField(
//                 controller: descController,
//                 decoration: const InputDecoration(
//                   labelText: 'Description',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 12),
//               ListTile(
//                 title: Text(selectedTime.format(context)),
//                 leading: const Icon(Icons.access_time),
//                 onTap: () async {
//                   final time = await showTimePicker(
//                       context: context, initialTime: selectedTime);
//                   if (time != null) setState(() => selectedTime = time);
//                 },
//               ),
//               SwitchListTile(
//                 title: const Text('Repeat Daily'),
//                 value: isRepeating,
//                 onChanged: (value) => setState(() => isRepeating = value),
//               ),
//               if (isRepeating) ...[
//                 const Text('Repeat on:',
//                     style: TextStyle(fontWeight: FontWeight.bold)),
//                 const SizedBox(height: 8),
//                 Wrap(
//                   spacing: 8,
//                   children: List.generate(7, (index) {
//                     return FilterChip(
//                       label: Text(dayNames[index]),
//                       selected: selectedDays[index],
//                       onSelected: (selected) =>
//                           setState(() => selectedDays[index] = selected),
//                       selectedColor: Colors.green.shade200,
//                     );
//                   }),
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: const Text('Cancel'),
//         ),
//         ElevatedButton(
//           onPressed: () async {
//             try {
//               final alarm = AlarmModel(
//                 id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
//                 medicineName: titleController.text,
//                 title: titleController.text,
//                 description: descController.text,
//                 dosage: ,
//                 hour: selectedTime.hour,
//                 minute: selectedTime.minute,
//                 isRepeating: isRepeating,
//                 selectedDays: selectedDays,
//               );

//               await AlarmService.saveAlarm(alarm);
//               widget.onAlarmAdded();

//               if (mounted) {
//                 Navigator.pop(context);
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content:
//                         Text('Alarm set for ${selectedTime.format(context)}'),
//                     backgroundColor: Colors.green,
//                   ),
//                 );
//               }
//             } catch (e) {
//               if (kDebugMode) print('Error saving alarm: $e');
//               if (mounted) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(
//                     content: Text('Error setting alarm'),
//                     backgroundColor: Colors.red,
//                   ),
//                 );
//               }
//             }
//           },
//           child: const Text('Save'),
//         ),
//       ],
//     );
//   }

//   @override
//   void dispose() {
//     titleController.dispose();
//     descController.dispose();
//     super.dispose();
//   }
// }
