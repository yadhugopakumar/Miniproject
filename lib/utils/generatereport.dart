import 'dart:io';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../../Hivemodel/medicine.dart';
import '../../Hivemodel/history_entry.dart';
import '../../Hivemodel/health_report.dart';

Future<File?> generateMonthlyReportPdf({required DateTime selectedMonth}) async {
  final pdf = pw.Document();

  // Load Roboto font
  final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
  final roboto = pw.Font.ttf(fontData);

  final medicinesBox = Hive.box<Medicine>('medicinesBox');
  final historyBox = Hive.box<HistoryEntry>('historyBox');
  final healthBox = Hive.box<HealthReport>('healthReportsBox');

  final monthName = DateFormat.MMMM().format(selectedMonth);
  final medicines = medicinesBox.values.toList();
  final healthReports = healthBox.values.toList()
    ..sort((a, b) => b.reportDate.compareTo(a.reportDate));

  // --- Medicine Intake Summary ---
  final historySummary = medicines.map((med) {
    final medHistory = historyBox.values.where((h) =>
        h.medicineName.contains(med.name) &&
        h.date.month == selectedMonth.month &&
        h.date.year == selectedMonth.year).toList();

    final takenEntries = medHistory.where((h) => h.status.toLowerCase() == 'taken').toList();
    final skippedEntries = medHistory.where((h) => h.status.toLowerCase() == 'skipped').toList();

    // Latest taken date
    final latelyTakenDate = takenEntries.isNotEmpty
        ? takenEntries.map((e) => e.date).reduce((a, b) => a.isAfter(b) ? a : b)
        : null;

    // Count of taken on latest date
    final latelyTakenCount = latelyTakenDate != null
        ? takenEntries
            .where((e) =>
                e.date.year == latelyTakenDate.year &&
                e.date.month == latelyTakenDate.month &&
                e.date.day == latelyTakenDate.day)
            .length
        : 0;

    final latelyTaken = latelyTakenDate != null
        ? '$latelyTakenCount times (recent: ${DateFormat('dd MMM').format(latelyTakenDate)})'
        : '-';

    final takenCount = takenEntries.length;
    final missedCount = skippedEntries.length;

    // Most recent action (taken or skipped)
    final recentActionDate = medHistory.isNotEmpty
        ? medHistory.map((e) => e.date).reduce((a, b) => a.isAfter(b) ? a : b)
        : null;
    final recentAction = recentActionDate != null
        ? DateFormat('dd MMM').format(recentActionDate)
        : '-';

    return [
      med.name,
      latelyTaken,
      takenCount.toString(),
      missedCount.toString(),
      recentAction
    ];
  }).toList();

  // --- Expiring Medicines ---
  final expiringMedicines = medicines
      .where((med) => med.expiryDate.isBefore(selectedMonth.add(Duration(days: 30))))
      .map((med) => [
            med.name,
            med.dosage,
            med.quantityLeft.toString(),
            DateFormat('dd MMM yyyy').format(med.expiryDate),
            med.instructions ?? '-',
          ])
      .toList();

  // --- Last 3 Health Reports ---
  final recentHealthReports = healthReports
      .take(3)
      .map((hr) => [
            DateFormat('dd MMM yyyy').format(hr.reportDate),
            hr.notes,
            hr.systolic ?? '-',
            hr.diastolic ?? '-',
            hr.cholesterol ?? '-',
          ])
      .toList();

  // --- Build PDF ---
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (context) => [
        pw.Center(
          child: pw.Text(
            'Monthly Report - $monthName',
            style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, font: roboto),
          ),
        ),
        pw.SizedBox(height: 20),

        // Medicine Intake Summary
        pw.Text('Medicine Intake Summary:',
            style: pw.TextStyle(fontSize: 18, font: roboto)),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: ['Medicine', 'Lately Taken', 'Taken Count', 'Missed Count', 'Recent Action'],
          data: historySummary,
          headerStyle: pw.TextStyle(font: roboto, fontSize: 12, fontWeight: pw.FontWeight.bold),
          cellStyle: pw.TextStyle(font: roboto, fontSize: 10),
          border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey),
        ),
        pw.SizedBox(height: 20),

        // Expiring Medicines
        if (expiringMedicines.isNotEmpty) ...[
          pw.Text('Expiring Medicines (Next 30 Days):',
              style: pw.TextStyle(fontSize: 18, font: roboto)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: ['Name', 'Dosage', 'Qty Left', 'Expiry', 'Instructions'],
            data: expiringMedicines,
            headerStyle: pw.TextStyle(font: roboto, fontSize: 12, fontWeight: pw.FontWeight.bold),
            cellStyle: pw.TextStyle(font: roboto, fontSize: 10),
            border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey),
          ),
          pw.SizedBox(height: 20),
        ],

        // Last 3 Health Reports
        pw.Text('Recent Health Reports:',
            style: pw.TextStyle(fontSize: 18, font: roboto)),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: ['Date', 'Notes', 'Systolic', 'Diastolic', 'Cholesterol'],
          data: recentHealthReports,
          headerStyle: pw.TextStyle(font: roboto, fontSize: 12, fontWeight: pw.FontWeight.bold),
          cellStyle: pw.TextStyle(font: roboto, fontSize: 10),
          border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey),
        ),
      ],
    ),
  );

  // Save PDF
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/Monthly_Medicine_Report_${selectedMonth.month}_${selectedMonth.year}.pdf');
  await file.writeAsBytes(await pdf.save());
  return file;
}
