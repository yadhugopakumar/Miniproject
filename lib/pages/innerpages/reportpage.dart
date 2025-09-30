import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math'; // Import for min/max functions

import '../../Hivemodel/health_report.dart';
import '../../Hivemodel/user_settings.dart';
import '../../utils/customsnackbar.dart';

// Helper function to safely parse values
double safeDoubleParse(String? value) {
  return double.tryParse(value ?? '') ?? 0;
}

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
    _syncFromSupabase(); // fetch on load
  }

  String? _getChildId() {
    try {
      final userBox = Hive.box<UserSettings>('settingsBox');

      final userSettings = userBox.get('user');

      if (userSettings == null || userSettings.childId.isEmpty) {
        _toast('Child ID not found. Set it in user settings.');
        return null;
      }

      return userSettings.childId;
    } catch (e) {
      _toast('Error retrieving Child ID: $e');
      return null;
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    AppSnackbar.show(context, message: msg, success: true);
  }

  Future<void> _addReport(HealthReport report) async {
    final childId = _getChildId();
    if (childId == null) {
      return;
    }

    setState(() => _busy = true);
    try {
      final inserted = await _supabase
          .from('health_reports')
          .insert({
            'child_id': childId,
            'report_date': report.reportDate.toIso8601String(),
            // FIX: Map report.systolic (Hive BP) to Supabase 'bloodPressure'
            'bloodPressure': report.systolic,
            // FIX: Map report.diastolic (Hive Sugar) to Supabase 'bloodSugar'
            'bloodSugar': report.diastolic,
            'cholesterol': report.cholesterol,
            'notes': report.notes,
          })
          .select()
          .single();

      final newReport = HealthReport(
        id: inserted['id'].toString(),
        childId: inserted['child_id'] as String,
        reportDate: DateTime.parse(inserted['report_date'] as String),
        // FIX: Map Supabase 'bloodPressure' back to Hive 'systolic'
        systolic: inserted['bloodPressure'] as String?,
        // FIX: Map Supabase 'bloodSugar' back to Hive 'diastolic'
        diastolic: inserted['bloodSugar'] as String?,
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
    final key = report.id; // Assuming report.id is the Hive key
    if (report.id.isEmpty) {
      _toast('Cannot update: missing report id.');
      return;
    }
    setState(() => _busy = true);
    try {
      await _supabase.from('health_reports').update({
        'report_date': report.reportDate.toIso8601String(),
        // FIX: Map report.systolic (Hive BP) to Supabase 'bloodPressure'
        'bloodPressure': report.systolic,
        // FIX: Map report.diastolic (Hive Sugar) to Supabase 'bloodSugar'
        'bloodSugar': report.diastolic,
        'cholesterol': report.cholesterol,
        'notes': report.notes,
      }).eq('id', report.id);

      await _hiveBox.put(key, report);
      _toast('Report updated');
    } catch (e) {
      _toast('Update failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteReport(String id) async {
    // Delete by ID/Key
    final report = _hiveBox.get(id);
    if (report == null) return;
    setState(() => _busy = true);
    try {
      if (report.id.isNotEmpty) {
        await _supabase.from('health_reports').delete().eq('id', report.id);
      }
      await _hiveBox.delete(id);
      _toast('Report deleted');
    } catch (e) {
      _toast('Delete failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _syncFromSupabase() async {
    final childId = _getChildId();
    if (childId == null) return;

    setState(() => _busy = true);
    try {
      final List<dynamic> rows = await _supabase
          .from('health_reports')
          .select()
          .eq('child_id', childId)
          .order('report_date', ascending: true);

      for (final row in rows) {
        final id = row['id'].toString();
        final newReport = HealthReport(
          id: id,
          childId: row['child_id'] as String,
          reportDate: DateTime.parse(row['report_date'] as String),
          // FIX: Map Supabase 'bloodPressure' back to Hive 'systolic'
          systolic: row['bloodPressure'] as String?,
          // FIX: Map Supabase 'bloodSugar' back to Hive 'diastolic'
          diastolic: row['bloodSugar'] as String?,
          cholesterol: row['cholesterol'] as String?,
          notes: row['notes'] as String,
        );

        await _hiveBox.put(id, newReport);
      }
      _toast('Sync successful!');
    } catch (e) {
      _toast('Sync failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showReportForm({HealthReport? toEdit, int? index}) {
    final formKey = GlobalKey<FormState>();
    // FIX: Use correct confusing but functional Hive fields for initialization
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
                // FIX: Clear labels for user clarity on the input fields
                _numField(
                    controller: systolicCtrl, label: 'Systolic BP (mmHg)'),
                _numField(
                    controller: diastolicCtrl, label: 'Blood Sugar (mg/dL)'),
                _numField(controller: cholCtrl, label: 'Cholesterol (mg/dL)'),
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

              // Note: No combining needed, the form fields are treated as raw values.

              final report = HealthReport(
                childId: _getChildId() ?? '',
                reportDate: toEdit?.reportDate ?? DateTime.now(),
                id: toEdit?.id ?? '',
                systolic: systolicCtrl.text.trim(), // Stored as BP
                diastolic: diastolicCtrl.text.trim(), // Stored as Sugar
                cholesterol: cholCtrl.text.trim(),
                notes: notesCtrl.text.trim(),
              );

              if (toEdit == null) {
                await _addReport(report);
              } else {
                // We no longer need the index argument in _updateReport
                await _updateReport(report, 0);
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

        // FIX: Update validation logic to match the clear labels
        if (label.contains('Systolic BP') && (n < 70 || n > 200)) {
          return 'Systolic BP should be 70-200';
        }
        // NOTE: The next line validates Blood Sugar, which is stored in diastolic field
        if (label.contains('Blood Sugar') && (n < 40 || n > 300)) {
          return 'Blood Sugar should be 40-300';
        }
        if (label.contains('Cholesterol') && (n < 80 || n > 400)) {
          return 'Cholesterol should be 80-400';
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
            width: 10,
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
      body: RefreshIndicator(
        onRefresh: _syncFromSupabase,
        child: ValueListenableBuilder(
          valueListenable: _hiveBox.listenable(),
          builder: (context, Box<HealthReport> box, _) {
            final reports = box.values.toList().cast<HealthReport>()
              ..sort((a, b) => b.reportDate.compareTo(a.reportDate));

            final reportsForChart = reports.reversed.toList();

            // --- CHART DATA PREPARATION (Same as before) ---
            List<double> systolicValues = reportsForChart
                .map((r) => safeDoubleParse(r.systolic))
                .toList();
            List<double> bloodSugarValues = reportsForChart
                .map((r) => safeDoubleParse(r.diastolic))
                .toList();
            List<double> cholesterolValues = reportsForChart
                .map((r) => safeDoubleParse(r.cholesterol))
                .toList();

            final allValues = [
              ...systolicValues,
              ...bloodSugarValues,
              ...cholesterolValues,
            ].where((v) => v > 0).toList();

            final effectiveMaxY = allValues.isNotEmpty
                ? (allValues.reduce(max) * 1.1).ceilToDouble()
                : 120.0;
            final interval = (effectiveMaxY / 5).ceilToDouble();
            // --- END CHART DATA PREPARATION ---

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: reports.isEmpty
                  ? const Center(
                      child: Text("No health reports yet. Tap '+' to add one.",
                          style: TextStyle(fontSize: 16)),
                    )
                  // FIX: Wrap the main Column in a SingleChildScrollView
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          // Chart Section (Fixed Height)
                          SizedBox(
                            height: 280,
                            child: Card(
                              color: Colors.green[50],
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(8, 16, 16, 8),
                                child: LineChart(
                                  LineChartData(
                                    minY: 0,
                                    maxY: effectiveMaxY,
                                    titlesData: FlTitlesData(
                                      // ... (titlesData configuration) ...
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          interval: 1,
                                          getTitlesWidget: (value, meta) {
                                            final i = value.toInt();
                                            if (i < 0 ||
                                                i >= reportsForChart.length) {
                                              return const SizedBox.shrink();
                                            }
                                            final d =
                                                reportsForChart[i].reportDate;
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 4.0),
                                              child: Text('${d.day}/${d.month}',
                                                  style: const TextStyle(
                                                      fontSize: 10)),
                                            );
                                          },
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                            showTitles: true,
                                            interval: interval,
                                            reservedSize: 36),
                                      ),
                                      topTitles: const AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                      rightTitles: const AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                    ),
                                    gridData: FlGridData(
                                      show: true,
                                      horizontalInterval: interval,
                                    ),
                                    borderData: FlBorderData(show: true),
                                    lineBarsData: [
                                      // 1. Systolic BP (Red)
                                      LineChartBarData(
                                        spots: _spotsFor(systolicValues),
                                        isCurved: true,
                                        color: Colors.red,
                                        barWidth: 2,
                                        dotData: FlDotData(
                                            show: true,
                                            checkToShowDot: (spot, barData) =>
                                                spot.y > 0),
                                      ),
                                      // 2. Blood Sugar (Blue)
                                      LineChartBarData(
                                        spots: _spotsFor(bloodSugarValues),
                                        isCurved: true,
                                        color: Colors.blue,
                                        barWidth: 2,
                                        dotData: FlDotData(
                                            show: true,
                                            checkToShowDot: (spot, barData) =>
                                                spot.y > 0),
                                      ),
                                      // 3. Cholesterol (Green)
                                      LineChartBarData(
                                        spots: _spotsFor(cholesterolValues),
                                        isCurved: true,
                                        color: Colors.green,
                                        barWidth: 2,
                                        dotData: FlDotData(
                                            show: true,
                                            checkToShowDot: (spot, barData) =>
                                                spot.y > 0),
                                      ),
                                    ],
                                    lineTouchData: LineTouchData(
                                      enabled: true,
                                      touchTooltipData: LineTouchTooltipData(
                                        tooltipBgColor: Colors.black87,
                                        tooltipHorizontalAlignment:
                                            FLHorizontalAlignment.left,
                                        fitInsideHorizontally: true,
                                        tooltipMargin: -200,
                                        getTooltipItems: (touchedSpots) {
                                          return touchedSpots.map((spot) {
                                            final label =
                                                switch (spot.barIndex) {
                                              0 => 'Systolic BP',
                                              1 => 'Blood Sugar',
                                              2 => 'Cholesterol',
                                              _ => 'Value',
                                            };
                                            final unit =
                                                switch (spot.barIndex) {
                                              0 => 'mmHg',
                                              1 || 2 => 'mg/dL',
                                              _ => '',
                                            };
                                            return LineTooltipItem(
                                              '$label: ${spot.y.toInt()} $unit',
                                              const TextStyle(
                                                  fontSize: 10,
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
                          // Legend
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _legendItem(Colors.red, 'BP (mmHg)'),
                                _legendItem(Colors.blue, 'Blood Sugar (mg/dL)'),
                                _legendItem(
                                    Colors.green, 'Cholesterol (mg/dL)'),
                              ],
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            child: Text("Past Health Reports:",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                          ),

                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 80.0),
                            itemCount: reports.length,

                            itemBuilder: (context, i) {
                              final r = reports[i];
                              return Card(
                                color: Colors
                                    .white, // Use white for better contrast
                                margin:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(
                                      color: Colors.green,
                                      width: 1), // Highlight card
                                ),
                                child: Padding(
                                    padding: const EdgeInsets.all(11.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // --- 1. HEALTH METRICS ROW (Uncongested) ---
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.favorite_border,
                                                color: Colors.red, size: 20),
                                            const SizedBox(width: 12),

                                            // BP (Systolic)
                                            Expanded(
                                              child: _buildDataPill(
                                                label: "BP (S)",
                                                value: "${r.systolic} mmHg",
                                                color: Colors.red,
                                              ),
                                            ),
                                            const SizedBox(width: 8),

                                            // Blood Sugar
                                            Expanded(
                                              child: _buildDataPill(
                                                label: "Sugar",
                                                value: "${r.diastolic} mg/dL",
                                                color: Colors.blue,
                                              ),
                                            ),
                                            const SizedBox(width: 8),

                                            // Cholesterol
                                            Expanded(
                                              child: _buildDataPill(
                                                label: "Chol",
                                                value: "${r.cholesterol} mg/dL",
                                                color: Colors.green,
                                              ),
                                            ),
                                          ],
                                        ),

                                        const Divider(
                                            height: 20,
                                            thickness: 1,
                                            color: Colors.grey),

                                        // --- 2. NOTES AND DATE ---
                                        const SizedBox(height: 1),
                                        Text(
                                          "Date: ${r.reportDate.toLocal().toString().substring(0, 16)}",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 3),

                                        Text(
                                          r.notes,
                                          style: const TextStyle(
                                            fontStyle: FontStyle.italic,
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),

                                        // --- 3. ACTIONS ROW ---
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            // EDIT Button (Primary action)
                                            TextButton.icon(
                                              onPressed: _busy
                                                  ? null
                                                  : () => _showReportForm(
                                                      toEdit: r),
                                              icon: const Icon(Icons.edit,
                                                  size: 20),
                                              label: const Text('Edit'),
                                              style: TextButton.styleFrom(
                                                  foregroundColor: Colors.blue),
                                            ),

                                            // DELETE Button (Secondary action)
                                            IconButton(
                                              icon: const Icon(Icons.delete,
                                                  color: Colors.red),
                                              tooltip: "Delete",
                                              onPressed: _busy
                                                  ? null
                                                  : () => showDialog(
                                                        context: context,
                                                        builder: (_) =>
                                                            AlertDialog(
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
                                                              onPressed:
                                                                  () async {
                                                                Navigator.pop(
                                                                    context);
                                                                await _deleteReport(
                                                                    r.id);
                                                              },
                                                              child: const Text(
                                                                  'Delete',
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .red)),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    )),
                              );
                            },
// ...
                          ),
                        ],
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDataPill(
      {required String label, required String value, required Color color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
