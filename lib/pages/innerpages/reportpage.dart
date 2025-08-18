// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:hive_flutter/adapters.dart';
// import 'package:medremind/Hivemodel/user_settings.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import '../../Hivemodel/health_report.dart';

// class Reportspage extends StatefulWidget {
//   const Reportspage({super.key});
//   @override
//   State<Reportspage> createState() => _ReportspageState();
// }

// class _ReportspageState extends State<Reportspage> {
//   late Box<HealthReport> hiveBox;

//   @override
//   void initState() {
//     super.initState();
//     hiveBox = Hive.box<HealthReport>('healthReportsBox');
//   }

//   @override
//   void dispose() {
//     hiveBox.close();
//     super.dispose();
//   }

//   // Add or update a report in Hive
//   // Future<void> _saveReport(
//   //     {HealthReport? toEdit, int? index, required HealthReport report}) async {
//   //   if (toEdit == null) {
//   //     await hiveBox.add(report);
//   //   } else if (index != null) {
//   //     final key = hiveBox.keyAt(index);
//   //     await hiveBox.put(key, report);
//   //   }
//   //   setState(() {}); // re-render, ValueListenableBuilder will also update UI
//   // }
//   Future<void> addHealthReport( HealthReport report) async {
//     final hiveBox = Hive.box<HealthReport>('healthReportsBox');
//     final userbox = Hive.box<UserSettings>('userSettingsBox');
//     final childId = userbox.get('childId');

//     final supabase = Supabase.instance.client;
//     // Insert into Supabase
//     final response = await supabase
//         .from('health_reports')
//         .insert({
//           'child_id': childId,
//           'report_date': report.date.toIso8601String(),
//           'systolic': report.systolic,
//           'diastolic': report.diastolic,
//           'cholesterol': report.cholesterol,
//           'notes': report.notes,
//         })
//         .select()
//         .single();

//     if (response == null) {
//       // Save in Hive with id from Supabase
//       report.id = response['id'].toString();
//       hiveBox.add(report);
//     }
//   }

//   // Delete a report from Hive
//   Future<void> _deleteReport(int index) async {
//     final key = hiveBox.keyAt(index);
//     await hiveBox.delete(key);
//     setState(() {});
//   }

//   void _showReportForm({HealthReport? toEdit, int? index}) async {
//     final _formKey = GlobalKey<FormState>();
//     final systolicCtrl =
//         TextEditingController(text: toEdit?.systolic.toString() ?? '');
//     final diastolicCtrl =
//         TextEditingController(text: toEdit?.diastolic.toString() ?? '');
//     final cholCtrl =
//         TextEditingController(text: toEdit?.cholesterol.toString() ?? '');
//     final notesCtrl = TextEditingController(text: toEdit?.notes ?? '');

//     await showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(
//             toEdit == null ? 'Add New Health Report' : 'Edit Health Report'),
//         content: SingleChildScrollView(
//           child: Form(
//             key: _formKey,
//             child: Column(
//               children: [
//                 TextFormField(
//                   controller: systolicCtrl,
//                   decoration: const InputDecoration(labelText: 'Systolic BP'),
//                   keyboardType: TextInputType.number,
//                   validator: (val) =>
//                       (val == null || val.isEmpty) ? 'Required' : null,
//                 ),
//                 TextFormField(
//                   controller: diastolicCtrl,
//                   decoration: const InputDecoration(labelText: 'Diastolic BP'),
//                   keyboardType: TextInputType.number,
//                   validator: (val) =>
//                       (val == null || val.isEmpty) ? 'Required' : null,
//                 ),
//                 TextFormField(
//                   controller: cholCtrl,
//                   decoration: const InputDecoration(labelText: 'Cholesterol'),
//                   keyboardType: TextInputType.number,
//                   validator: (val) =>
//                       (val == null || val.isEmpty) ? 'Required' : null,
//                 ),
//                 TextFormField(
//                   controller: notesCtrl,
//                   decoration: const InputDecoration(labelText: 'Notes'),
//                   maxLines: 2,
//                   validator: (val) =>
//                       (val == null || val.isEmpty) ? 'Required' : null,
//                 ),
//               ],
//             ),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               if (_formKey.currentState!.validate()) {
//                 final report = HealthReport(

//                   date: toEdit?.date ?? DateTime.now(),
//                   systolic: int.parse(systolicCtrl.text),
//                   diastolic: int.parse(diastolicCtrl.text),
//                   cholesterol: int.parse(cholCtrl.text),
//                   notes: notesCtrl.text,
//                 );
//                 addHealthReport(report.id);
//                 Navigator.pop(context);
//               }
//             },
//             child: Text(toEdit == null ? 'Add' : 'Save'),
//           ),
//         ],
//       ),
//     );
//   }

//   List<FlSpot> _spotsFor(List<int> values) {
//     return List.generate(values.length, (i) {
//       return FlSpot(i.toDouble(), values[i].toDouble());
//     });
//   }

//   void _confirmDelete(int index) {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text('Delete Report'),
//         content:
//             const Text('Are you sure you want to delete this health report?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () {
//               _deleteReport(index);
//               Navigator.pop(ctx);
//             },
//             child: const Text('Delete', style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _legendItem(Color color, String label) {
//     return Row(
//       children: [
//         Container(
//           width: 14,
//           height: 14,
//           decoration: BoxDecoration(
//             color: color,
//             shape: BoxShape.circle,
//           ),
//         ),
//         const SizedBox(width: 6),
//         Text(label, style: const TextStyle(fontSize: 13)),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.green[800],
//         title: const Text(
//           "Health Tracker",
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//       ),
//       floatingActionButton: FloatingActionButton(
//         backgroundColor: Colors.redAccent,
//         child: const Icon(Icons.add),
//         onPressed: () => _showReportForm(),
//         tooltip: "Add New Report",
//       ),
//       body: ValueListenableBuilder(
//         valueListenable: hiveBox.listenable(),
//         builder: (context, Box<HealthReport> box, _) {
//           final reports = box.values.toList();
//           return Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: reports.isEmpty
//                 ? const Center(
//                     child: Text("No health reports yet.",
//                         style: TextStyle(fontSize: 16)))
//                 : Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Trend Chart
//                       const SizedBox(
//                         height: 18,
//                       ),
//                       SizedBox(
//                         height: 250,
//                         child: Card(
//                           color: Colors.green[50],
//                           elevation: 2,
//                           margin: const EdgeInsets.only(bottom: 20),
//                           child: Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: LineChart(
//                               LineChartData(
//                                 titlesData: FlTitlesData(
//                                   bottomTitles: AxisTitles(
//                                     sideTitles: SideTitles(
//                                       showTitles: true,
//                                       getTitlesWidget: (value, meta) {
//                                         int index = value.toInt();
//                                         if (index < 0 ||
//                                             index >= reports.length) {
//                                           return Container();
//                                         }
//                                         final date = reports[index].date;
//                                         return Text(
//                                           "${date.day}/${date.month}",
//                                           style: const TextStyle(fontSize: 10),
//                                         );
//                                       },
//                                     ),
//                                   ),
//                                   leftTitles: const AxisTitles(
//                                     sideTitles: SideTitles(
//                                       showTitles: true,
//                                       interval: 20,
//                                       reservedSize: 35,
//                                     ),
//                                   ),
//                                   topTitles: AxisTitles(
//                                     sideTitles: SideTitles(showTitles: false),
//                                   ),
//                                   rightTitles: AxisTitles(
//                                     sideTitles: SideTitles(showTitles: false),
//                                   ),
//                                 ),
//                                 borderData: FlBorderData(show: true),
//                                 lineBarsData: [
//                                   LineChartBarData(
//                                     spots: _spotsFor(reports
//                                         .map((e) => e.systolic)
//                                         .toList()),
//                                     isCurved: true,
//                                     color: Colors.red,
//                                     barWidth: 3,
//                                     dotData: FlDotData(show: true),
//                                   ),
//                                   LineChartBarData(
//                                     spots: _spotsFor(reports
//                                         .map((e) => e.diastolic)
//                                         .toList()),
//                                     isCurved: true,
//                                     color: Colors.blue,
//                                     barWidth: 3,
//                                     dotData: FlDotData(show: true),
//                                   ),
//                                   LineChartBarData(
//                                     spots: _spotsFor(reports
//                                         .map((e) => e.cholesterol)
//                                         .toList()),
//                                     isCurved: true,
//                                     color: Colors.green,
//                                     barWidth: 3,
//                                     dotData: FlDotData(show: true),
//                                   ),
//                                 ],
//                                 lineTouchData: LineTouchData(
//                                   enabled: true,
//                                   touchTooltipData: LineTouchTooltipData(
//                                     tooltipBgColor: Colors.black87,
//                                     tooltipRoundedRadius: 8,
//                                     tooltipMargin:
//                                         16, // Increase for more spacing below/above marker
//                                     fitInsideHorizontally: true,
//                                     fitInsideVertically: true,
//                                     getTooltipItems: (touchedSpots) {
//                                       return touchedSpots.map((spot) {
//                                         String label;
//                                         if (spot.barIndex == 0) {
//                                           label = 'Systolic BP';
//                                         } else if (spot.barIndex == 1) {
//                                           label = 'Diastolic BP';
//                                         } else if (spot.barIndex == 2) {
//                                           label = 'Cholesterol';
//                                         } else {
//                                           label = 'Value';
//                                         }

//                                         return LineTooltipItem(
//                                           '$label: ${spot.y.toInt()}',
//                                           const TextStyle(
//                                             color: Colors.white,
//                                             fontWeight: FontWeight.bold,
//                                           ),
//                                         );
//                                       }).toList();
//                                     },
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                       Padding(
//                           padding: const EdgeInsets.symmetric(vertical: 12.0),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               _legendItem(Colors.red, 'Systolic BP'),
//                               const SizedBox(width: 16),
//                               _legendItem(Colors.blue, 'Diastolic BP'),
//                               const SizedBox(width: 16),
//                               _legendItem(Colors.green, 'Cholesterol'),
//                             ],
//                           )),
//                       Padding(
//                         padding: const EdgeInsets.symmetric(vertical: 10.0),
//                         child: const Text("Past Health Reports:",
//                             style: TextStyle(
//                                 fontSize: 18, fontWeight: FontWeight.bold)),
//                       ),
//                       Expanded(
//                         child: ListView.builder(
//                           itemCount: reports.length,
//                           itemBuilder: (context, i) {
//                             final report = reports[i];
//                             return Card(
//                               color: Colors.green[50],
//                               margin: const EdgeInsets.symmetric(vertical: 6),
//                               child: ListTile(
//                                 leading: const Icon(Icons.assignment_outlined,
//                                     color: Colors.red),
//                                 title: Text(
//                                   "BP: ${report.systolic}/${report.diastolic} | Chol: ${report.cholesterol}",
//                                   style: const TextStyle(
//                                       fontWeight: FontWeight.bold),
//                                 ),
//                                 subtitle: Text(
//                                     "${report.notes}\n${report.date.toLocal().toString().substring(0, 16)}"),
//                                 trailing: Row(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     IconButton(
//                                       icon: const Icon(Icons.edit,
//                                           color: Colors.blue),
//                                       tooltip: "Edit",
//                                       onPressed: () => _showReportForm(
//                                           toEdit: report, index: i),
//                                     ),
//                                     IconButton(
//                                       icon: const Icon(Icons.delete,
//                                           color: Colors.red),
//                                       tooltip: "Delete",
//                                       onPressed: () => _confirmDelete(i),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//           );
//         },
//       ),
//     );
//   }
//
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../Hivemodel/health_report.dart';
import '../../Hivemodel/user_settings.dart';

class Reportspage extends StatefulWidget {
  const Reportspage({super.key});
  @override
  State<Reportspage> createState() => _ReportspageState();
}

class _ReportspageState extends State<Reportspage> {
  late final Box<HealthReport> _hiveBox;
  final _supabase = Supabase.instance.client;
  final session = Hive.box('session');

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _hiveBox = Hive.box<HealthReport>('healthReportsBox');
  }

  String? _getChildId() {
    try {
      final String Id = session.get('childId');
      if (Id.isNotEmpty) return Id;
      _toast('Child ID not found. Set it in user settings.');
    } catch (_) {}
    return null;
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _addReport(HealthReport report) async {
    final childId = _getChildId();
    if (childId == null) {
      _toast('Child ID not found. Set it in user settings.');
      return;
    }
    setState(() => _busy = true);
    try {
      final inserted = await _supabase
          .from('health_reports')
          .insert({
            'child_id': childId,
            'report_date': report.reportDate.toIso8601String(),
            'systolic': report.systolic,
            'diastolic': report.diastolic,
            'cholesterol': report.cholesterol,
            'notes': report.notes,
          })
          .select()
          .single();

      final newReport = HealthReport(
        id: inserted['id'].toString(),
        childId: inserted['child_id'] as String,
        reportDate: DateTime.parse(inserted['report_date'] as String),
        systolic: inserted['systolic'] as String?,
        diastolic: inserted['diastolic'] as String?,
        cholesterol: inserted['cholesterol'] as String?,
        notes: inserted['notes'] as String,
      );

      await _hiveBox.put(newReport.id, newReport);
      _toast('Report saved locally & synced with Supabase');
    } catch (e) {
      _toast('Error inserting health report: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _updateReport(HealthReport report, int index) async {
    if (report.id.isEmpty) {
      _toast('Cannot update: missing report id.');
      return;
    }
    setState(() => _busy = true);
    try {
      await _supabase.from('health_reports').update({
        'report_date': report.reportDate.toIso8601String(),
        'systolic': report.systolic,
        'diastolic': report.diastolic,
        'cholesterol': report.cholesterol,
        'notes': report.notes,
      }).eq('id', report.id);

      final key = _hiveBox.keyAt(index);
      await _hiveBox.put(key, report);
      _toast('Report updated');
    } catch (e) {
      _toast('Update failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteReport(int index) async {
    final report = _hiveBox.getAt(index);
    if (report == null) return;
    setState(() => _busy = true);
    try {
      if (report.id.isNotEmpty) {
        await _supabase.from('health_reports').delete().eq('id', report.id);
      }
      final key = _hiveBox.keyAt(index);
      await _hiveBox.delete(key);
      _toast('Report deleted');
    } catch (e) {
      _toast('Delete failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _syncFromSupabase() async {
    final childId = _getChildId();
    if (childId == null) {
      _toast('Child ID not found. Set it in user settings.');
      return;
    }
    setState(() => _busy = true);
    try {
      final List<dynamic> rows = await _supabase
          .from('health_reports')
          .select()
          .eq('child_id', childId)
          .order('report_date', ascending: true);

      await _hiveBox.clear();

      for (final row in rows) {
        final r = HealthReport(
          id: row['id'].toString(),
          childId: row['child_id'] as String,
          reportDate: DateTime.parse(row['report_date'] as String),
          systolic: row['systolic'] as String?,
          diastolic: row['diastolic'] as String?,
          cholesterol: row['cholesterol'] as String?,
          notes: row['notes'] as String,
        );
        await _hiveBox.put(r.id, r);
      }
      _toast('Synced from cloud');
    } catch (e) {
      _toast('Sync failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showReportForm({HealthReport? toEdit, int? index}) {
    final formKey = GlobalKey<FormState>();
    final systolicCtrl = TextEditingController(text: toEdit?.systolic ?? '');
    final diastolicCtrl = TextEditingController(text: toEdit?.diastolic ?? '');
    final cholCtrl = TextEditingController(text: toEdit?.cholesterol ?? '');
    final notesCtrl = TextEditingController(text: toEdit?.notes ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            toEdit == null ? 'Add New Health Report' : 'Edit Health Report'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _numField(controller: systolicCtrl, label: 'Systolic BP'),
                _numField(controller: diastolicCtrl, label: 'Diastolic BP'),
                _numField(controller: cholCtrl, label: 'Cholesterol'),
                TextFormField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 2,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final report = HealthReport(
                childId: _getChildId() ?? '',
                reportDate: toEdit?.reportDate ?? DateTime.now(),
                id: toEdit?.id ?? '',
                systolic: systolicCtrl.text,
                diastolic: diastolicCtrl.text,
                cholesterol: cholCtrl.text,
                notes: notesCtrl.text.trim(),
              );

              if (toEdit == null) {
                await _addReport(report);
              } else if (index != null) {
                await _updateReport(report, index);
              }
              if (mounted) Navigator.pop(context);
            },
            child: Text(toEdit == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  Widget _numField(
      {required TextEditingController controller, required String label}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Required';
        final n = int.tryParse(v.trim());
        if (n == null) return 'Enter a number';
        if (label.contains('Systolic') && (n < 70 || n > 250)) {
          return 'Out of range';
        }
        if (label.contains('Diastolic') && (n < 40 || n > 150)) {
          return 'Out of range';
        }
        if (label.contains('Cholesterol') && (n < 80 || n > 400)) {
          return 'Out of range';
        }
        return null;
      },
    );
  }

  List<FlSpot> _spotsFor(List<double> values) {
    return List.generate(values.length, (i) => FlSpot(i.toDouble(), values[i]));
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Tracker',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Sync from cloud',
            onPressed: _busy ? null : _syncFromSupabase,
            icon: const Icon(Icons.refresh),
          ),
        ],
        backgroundColor: Colors.green[800],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.redAccent,
        onPressed: _busy ? null : () => _showReportForm(),
        tooltip: "Add New Report",
        child: _busy
            ? const CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white)
            : const Icon(Icons.add),
      ),
      body: ValueListenableBuilder(
        valueListenable: _hiveBox.listenable(),
        builder: (context, Box<HealthReport> box, _) {
          final reports = box.values.toList();

          // Convert nullable string readings to doubles with fallback
          List<double> systolicValues = reports
              .map((r) => double.tryParse(r.systolic ?? '') ?? 0)
              .toList();
          List<double> diastolicValues = reports
              .map((r) => double.tryParse(r.diastolic ?? '') ?? 0)
              .toList();
          List<double> cholesterolValues = reports
              .map((r) => double.tryParse(r.cholesterol ?? '') ?? 0)
              .toList();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: reports.isEmpty
                ? const Center(
                    child: Text("No health reports yet.",
                        style: TextStyle(fontSize: 16)),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 260,
                        child: Card(
                          color: Colors.green[50],
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: LineChart(
                              LineChartData(
                                minY: 0,
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: 1,
                                      getTitlesWidget: (value, meta) {
                                        final i = value.toInt();
                                        if (i < 0 || i >= reports.length) {
                                          return const SizedBox.shrink();
                                        }
                                        final d = reports[i].reportDate;
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4.0),
                                          child: Text('${d.day}/${d.month}',
                                              style: const TextStyle(
                                                  fontSize: 10)),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: const AxisTitles(
                                    sideTitles: SideTitles(
                                        showTitles: true,
                                        interval: 20,
                                        reservedSize: 36),
                                  ),
                                  topTitles: const AxisTitles(
                                      sideTitles:
                                          SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(
                                      sideTitles:
                                          SideTitles(showTitles: false)),
                                ),
                                gridData: const FlGridData(
                                  show: true,
                                  horizontalInterval: 20,
                                ),
                                borderData: FlBorderData(show: true),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: _spotsFor(systolicValues),
                                    isCurved: true,
                                    color: Colors.red,
                                    barWidth: 3,
                                    dotData: FlDotData(show: true),
                                  ),
                                  LineChartBarData(
                                    spots: _spotsFor(diastolicValues),
                                    isCurved: true,
                                    color: Colors.blue,
                                    barWidth: 3,
                                    dotData: FlDotData(show: true),
                                  ),
                                  LineChartBarData(
                                    spots: _spotsFor(cholesterolValues),
                                    isCurved: true,
                                    color: Colors.green,
                                    barWidth: 3,
                                    dotData: FlDotData(show: true),
                                  ),
                                ],
                                lineTouchData: LineTouchData(
                                  enabled: true,
                                  touchTooltipData: LineTouchTooltipData(
                                    tooltipBgColor: Colors.black87,
                                    getTooltipItems: (touchedSpots) {
                                      return touchedSpots.map((spot) {
                                        final label = switch (spot.barIndex) {
                                          0 => 'Systolic BP',
                                          1 => 'Diastolic BP',
                                          2 => 'Cholesterol',
                                          _ => 'Value',
                                        };
                                        return LineTooltipItem(
                                          '$label: ${spot.y.toInt()}',
                                          const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        );
                                      }).toList();
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _legendItem(Colors.red, 'Systolic BP'),
                            const SizedBox(width: 16),
                            _legendItem(Colors.blue, 'Diastolic BP'),
                            const SizedBox(width: 16),
                            _legendItem(Colors.green, 'Cholesterol'),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text("Past Health Reports:",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: reports.length,
                          itemBuilder: (context, i) {
                            final r = reports[i];
                            return Card(
                              color: Colors.green[50],
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                leading: const Icon(Icons.assignment_outlined,
                                    color: Colors.red),
                                title: Text(
                                  "BP: ${r.systolic}/${r.diastolic} | Chol: ${r.cholesterol}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                    "${r.notes}\n${r.reportDate.toLocal().toString().substring(0, 16)}"),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue),
                                      tooltip: "Edit",
                                      onPressed: _busy
                                          ? null
                                          : () => _showReportForm(
                                              toEdit: r, index: i),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      tooltip: "Delete",
                                      onPressed: _busy
                                          ? null
                                          : () => showDialog(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  title: const Text(
                                                      'Delete Report'),
                                                  content: const Text(
                                                      'Are you sure you want to delete this report?'),
                                                  actions: [
                                                    TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context),
                                                        child: const Text(
                                                            'Cancel')),
                                                    TextButton(
                                                      onPressed: () async {
                                                        Navigator.pop(context);
                                                        await _deleteReport(i);
                                                      },
                                                      child: const Text(
                                                          'Delete',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.red)),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}
