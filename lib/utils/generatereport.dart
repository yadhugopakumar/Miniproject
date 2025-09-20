// import 'dart:io';
// import 'package:flutter/services.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:hive/hive.dart';
// import '../../Hivemodel/medicine.dart';
// import '../../Hivemodel/history_entry.dart';
// import '../Hivemodel/health_report.dart';

// Future<String?> generateMonthlyReportPdf() async {
//   final pdf = pw.Document();

//   // Load Unicode TTF font
//   final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
//   final roboto = pw.Font.ttf(fontData);

//   final medicinesBox = Hive.box<Medicine>('medicinesBox');
//   final historyBox = Hive.box<HistoryEntry>('historyBox');
//   final now = DateTime.now();

//   final medicines = medicinesBox.values.toList();
//   final history = historyBox.values.toList();
// final healthReportBox = Hive.box<HealthReport>('healthReportBox');
// final healthReports = healthReportBox.values.toList();

// // Sort by date descending
// healthReports.sort((a, b) => b.reportDate.compareTo(a.reportDate));
//   pdf.addPage(
//     pw.MultiPage(
//       pageFormat: PdfPageFormat.a4,
//       build: (context) {
//         return [
//           pw.Header(
//             level: 0,
//             child: pw.Text('Monthly Medicine Report',
//                 style: pw.TextStyle(fontSize: 24, font: roboto)),
//           ),
//           pw.SizedBox(height: 10),

//           // Medicine Details Table
//           pw.Text('Medicine Details:',
//               style: pw.TextStyle(
//                   fontSize: 18, fontWeight: pw.FontWeight.bold, font: roboto)),
//           pw.TableHelper.fromTextArray(
//             context: context,
//             data: medicines.map((med) => [
//               med.name,
//               med.dosage,
//               med.totalQuantity.toString(),
//               med.quantityLeft.toString(),
//               med.refillThreshold.toString(),
//               med.expiryDate.toLocal().toString().split(' ')[0],
//             ]).toList(),
//             headers: [
//               'Name',
//               'Dosage',
//               'Total Qty',
//               'Qty Left',
//               'Refill Threshold',
//               'Expiry'
//             ],
//             border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey),
//             headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: roboto),
//             cellStyle: pw.TextStyle(fontSize: 10, font: roboto),
//             headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
//             cellAlignments: {
//               0: pw.Alignment.centerLeft,
//               1: pw.Alignment.center,
//               2: pw.Alignment.center,
//               3: pw.Alignment.center,
//               4: pw.Alignment.center,
//               5: pw.Alignment.center,
//             },
//           ),
//           pw.SizedBox(height: 20),

//           // Expiring medicines this month
//           pw.Text('Expiring Medicines This Month:',
//               style: pw.TextStyle(
//                   fontSize: 18, fontWeight: pw.FontWeight.bold, font: roboto)),
//           pw.Column(
//             children: medicines
//                 .where((med) => med.expiryDate.month == now.month)
//                 .map((med) => pw.Text(
//                     '${med.name} - ${med.expiryDate.toLocal().toString().split(' ')[0]}',
//                     style: pw.TextStyle(font: roboto)))
//                 .toList(),
//           ),
//           pw.SizedBox(height: 20),

//           // Medicine Intake Summary
//           pw.Text('Medicine Intake Summary:',
//               style: pw.TextStyle(
//                   fontSize: 18, fontWeight: pw.FontWeight.bold, font: roboto)),
//           pw.TableHelper.fromTextArray(
//             context: context,
//             headers: ['Name', 'Taken Count', 'Missed Count', 'Last Taken', 'Last Missed'],
//             data: medicines.map((med) {
//               final medHistory = history
//                   .where((h) => h.medicineName == med.name && h.date.month == now.month)
//                   .toList();
//               final takenCount = medHistory.where((h) => h.status == 'taken').length;
//               final missedCount = medHistory.where((h) => h.status == 'missed').length;
//               final lastTakenEntry = medHistory.lastWhere(
//                 (h) => h.status == 'taken',
//                 orElse: () => HistoryEntry(
//                   medicineName: '',
//                   date: DateTime(0),
//                   status: '',
//                 ),
//               );
//               final lastMissedEntry = medHistory.lastWhere(
//                 (h) => h.status == 'missed',
//                 orElse: () => HistoryEntry(
//                   medicineName: '',
//                   date: DateTime(0),
//                   status: '',
//                 ),
//               );
//               final lastTaken = lastTakenEntry?.date.toLocal().toString().split(' ')[0] ?? '-';
//               final lastMissed = lastMissedEntry?.date.toLocal().toString().split(' ')[0] ?? '-';
//               return [
//                 med.name,
//                 takenCount.toString(),
//                 missedCount.toString(),
//                 lastTaken,
//                 lastMissed,
//               ];
//             }).toList(),
//             cellStyle: pw.TextStyle(fontSize: 10, font: roboto),
//             headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: roboto),
//             border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey),
//             cellAlignments: {
//               0: pw.Alignment.centerLeft,
//               1: pw.Alignment.center,
//               2: pw.Alignment.center,
//               3: pw.Alignment.center,
//               4: pw.Alignment.center,
//             },
//           ),
//           pw.SizedBox(height: 20),

//           // Health Checkup Reminder
//           if (now.day == 1 || now.day == DateTime(now.year, now.month + 1, 0).day)
//             pw.Text('Health Checkup Reminder: It\'s time for your monthly checkup! 🩺',
//                 style: pw.TextStyle(
//                     fontSize: 16,
//                     fontWeight: pw.FontWeight.bold,
//                     color: PdfColors.red,
//                     font: roboto)),

//                     pw.SizedBox(height: 20),
//         pw.Text('Health Report Summary:',
//             style: pw.TextStyle(
//                 fontSize: 18, fontWeight: pw.FontWeight.bold, font: roboto)),

//         pw.TableHelper.fromTextArray(
//           context: context,
//           headers: ['Date', 'Status'],
//           data: healthReports.map((report) {
//             return [
//               report.reportDate.toLocal().toString().split(' ')[0],
//               report.notes, // e.g., "Good", "Needs Attention", etc.
//             ];
//           }).toList(),
//           cellStyle: pw.TextStyle(fontSize: 10, font: roboto),
//           headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: roboto),
//           border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey),
//           cellAlignments: {
//             0: pw.Alignment.center,
//             1: pw.Alignment.center,
//           },
//         ),

//         // Optional: Latest health report highlight
//         if (healthReports.isNotEmpty)
//           pw.Padding(
//             padding: const pw.EdgeInsets.only(top: 10),
//             child: pw.Text(
//                 'Latest Health Report (${healthReports.first.reportDate.toLocal().toString().split(' ')[0]}): chol - ${healthReports.first.cholesterol}, BP - ${healthReports.first.systolic}/${healthReports.first.diastolic}, Notes - ${healthReports.first.notes}',
//                 style: pw.TextStyle(
//                     fontSize: 14,
//                     fontWeight: pw.FontWeight.bold,
//                     color: PdfColors.blue,
//                     font: roboto)),
//           ),
//         ];
//       },
//     ),
//   );

//   Directory? directory;
//   if (Platform.isAndroid) {
//     directory = await getExternalStorageDirectory();
//   } else if (Platform.isIOS) {
//     directory = await getApplicationDocumentsDirectory();
//   }

//   if (directory == null) return null;

//   final filePath = '${directory.path}/Monthly_Medicine_Report_${now.month}_${now.year}.pdf';
//   final file = File(filePath);

//   await file.writeAsBytes(await pdf.save());

//   print('PDF saved at: $filePath');

//   return filePath; // Return file path for further use if needed
// // }
// import 'dart:io';
// import 'package:flutter/services.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:hive/hive.dart';
// import 'package:open_file/open_file.dart';
// import 'package:permission_handler/permission_handler.dart';
// import '../../Hivemodel/medicine.dart';
// import '../../Hivemodel/history_entry.dart';
// import '../Hivemodel/health_report.dart';

// Future<bool> requestStoragePermission() async {
//   // Request storage permission
//   var status = await Permission.storage.request();

//   if (status.isGranted) {
//     return true; // Permission granted
//   } else if (status.isDenied) {
//     // User denied, you can show a message or ask again
//     return false;
//   } else if (status.isPermanentlyDenied) {
//     // Open app settings so user can grant manually
//     openAppSettings();
//     return false;
//   }
//   return false;
// }

// Future<void> generateMonthlyReportPdf() async {
//   bool permissionGranted = await requestStoragePermission();
//   if (!permissionGranted) {
//     print("Storage permission denied. Cannot save PDF.");
//     return null;
//   }

//   final pdf = pw.Document();

//   // Load Unicode TTF font
//   final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
//   final roboto = pw.Font.ttf(fontData);

//   final medicinesBox = Hive.box<Medicine>('medicinesBox');
//   final historyBox = Hive.box<HistoryEntry>('historyBox');
//   final healthReportBox = Hive.box<HealthReport>('healthReportsBox');

//   final now = DateTime.now();
//   final medicines = medicinesBox.values.toList();
//   final history = historyBox.values.toList();
//   final healthReports = healthReportBox.values.toList()
//     ..sort((a, b) => b.reportDate.compareTo(a.reportDate));

//   pdf.addPage(
//     pw.MultiPage(
//       pageFormat: PdfPageFormat.a4,
//       build: (context) => [
//         pw.Header(
//             level: 0,
//             child: pw.Text('Monthly Medicine Report',
//                 style: pw.TextStyle(fontSize: 24, font: roboto))),
//         pw.SizedBox(height: 10),

//         // Medicine Details
//         pw.Text('Medicine Details:',
//             style: pw.TextStyle(
//                 fontSize: 18, fontWeight: pw.FontWeight.bold, font: roboto)),
//         pw.TableHelper.fromTextArray(
//           context: context,
//           headers: [
//             'Name',
//             'Dosage',
//             'Total Qty',
//             'Qty Left',
//             'Refill Threshold',
//             'Expiry'
//           ],
//           data: medicines
//               .map((med) => [
//                     med.name,
//                     med.dosage,
//                     med.totalQuantity.toString(),
//                     med.quantityLeft.toString(),
//                     med.refillThreshold.toString(),
//                     med.expiryDate.toLocal().toString().split(' ')[0],
//                   ])
//               .toList(),
//           cellStyle: pw.TextStyle(fontSize: 10, font: roboto),
//           headerStyle:
//               pw.TextStyle(fontWeight: pw.FontWeight.bold, font: roboto),
//           border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey),
//         ),
//         pw.SizedBox(height: 20),

//         // Expiring medicines
//         pw.Text('Expiring Medicines This Month:',
//             style: pw.TextStyle(
//                 fontSize: 18, fontWeight: pw.FontWeight.bold, font: roboto)),
//         pw.Column(
//           children: medicines
//               .where((med) => med.expiryDate.month == now.month)
//               .map((med) => pw.Text(
//                   '${med.name} - ${med.expiryDate.toLocal().toString().split(' ')[0]}',
//                   style: pw.TextStyle(font: roboto)))
//               .toList(),
//         ),
//         pw.SizedBox(height: 20),

//         // Medicine Intake Summary
//         pw.Text('Medicine Intake Summary:',
//             style: pw.TextStyle(
//                 fontSize: 18, fontWeight: pw.FontWeight.bold, font: roboto)),
//         pw.TableHelper.fromTextArray(
//           context: context,
//           headers: ['Name', 'Taken', 'Missed', 'Last Taken', 'Last Missed'],
//           data: medicines.map((med) {
//             final medHistory = history
//                 .where((h) =>
//                     h.medicineName == med.name && h.date.month == now.month)
//                 .toList();
//             final takenCount =
//                 medHistory.where((h) => h.status == 'taken').length;
//             final missedCount =
//                 medHistory.where((h) => h.status == 'missed').length;

//             final lastTakenEntry = medHistory.lastWhere(
//                 (h) => h.status == 'taken',
//                 orElse: () => HistoryEntry(
//                     medicineName: '', date: DateTime(0), status: ''));

//             final lastMissedEntry = medHistory.lastWhere(
//                 (h) => h.status == 'missed',
//                 orElse: () => HistoryEntry(
//                     medicineName: '', date: DateTime(0), status: ''));

//             final lastTaken = lastTakenEntry.date.year == 0
//                 ? '-'
//                 : lastTakenEntry.date.toLocal().toString().split(' ')[0];
//             final lastMissed = lastMissedEntry.date.year == 0
//                 ? '-'
//                 : lastMissedEntry.date.toLocal().toString().split(' ')[0];

//             return [
//               med.name,
//               takenCount.toString(),
//               missedCount.toString(),
//               lastTaken,
//               lastMissed,
//             ];
//           }).toList(),
//           cellStyle: pw.TextStyle(fontSize: 10, font: roboto),
//           headerStyle:
//               pw.TextStyle(fontWeight: pw.FontWeight.bold, font: roboto),
//           border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey),
//         ),
//         pw.SizedBox(height: 20),

//         // Health Reports
//         pw.Text('Health Report Summary:',
//             style: pw.TextStyle(
//                 fontSize: 18, fontWeight: pw.FontWeight.bold, font: roboto)),
//         pw.TableHelper.fromTextArray(
//           context: context,
//           headers: ['Date', 'Status'],
//           data: healthReports
//               .map((report) => [
//                     report.reportDate.toLocal().toString().split(' ')[0],
//                     report.notes,
//                   ])
//               .toList(),
//           cellStyle: pw.TextStyle(fontSize: 10, font: roboto),
//           headerStyle:
//               pw.TextStyle(fontWeight: pw.FontWeight.bold, font: roboto),
//           border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey),
//         ),
//       ],
//     ),
//   );

//   // Save PDF
//   Directory? directory;
//   if (Platform.isAndroid) {
//     directory = Directory('/storage/emulated/0/Download');
//   } else if (Platform.isIOS) {
//     directory = await getApplicationDocumentsDirectory();
//   }

//   if (directory == null) return;

//   final filePath =
//       '${directory.path}/Monthly_Medicine_Report_${now.month}_${now.year}.pdf';
//   final file = File(filePath);
//   await file.writeAsBytes(await pdf.save());

//   print('PDF saved at: $filePath');

//   // Open file safely
//   try {
//     await OpenFile.open(filePath);
//   } catch (e) {
//     print(
//         'Cannot open file automatically. Please navigate manually: $filePath');
//   }
// }
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:hive/hive.dart';
import '../../Hivemodel/medicine.dart';
import '../../Hivemodel/history_entry.dart';
import '../Hivemodel/health_report.dart';

Future<File?> generateMonthlyReportPdf() async {
  final pdf = pw.Document();

  // Load font
  final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
  final roboto = pw.Font.ttf(fontData);

  final medicinesBox = Hive.box<Medicine>('medicinesBox');
  final historyBox = Hive.box<HistoryEntry>('historyBox');
  final healthBox = Hive.box<HealthReport>('healthReportsBox');

  final now = DateTime.now();
  final medicines = medicinesBox.values.toList();
  final history = historyBox.values.toList();
  final healthReports = healthBox.values.toList()
    ..sort((a, b) => b.reportDate.compareTo(a.reportDate));

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (context) => [
        pw.Header(
          level: 0,
          child: pw.Text('Monthly Medicine Report',
              style: pw.TextStyle(fontSize: 24, font: roboto)),
        ),
        pw.SizedBox(height: 10),
        // Medicine table (simplified)
        pw.Text('Medicine Details:', style: pw.TextStyle(fontSize: 18, font: roboto)),
        pw.TableHelper.fromTextArray(
          context: context,
          headers: ['Name', 'Dosage', 'Qty Left', 'Expiry'],
          data: medicines.map((med) => [
            med.name,
            med.dosage,
            med.quantityLeft.toString(),
            med.expiryDate.toLocal().toString().split(' ')[0],
          ]).toList(),
          cellStyle: pw.TextStyle(font: roboto, fontSize: 10),
          headerStyle: pw.TextStyle(font: roboto, fontSize: 12, fontWeight: pw.FontWeight.bold),
          border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey),
        ),
        pw.SizedBox(height: 20),
        // Health report table
        pw.Text('Health Report Summary:', style: pw.TextStyle(fontSize: 18, font: roboto)),
        pw.TableHelper.fromTextArray(
          context: context,
          headers: ['Date', 'Status'],
          data: healthReports.map((hr) => [
            hr.reportDate.toLocal().toString().split(' ')[0],
            hr.notes,
          ]).toList(),
          cellStyle: pw.TextStyle(font: roboto, fontSize: 10),
          headerStyle: pw.TextStyle(font: roboto, fontSize: 12, fontWeight: pw.FontWeight.bold),
          border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey),
        ),
      ],
    ),
  );

  // Save file
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/Monthly_Medicine_Report_${now.month}_${now.year}.pdf');
  await file.writeAsBytes(await pdf.save());
  return file;
}
