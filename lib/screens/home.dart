import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/calc.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime? dutyDate;
  TimeOfDay? fromTime;
  TimeOfDay? toTime;
  final basicPayController = TextEditingController();
  final daController = TextEditingController();
  bool isHoliday = false;
  bool isWeeklyRest = false;

  double totalDutyHours = 0;
  double nightHours1 = 0; // 22:00 - 00:00
  double nightHours2 = 0; // 00:00 - 06:00
  double totalNightHours = 0;
  double ndaAllowance = 0;

  final dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void dispose() {
    basicPayController.dispose();
    daController.dispose();
    super.dispose();
  }

  Future<void> pickDutyDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: dutyDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        dutyDate = date;
      });
    }
  }

  Future<void> pickFromTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: fromTime ?? const TimeOfDay(hour: 22, minute: 0),
    );
    if (time != null) {
      setState(() {
        fromTime = time;
      });
    }
  }

  Future<void> pickToTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: toTime ?? const TimeOfDay(hour: 6, minute: 0),
    );
    if (time != null) {
      setState(() {
        toTime = time;
      });
    }
  }

  DateTime _combineDateTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void calculate() {
    if (dutyDate == null || fromTime == null || toTime == null) {
      _showMessage('Please select duty date and times.');
      return;
    }
    if (basicPayController.text.isEmpty || daController.text.isEmpty) {
      _showMessage('Please enter Basic Pay and Dearness Allowance.');
      return;
    }

    final basicPay = double.tryParse(basicPayController.text);
    final daPercent = double.tryParse(daController.text);
    if (basicPay == null || daPercent == null) {
      _showMessage('Invalid Basic Pay or Dearness Allowance.');
      return;
    }

    var fromDateTime = _combineDateTime(dutyDate!, fromTime!);
    var toDateTime = _combineDateTime(dutyDate!, toTime!);
    if (toDateTime.isBefore(fromDateTime)) {
      // Assume duty ended next day
      toDateTime = toDateTime.add(const Duration(days: 1));
    }

    totalDutyHours = toDateTime.difference(fromDateTime).inMinutes / 60;

    nightHours1 = _calculateOverlap(fromDateTime, toDateTime,
        dutyDate!.add(const Duration(hours: 22)), dutyDate!.add(const Duration(days: 1))); // 22:00 to 00:00

    nightHours2 = _calculateOverlap(fromDateTime, toDateTime,
        dutyDate!.add(const Duration(days: 1)), dutyDate!.add(const Duration(days: 1, hours: 6))); // 00:00 to 06:00

    totalNightHours = nightHours1 + nightHours2;

    ndaAllowance = calculateNda(basicPay, daPercent, totalNightHours);

    if (isHoliday && isWeeklyRest) {
      // Both allowances paid plus compensation rest
      ndaAllowance = ndaAllowance * 2; // Example doubling allowance
    } else if (isHoliday || isWeeklyRest) {
      // Holiday or weekly rest allowance + NDA
      ndaAllowance = ndaAllowance * 1.5; // Example multiplier
    }

    setState(() {});
  }

  double _calculateOverlap(
      DateTime startA, DateTime endA, DateTime startB, DateTime endB) {
    final latestStart = startA.isAfter(startB) ? startA : startB;
    final earliestEnd = endA.isBefore(endB) ? endA : endB;
    final overlap = earliestEnd.difference(latestStart);
    if (overlap.isNegative) return 0;
    return overlap.inMinutes / 60;
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> exportPdf() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
          build: (context) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Night Duty Allowance Details', style: const pw.TextStyle(fontSize: 20)),
                  pw.SizedBox(height: 10),
                  pw.Text('Duty Date: ${dutyDate != null ? dateFormat.format(dutyDate!) : '-'}'),
                  pw.Text('From Time: ${fromTime?.format(context) ?? '-'}'),
                  pw.Text('To Time: ${toTime?.format(context) ?? '-'}'),
                  pw.Text('Basic Pay: ${basicPayController.text}'),
                  pw.Text('Dearness Allowance (%): ${daController.text}'),
                  pw.Text('Holiday: ${isHoliday ? "Yes" : "No"}'),
                  pw.Text('Weekly Rest: ${isWeeklyRest ? "Yes" : "No"}'),
                  pw.SizedBox(height: 10),
                  pw.Text('Total Duty Hours: ${totalDutyHours.toStringAsFixed(2)}'),
                  pw.Text('Night Hours (22:00-00:00): ${nightHours1.toStringAsFixed(2)}'),
                  pw.Text('Night Hours (00:00-06:00): ${nightHours2.toStringAsFixed(2)}'),
                  pw.Text('Total Night Hours: ${totalNightHours.toStringAsFixed(2)}'),
                  pw.Text('Night Duty Allowance: ₹${ndaAllowance.toStringAsFixed(2)}'),
                ],
              )),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'NDA_Details.pdf');
  }

  void clearAll() {
    setState(() {
      dutyDate = null;
      fromTime = null;
      toTime = null;
      basicPayController.clear();
      daController.clear();
      isHoliday = false;
      isWeeklyRest = false;
      totalDutyHours = 0;
      nightHours1 = 0;
      nightHours2 = 0;
      totalNightHours = 0;
      ndaAllowance = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NIGHT DUTY CALCULATOR')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextButton(
              onPressed: pickDutyDate,
              child: Text(dutyDate == null ? 'Select Duty Date' : 'Duty Date: ${dateFormat.format(dutyDate!)}'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: pickFromTime,
              child: Text(fromTime == null ? 'Select From Time' : 'From Time: ${fromTime!.format(context)}'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: pickToTime,
              child: Text(toTime == null ? 'Select To Time' : 'To Time: ${toTime!.format(context)}'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: basicPayController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Basic Pay'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: daController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Dearness Allowance (%)'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Checkbox(
                  value: isHoliday,
                  onChanged: (val) {
                    setState(() {
                      isHoliday = val ?? false;
                    });
                  },
                ),
                const Text('Holiday'),
                const SizedBox(width: 20),
                Checkbox(
                  value: isWeeklyRest,
                  onChanged: (val) {
                    setState(() {
                      isWeeklyRest = val ?? false;
                    });
                  },
                ),
                const Text('Weekly Rest'),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(primary: Colors.green),
              onPressed: calculate,
              child: const Text('Calculate Allowance'),
            ),
            const SizedBox(height: 20),
            if (ndaAllowance > 0)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Duty Hours: ${totalDutyHours.toStringAsFixed(2)}'),
                  Text('Night Hours (22:00-00:00): ${nightHours1.toStringAsFixed(2)}'),
                  Text('Night Hours (00:00-06:00): ${nightHours2.toStringAsFixed(2)}'),
                  Text('Total Night Hours: ${totalNightHours.toStringAsFixed(2)}'),
                  Text('Night Duty Allowance: ₹${ndaAllowance.toStringAsFixed(2)}'),
                ],
              ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(primary: Colors.green),
                  onPressed: exportPdf,
                  child: const Text('Export PDF'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(primary: Colors.green),
                  onPressed: clearAll,
                  child: const Text('Clear All'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(primary: Colors.green),
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Exit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
